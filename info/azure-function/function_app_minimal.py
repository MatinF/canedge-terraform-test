import logging
import json
import azure.functions as func

# Module level logging to verify function loading
logging.info("Event Grid Function module loaded")

app = func.FunctionApp()

@app.function_name(name="ProcessMdfToParquet")
@app.event_grid_trigger(arg_name="event")
def process_event_grid(event: func.EventGridEvent):
    # Log the function invocation
    logging.info(f"Processing Event Grid event: {event.event_type}")
    logging.info(f"Event subject: {event.subject}")
    logging.info(f"Event time: {event.event_time}")
    
    # For blob created events, extract the blob URL
    if event.event_type == "Microsoft.Storage.BlobCreated":
        try:
            # Parse the data portion of the event
            data = event.get_json()
            
            # Extract useful information
            url = data.get('url', 'No URL found')
            content_type = data.get('contentType', 'Unknown')
            content_length = data.get('contentLength', 0)
            
            # Log key information about the blob
            logging.info(f"Blob URL: {url}")
            logging.info(f"Content Type: {content_type}")
            logging.info(f"Size: {content_length} bytes")
            
            # Here you would normally process the MF4 file
            # 1. Download the blob using the URL
            # 2. Process the MF4 file
            # 3. Upload the resulting Parquet file to the output container
            
        except Exception as e:
            logging.error(f"Error processing event data: {str(e)}")
    else:
        logging.info(f"Skipping non-BlobCreated event: {event.event_type}")
