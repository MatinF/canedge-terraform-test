import os
import tempfile
import pyarrow.parquet as pq
from azure.storage.blob import BlobServiceClient
import pymssql

def initialize_blob_client(connection_string_output, container_output):
    blob_service_client = BlobServiceClient.from_connection_string(connection_string_output)
    return blob_service_client.get_container_client(container_output)

def list_device_message_folders(container_client):
    blobs = container_client.list_blobs()
    device_message_folders = set()
    for blob in blobs:
        parts = blob.name.split('/')
        if len(parts) == 5:
            device_message_folders.add('/'.join(parts[:2]))
    return list(device_message_folders)

def get_parquet_schema(container_client, folder_path):
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
            finally:
                os.remove(temp_file_path)
            return table.schema
    return None

def generate_create_external_table_sql(table_name, schema, location):
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
    drop_sql = f"""
    IF EXISTS (SELECT * FROM sys.external_tables WHERE name = 'tbl_{table_name}')
    DROP EXTERNAL TABLE [tbl_{table_name}]
    """
    cursor.execute(drop_sql)

def create_external_table(cursor, sql, table_name):
    try:
        drop_external_table_if_exists(cursor, table_name)
        print(f"Executing SQL for table: tbl_{table_name}")
        cursor.execute(sql)
    except pymssql.Error as e:
        print(f"Error creating table tbl_{table_name}: {e}")

def create_database_and_objects(synapse_server, synapse_user, synapse_password, synapse_database, storage_account_name, container_output, master_key_password):
    conn = pymssql.connect(server=synapse_server, user=synapse_user, password=synapse_password, database="master")
    conn.autocommit(True)
    cursor = conn.cursor()
    cursor.execute(f"SELECT COUNT(*) FROM sys.databases WHERE name = '{synapse_database}'")
    if cursor.fetchone()[0] == 0:
        cursor.execute(f"CREATE DATABASE {synapse_database}")
        print(f"Database {synapse_database} created.")
    cursor.close()
    conn.close()

    conn = pymssql.connect(server=synapse_server, user=synapse_user, password=synapse_password, database=synapse_database)
    cursor = conn.cursor()

    cursor.execute(f"SELECT COUNT(*) FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##'")
    if cursor.fetchone()[0] == 0:
        cursor.execute(f"CREATE MASTER KEY ENCRYPTION BY PASSWORD = '{master_key_password}'")

    cursor.execute(f"SELECT COUNT(*) FROM sys.database_scoped_credentials WHERE name = 'my_credential'")
    if cursor.fetchone()[0] == 0:
        cursor.execute(f"CREATE DATABASE SCOPED CREDENTIAL my_credential WITH IDENTITY = 'Managed Identity'")

    cursor.execute(f"SELECT COUNT(*) FROM sys.external_data_sources WHERE name = 'ParquetDataLake'")
    if cursor.fetchone()[0] == 0:
        cursor.execute(f"CREATE EXTERNAL DATA SOURCE ParquetDataLake WITH (LOCATION = 'https://{storage_account_name}.dfs.core.windows.net/{container_output}', CREDENTIAL = my_credential)")

    cursor.execute(f"SELECT COUNT(*) FROM sys.external_file_formats WHERE name = 'ParquetFormat'")
    if cursor.fetchone()[0] == 0:
        cursor.execute(f"CREATE EXTERNAL FILE FORMAT ParquetFormat WITH (FORMAT_TYPE = PARQUET)")

    conn.commit()
    print(f"Database {synapse_database} and objects created.")
    cursor.close()
    conn.close()

def main():
    storage_account = os.environ["STORAGE_ACCOUNT"]
    container_output = os.environ["CONTAINER_OUTPUT"]
    storage_connection_string = os.environ["STORAGE_CONNECTION_STRING"]
    synapse_server = os.environ["SYNAPSE_SERVER"]
    synapse_password = os.environ["SYNAPSE_PASSWORD"]
    master_key_password = os.environ["MASTER_KEY_PASSWORD"]
    synapse_database = os.environ.get("SYNAPSE_DATABASE", "parquetdatalake")
    synapse_user = os.environ.get("SYNAPSE_USER", "sqladminuser")

    container_client = initialize_blob_client(storage_connection_string, container_output)
    folders = list_device_message_folders(container_client)
    create_database_and_objects(synapse_server, synapse_user, synapse_password, synapse_database, storage_account, container_output, master_key_password)
    conn = pymssql.connect(server=synapse_server, user=synapse_user, password=synapse_password, database=synapse_database)
    cursor = conn.cursor()
    for folder in folders:
        schema = get_parquet_schema(container_client, folder)
        if schema is not None:
            table_name = folder.replace('/', '_')
            location = f'/{folder}'
            sql = generate_create_external_table_sql(table_name, schema, location)
            create_external_table(cursor, sql, table_name)
            conn.commit()
    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()
