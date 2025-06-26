# MF4 decoder version: v24.10.17
# Function script version: 1.3.0
import os
import logging
import azure.functions as func

# Add module-level logging to help debug function loading
logging.warning('FUNCTION_APP.PY IS LOADING - Function module has been imported')

# Only uncomment when testing initial deployment success
# from azure.storage.blob import BlobServiceClient 
# from modules.mdf_to_parquet import mdf_to_parquet

# Configure logging to reduce Azure SDK verbosity
logging.getLogger('azure').setLevel(logging.WARNING)
logging.getLogger('azure.core.pipeline').setLevel(logging.ERROR)

# Simplified configuration for initial testing
app = func.FunctionApp()

@app.function_name(name="ProcessMdfToParquet")
@app.blob_trigger(
    arg_name="myblob",
    path="canedge-test-container-26/{name}.MF4",  # Hardcoded path for testing
    connection="StorageConnectionString",
    source="EventGrid"
)
def process_event_grid_blob(myblob: func.InputStream):
    logging.info(f"Python Event Grid blob trigger function processed blob\n"
                 f"Name: {myblob.name}\n"
                 f"Blob Size: {myblob.length} bytes")
    
    # Very simplified function for testing deployment and Event Grid triggering