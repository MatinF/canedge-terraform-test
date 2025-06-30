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
import time

# Configure logging - suppress Azure SDK HTTP noise completely
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Completely disable HTTP logging from Azure SDK
logging.getLogger('azure').setLevel(logging.ERROR)
logging.getLogger('azure.core').setLevel(logging.ERROR)
logging.getLogger('azure.core.pipeline').setLevel(logging.ERROR)
logging.getLogger('azure.core.pipeline.policies.http_logging_policy').setLevel(logging.ERROR)

# Disable Azure Storage logging below CRITICAL
logging.getLogger('azure.storage').setLevel(logging.CRITICAL)

# Get our script logger
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
    logger.info(f"- Getting schema for folder: {folder_path}")
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
                    logger.info(f"- Successfully read schema from {blob.name}")
                    return table.schema
                finally:
                    os.remove(temp_file_path)
        logger.warning(f"- No Parquet files found in {folder_path}")
        return None
    except Exception as e:
        logger.error(f"- Failed to get Parquet schema for {folder_path}: {e}")
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

def drop_external_table_if_exists(synapse_server, synapse_user, synapse_password, synapse_database, table_name):
    """Drop the external table if it exists using REST API"""
    drop_sql = f"""
    IF EXISTS (SELECT * FROM sys.external_tables WHERE name = 'tbl_{table_name}')
    BEGIN
        DROP EXTERNAL TABLE [tbl_{table_name}]
    END
    """
    return execute_sql(synapse_server, synapse_user, synapse_password, synapse_database, drop_sql)

def create_external_table(synapse_server, synapse_user, synapse_password, synapse_database, sql, table_name):
    """Create an external table in Synapse using REST API"""
    try:
        drop_external_table_if_exists(synapse_server, synapse_user, synapse_password, synapse_database, table_name)
        logger.info(f"- Executing SQL for table: tbl_{table_name}")
        result = execute_sql(synapse_server, synapse_user, synapse_password, synapse_database, sql)
        if result:
            logger.info(f"- Successfully created table tbl_{table_name}")
            return True
        else:
            logger.error(f"- Failed to create table tbl_{table_name}")
            return False
    except Exception as e:
        logger.error(f"- Error creating table tbl_{table_name}: {e}")
        return False

def execute_sql(synapse_server, synapse_user, synapse_password, database, sql_query, autocommit=False):
    """Execute SQL query using direct connection with SQL authentication"""
    try:
        import pymssql
        
        # For SQL authentication, we can directly use pymssql with the serverless SQL pool endpoint
        # The serverless SQL endpoint follows this format: <workspace-name>-ondemand.sql.azuresynapse.net
        workspace_name = synapse_server.split('.')[0]
        serverless_endpoint = f"{workspace_name}-ondemand.sql.azuresynapse.net"
                
        # Connect using SQL authentication
        conn = pymssql.connect(
            server=serverless_endpoint,
            user=synapse_user,
            password=synapse_password,
            database=database,
            autocommit=autocommit
        )
        
        cursor = conn.cursor()       
        cursor.execute(sql_query)
        
        # Try to fetch results if available
        try:
            results = cursor.fetchall()
            result_dict = {
                'results': results
            }
        except:
            # If no results to fetch (e.g., for CREATE statements)
            result_dict = {
                'results': []
            }
        
        if not autocommit:
            conn.commit()
        cursor.close()
        conn.close()
        
        return result_dict
    except Exception as e:
        logger.error(f"Failed to execute SQL: {e}")
        return None

def create_database_and_objects(synapse_server, synapse_user, synapse_password, synapse_database, storage_account_name, container_output, master_key_password):
    """Create database and required objects in Synapse using REST API and SQL queries"""
    try:
        # Use the original database name passed to the function
        # No override needed as we fixed the connection approach
        
        # Check if the database exists by trying to use it
        logger.info(f"Checking if database {synapse_database} exists in {synapse_server}")
        
        # Using default 'master' database to check if our target database exists
        check_db_query = f"SELECT name FROM sys.databases WHERE name = '{synapse_database}'"
        result = execute_sql(synapse_server, synapse_user, synapse_password, "master", check_db_query)
        
        # If the database doesn't exist, we create it using a special SQL query for Synapse with autocommit=True
        if not result or len(result.get('results', [])) == 0:
            logger.info(f"Creating database {synapse_database}")
            create_db_query = f"CREATE DATABASE {synapse_database}"
            result = execute_sql(synapse_server, synapse_user, synapse_password, "master", create_db_query, autocommit=True)
            if not result:
                logger.error("Failed to create database")
                sys.exit(1)
            logger.info(f"Database {synapse_database} created")
            
            # Wait a moment for the database to be ready
            logger.info("Waiting for database to be ready...")
            time.sleep(5)
        else:
            logger.info(f"Database {synapse_database} already exists")
        
        # Now create the required objects in the database
        # Master Key
        logger.info("Creating master key if it doesn't exist")
        master_key_query = f"""
        IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
        BEGIN
            CREATE MASTER KEY ENCRYPTION BY PASSWORD = '{master_key_password}'
        END
        """
        execute_sql(synapse_server, synapse_user, synapse_password, synapse_database, master_key_query)
        
        # Database Scoped Credential
        logger.info("Creating database scoped credential if it doesn't exist")
        credential_query = """
        IF NOT EXISTS (SELECT * FROM sys.database_scoped_credentials WHERE name = 'my_credential')
        BEGIN
            CREATE DATABASE SCOPED CREDENTIAL my_credential WITH IDENTITY = 'Managed Identity'
        END
        """
        execute_sql(synapse_server, synapse_user, synapse_password, synapse_database, credential_query)
        
        # External Data Source
        logger.info("Creating external data source if it doesn't exist")
        datasource_query = f"""
        IF NOT EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'ParquetDataLake')
        BEGIN
            CREATE EXTERNAL DATA SOURCE ParquetDataLake WITH (
                LOCATION = 'https://{storage_account_name}.dfs.core.windows.net/{container_output}',
                CREDENTIAL = my_credential
            )
        END
        """
        execute_sql(synapse_server, synapse_user, synapse_password, synapse_database, datasource_query)
        
        # External File Format
        logger.info("Creating external file format if it doesn't exist")
        fileformat_query = """
        IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'ParquetFormat')
        BEGIN
            CREATE EXTERNAL FILE FORMAT ParquetFormat WITH (FORMAT_TYPE = PARQUET)
        END
        """
        execute_sql(synapse_server, synapse_user, synapse_password, synapse_database, fileformat_query)
        
        logger.info(f"Database {synapse_database} and required objects created/verified")
        
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
    
    # Create tables for each folder using REST API
    tables_created = 0
    for folder in folders:
        logger.info(" ")
        logger.info(f"Now processing {folder}:")
        schema = get_parquet_schema(container_client, folder)
        if schema is not None:
            table_name = folder.replace('/', '_')
            location = f'/{folder}'
            sql = generate_create_external_table_sql(table_name, schema, location)
            if create_external_table(synapse_server, synapse_user, synapse_password, synapse_database, sql, table_name):
                tables_created += 1
    
    logger.info(" ")
    logger.info(f"Process completed. Created {tables_created} tables out of {len(folders)} folders.")

if __name__ == "__main__":
    main()
