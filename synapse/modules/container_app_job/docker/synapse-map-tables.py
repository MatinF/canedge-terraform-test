#!/usr/bin/env python3
"""
Synapse Table Mapper for Parquet Files

This script maps Azure Storage Parquet files to Synapse external tables.
It scans the specified container for device/message folders and creates
appropriate external tables in the Synapse workspace.
"""

import os
import sys
import tempfile
import logging
import pyarrow.parquet as pq
from azure.storage.blob import BlobServiceClient
import pymssql

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("synapse-map-tables")

def initialize_blob_client(connection_string_output, container_output):
    """Initialize Azure Blob Storage client"""
    try:
        blob_service_client = BlobServiceClient.from_connection_string(connection_string_output)
        return blob_service_client.get_container_client(container_output)
    except Exception as e:
        logger.error(f"Failed to initialize blob client: {e}")
        sys.exit(1)

def list_device_message_folders(container_client):
    """List all device/message folders in the container"""
    logger.info("Scanning for device/message folders...")
    try:
        blobs = container_client.list_blobs()
        device_message_folders = set()
        for blob in blobs:
            parts = blob.name.split('/')
            if len(parts) == 5:  # Expected path structure
                device_message_folders.add('/'.join(parts[:2]))
        
        logger.info(f"Found {len(device_message_folders)} device/message folders")
        return list(device_message_folders)
    except Exception as e:
        logger.error(f"Failed to list folders: {e}")
        return []

def get_parquet_schema(container_client, folder_path):
    """Extract schema from the first Parquet file in a folder"""
    logger.info(f"Getting schema for folder: {folder_path}")
    try:
        blobs = container_client.list_blobs(name_starts_with=folder_path)
        for blob in blobs:
            if blob.name.endswith('.parquet'):
                blob_client = container_client.get_blob_client(blob)
                downloaded_blob = blob_client.download_blob().readall()
                with tempfile.NamedTemporaryFile(delete=False) as temp_file:
                    temp_file.write(downloaded_blob)
                    temp_file_path = temp_file.name
                try:
                    table = pq.read_table(temp_file_path)
                    logger.info(f"Successfully read schema from {blob.name}")
                    return table.schema
                finally:
                    os.remove(temp_file_path)
        logger.warning(f"No Parquet files found in {folder_path}")
        return None
    except Exception as e:
        logger.error(f"Failed to get Parquet schema for {folder_path}: {e}")
        return None

def generate_create_external_table_sql(table_name, schema, location):
    """Generate SQL to create an external table"""
    columns = []
    for field in schema:
        if field.name == "t":
            column = f"[{field.name}] DATETIME"
        else:
            column = f"[{field.name}] FLOAT"
        columns.append(column)
    columns_sql = ",\n\t".join(columns)
    sql = f"""
    CREATE EXTERNAL TABLE [tbl_{table_name}]
    (
        {columns_sql}
    )
    WITH
    (
        LOCATION = '{location}/*',
        DATA_SOURCE = [ParquetDataLake],
        FILE_FORMAT = [ParquetFormat]
    )
    """
    return sql

def drop_external_table_if_exists(cursor, table_name):
    """Drop the external table if it exists"""
    drop_sql = f"""
    IF EXISTS (SELECT * FROM sys.external_tables WHERE name = 'tbl_{table_name}')
    DROP EXTERNAL TABLE [tbl_{table_name}]
    """
    cursor.execute(drop_sql)

def create_external_table(cursor, sql, table_name):
    """Create an external table in Synapse"""
    try:
        drop_external_table_if_exists(cursor, table_name)
        logger.info(f"Executing SQL for table: tbl_{table_name}")
        cursor.execute(sql)
        logger.info(f"Successfully created table tbl_{table_name}")
    except pymssql.Error as e:
        logger.error(f"Error creating table tbl_{table_name}: {e}")

def create_database_and_objects(synapse_server, synapse_user, synapse_password, synapse_database, storage_account_name, container_output, master_key_password):
    """Create database and required objects in Synapse"""
    try:
        logger.info(f"Connecting to master database on {synapse_server}")
        conn = pymssql.connect(server=synapse_server, user=synapse_user, password=synapse_password, database="master")
        conn.autocommit(True)
        cursor = conn.cursor()
        cursor.execute(f"SELECT COUNT(*) FROM sys.databases WHERE name = '{synapse_database}'")
        if cursor.fetchone()[0] == 0:
            cursor.execute(f"CREATE DATABASE {synapse_database}")
            logger.info(f"Database {synapse_database} created.")
        else:
            logger.info(f"Database {synapse_database} already exists.")
        cursor.close()
        conn.close()

        logger.info(f"Connecting to {synapse_database} database")
        conn = pymssql.connect(server=synapse_server, user=synapse_user, password=synapse_password, database=synapse_database)
        cursor = conn.cursor()

        cursor.execute(f"SELECT COUNT(*) FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##'")
        if cursor.fetchone()[0] == 0:
            cursor.execute(f"CREATE MASTER KEY ENCRYPTION BY PASSWORD = '{master_key_password}'")
            logger.info("Master key created.")
        else:
            logger.info("Master key already exists.")

        cursor.execute(f"SELECT COUNT(*) FROM sys.database_scoped_credentials WHERE name = 'my_credential'")
        if cursor.fetchone()[0] == 0:
            cursor.execute(f"CREATE DATABASE SCOPED CREDENTIAL my_credential WITH IDENTITY = 'Managed Identity'")
            logger.info("Database scoped credential created.")
        else:
            logger.info("Database scoped credential already exists.")

        cursor.execute(f"SELECT COUNT(*) FROM sys.external_data_sources WHERE name = 'ParquetDataLake'")
        if cursor.fetchone()[0] == 0:
            cursor.execute(f"CREATE EXTERNAL DATA SOURCE ParquetDataLake WITH (LOCATION = 'https://{storage_account_name}.dfs.core.windows.net/{container_output}', CREDENTIAL = my_credential)")
            logger.info("External data source created.")
        else:
            logger.info("External data source already exists.")

        cursor.execute(f"SELECT COUNT(*) FROM sys.external_file_formats WHERE name = 'ParquetFormat'")
        if cursor.fetchone()[0] == 0:
            cursor.execute(f"CREATE EXTERNAL FILE FORMAT ParquetFormat WITH (FORMAT_TYPE = PARQUET)")
            logger.info("External file format created.")
        else:
            logger.info("External file format already exists.")

        conn.commit()
        logger.info(f"Database {synapse_database} and objects created.")
        cursor.close()
        conn.close()
    except Exception as e:
        logger.error(f"Failed to create database and objects: {e}")
        sys.exit(1)

def main():
    """Main function to map Synapse tables"""
    logger.info("Starting Synapse table mapping process")
    
    # Get environment variables
    try:
        storage_account = os.environ["STORAGE_ACCOUNT"]
        container_output = os.environ["CONTAINER_OUTPUT"]
        storage_connection_string = os.environ["STORAGE_CONNECTION_STRING"]
        synapse_server = os.environ["SYNAPSE_SERVER"]
        synapse_password = os.environ["SYNAPSE_PASSWORD"]
        master_key_password = os.environ["MASTER_KEY_PASSWORD"]
        synapse_database = os.environ.get("SYNAPSE_DATABASE", "parquetdatalake")
        synapse_user = os.environ.get("SYNAPSE_USER", "sqladminuser")
    except KeyError as e:
        logger.error(f"Missing required environment variable: {e}")
        sys.exit(1)
    
    logger.info(f"Connecting to storage account: {storage_account}")
    logger.info(f"Using container: {container_output}")
    logger.info(f"Synapse server: {synapse_server}")
    logger.info(f"Synapse database: {synapse_database}")
    
    # Initialize container client
    container_client = initialize_blob_client(storage_connection_string, container_output)
    
    # List all device/message folders
    folders = list_device_message_folders(container_client)
    if not folders:
        logger.warning("No device/message folders found. No tables will be created.")
        sys.exit(0)
    
    # Create database and required objects
    create_database_and_objects(synapse_server, synapse_user, synapse_password, synapse_database, 
                               storage_account, container_output, master_key_password)
    
    # Create tables for each folder
    conn = pymssql.connect(server=synapse_server, user=synapse_user, password=synapse_password, database=synapse_database)
    cursor = conn.cursor()
    
    tables_created = 0
    for folder in folders:
        schema = get_parquet_schema(container_client, folder)
        if schema is not None:
            table_name = folder.replace('/', '_')
            location = f'/{folder}'
            sql = generate_create_external_table_sql(table_name, schema, location)
            create_external_table(cursor, sql, table_name)
            conn.commit()
            tables_created += 1
    
    cursor.close()
    conn.close()
    
    logger.info(f"Process completed. Created {tables_created} tables out of {len(folders)} folders.")

if __name__ == "__main__":
    main()
