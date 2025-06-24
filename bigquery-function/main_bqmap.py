import functions_framework
import os
from google.cloud import storage, bigquery
from google.cloud import exceptions

@functions_framework.http
def map_bigquery_tables(request):
    """HTTP Cloud Function to map tables in BigQuery based on parquet files in a bucket.
    Args:
        request (flask.Request): The request object.
    Returns:
        A response with the mapping results.
    """
    # Get environment variables
    bucket_output_name = os.environ.get('OUTPUT_BUCKET')
    dataset_id = os.environ.get('DATASET_ID')
    
    if not bucket_output_name or not dataset_id:
        return ({
            'status': 'error',
            'message': 'Missing required environment variables: OUTPUT_BUCKET and/or DATASET_ID'
        }, 400)
    
    storage_client = storage.Client()
    client = bigquery.Client()
    
    try:
        bucket = storage_client.get_bucket(bucket_output_name)
    except Exception as e:
        return ({
            'status': 'error',
            'message': f'Failed to get bucket {bucket_output_name}: {str(e)}'
        }, 500)
    
    results = {
        'processed': [],
        'skipped': [],
        'failed': []
    }
    
    # Get project ID from the BigQuery client (for table naming)
    project_id = client.project
    
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
        deviceid, message = prefix.split('/')
        table_id = f"{project_id}.{dataset_id}.tbl_{deviceid}_{message}"
        
        # Check if the table already exists
        try:
            client.get_table(table_id)
            results['skipped'].append({
                'table_id': table_id,
                'reason': 'Table already exists'
            })
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
            results['processed'].append({
                'table_id': created_table.table_id,
                'status': 'created'
            })
        except Exception as e:
            results['failed'].append({
                'table_id': table_id,
                'error': str(e)
            })
    
    return ({
        'status': 'success',
        'results': results,
        'message': f"Processed {len(results['processed'])} tables, skipped {len(results['skipped'])} existing tables, and failed for {len(results['failed'])} tables."
    }, 200)
