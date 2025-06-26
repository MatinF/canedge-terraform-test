import logging
import azure.functions as func

app = func.FunctionApp()

@app.function_name(name="ProcessMdfToParquet")
@app.blob_trigger(
    arg_name="myblob",
    path="canedge-test-container-26/{name}.MF4",
    connection="StorageConnectionString",
    source="EventGrid"
)
def process_event_grid_blob(myblob: func.InputStream):
    logging.info(f"Blob trigger function processed blob: {myblob.name}")
    logging.info(f"Blob size: {myblob.length} bytes")
