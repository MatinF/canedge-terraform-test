# MF4 decoder version: v24.10.17
# Google Cloud Function script version: 1.7.0
import functions_framework
from google.cloud import storage
from modules.mdf_to_parquet import mdf_to_parquet

# Cloud provider configuration
cloud = "Google"
storage_client = storage.Client()
notification_client = None # not used in Google

@functions_framework.cloud_event
def process_mdf_file(cloud_event):
    # Handle list of events (for local testing)
    if isinstance(cloud_event, list):
        bucket_input = cloud_event[0].data['bucket']
    else:
        bucket_input = cloud_event.data['bucket']
    
    bucket_output = bucket_input + "-parquet"
    
    return mdf_to_parquet(cloud, storage_client, notification_client, cloud_event, bucket_input, bucket_output)