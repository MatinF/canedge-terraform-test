# MF4 decoder version: v24.10.17
# Function script version: 1.3.0
import os
import logging
import azure.functions as func
from azure.storage.blob import BlobServiceClient
from modules.mdf_to_parquet import mdf_to_parquet

# Configure logging to reduce Azure SDK verbosity
logging.getLogger('azure').setLevel(logging.WARNING)
logging.getLogger('azure.core.pipeline').setLevel(logging.ERROR)
logging.getLogger('azure.storage').setLevel(logging.WARNING)

# Cloud provider configuration
storage_connection_string = os.getenv("STORAGE_CONNECTION_STRING")
bucket_input = os.getenv("BUCKET_INPUT")
ext = os.getenv("MDF_EXTENSION", "MF4")

cloud = "Azure"
bucket_output = bucket_input + "-parquet"
storage_client = BlobServiceClient.from_connection_string(storage_connection_string)
notification_client = None

app = func.FunctionApp()

@app.blob_trigger(
    arg_name="myblob",
    path = bucket_input + "/{name}." + ext,
    connection="STORAGE_CONNECTION_STRING"
)
def MdfToParquet(myblob):
    mdf_to_parquet(cloud, storage_client, notification_client, myblob, bucket_input, bucket_output)