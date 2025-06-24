# This script has been tested on Windows 10 with Python 3.11

from google.cloud import storage, bigquery
from google.cloud import exceptions
from google.oauth2 import service_account

# Specify the below variables 
project_id = 'your-project-id' # e.g. bigquerytest-442201
bucket_output_name = 'your-output-bucket' # e.g. mybucket-parquet

#--------------------------------
# Specify dataset ID (assumed correctly named as per the guide)
dataset_id = "lakedataset1" 

# Initialize credentials
key_path = "bigquery-storage-admin-account.json"
credentials = service_account.Credentials.from_service_account_file(key_path)

# Construct clients for Google Cloud Storage and BigQuery
storage_client = storage.Client(credentials=credentials, project=project_id)
bucket = storage_client.get_bucket(bucket_output_name)
client = bigquery.Client(credentials=credentials, project=project_id)

# Crawl the bucket to get all unique combinations of deviceid and message
prefixes = set()
blobs = bucket.list_blobs()
for blob in blobs:
    parts = blob.name.split('/')
    if len(parts) >= 3:
        device_message = '/'.join(parts[0:2])
        prefixes.add(device_message)

# Process each unique deviceid/message combination
for prefix in prefixes:
    print(f"Prefix {prefix}")
    deviceid, message = prefix.split('/')
    table_id = f"{project_id}.{dataset_id}.tbl_{deviceid}_{message}"
    
    # Check if the table already exists
    try:
        client.get_table(table_id)
        print(f"- SKIPPED: Table {table_id} already exists")
        continue  # Skip this iteration if the table exists
    except exceptions.NotFound:
        pass  # Table does not exist, proceed with creation
    
    # Construct the URI pattern to match Parquet files for the combination
    source_uris = [f"gs://{bucket_output_name}/{prefix}/*"]

    # Create an external table in BigQuery
    external_config = bigquery.ExternalConfig('PARQUET')
    external_config.source_uris = source_uris
    external_config.autodetect = True
    external_config.ignore_unknown_values = True  # Set to ignore unknown values

    table = bigquery.Table(table_id)
    table.external_data_configuration = external_config

    try:
        # Create the table in BigQuery
        created_table = client.create_table(table)  # Make an API request.
        print(f"- created table {created_table.table_id}")
    except Exception as e:
        print(f"- failed to create table {table_id}. Error: {str(e)}")

print("\nFinished creating external tables for all device and message combinations.")