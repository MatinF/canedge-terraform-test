def mdf_to_parquet(cloud, storage_client, notification_client, event, bucket_input, bucket_output):
    from pathlib import Path
    from .utils import DownloadObjects, DetectEvents, CreateCustomMessages, decode_log_file
    from .functions import process_decoded_data
    from .cloud_functions import get_log_file_object_paths
    import tempfile, os, logging

    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    
    logger.info(f"Trigger event: {event}")
    process_result = False 
    decoder = os.environ.get("MF4_DECODER", "mdf2parquet_decode")
    log_file_object_paths = get_log_file_object_paths(cloud, event, logger)            

    if len(log_file_object_paths) == 0:
        return False 
    
    with tempfile.TemporaryDirectory() as temp:       
        tmp_input_dir = Path(temp) / "input"
        tmp_input_mdf_dir = Path(temp) / "input" / "logfiles"
        tmp_output_dir = Path(temp) / "output"     
        tmp_input_dir.mkdir()
        tmp_input_mdf_dir.mkdir()
        tmp_output_dir.mkdir() 
        
        # Initialize classes for downloading objects, decoding MDFs, creating custom messages and detecting events 
        do = DownloadObjects(cloud, storage_client, bucket_input, tmp_input_dir, log_file_object_paths[0], logger)
        ccm = CreateCustomMessages(tmp_output_dir, logger)   
        de = DetectEvents(cloud, storage_client, notification_client, bucket_input, tmp_input_dir, tmp_output_dir, logger)

        # Get device ID, device specific DBC list, DBC files, log file and passwords file
        logger.info(f"\n\nDOWNLOAD OBJECTS")
        device_id = do.extract_device_id()
        device_dbc_list = do.get_device_dbc_list(device_id)       
        dbc_result = do.download_dbc_files(device_dbc_list)
        if dbc_result:  
            do.download_password_file()
            for log_file_object_path in log_file_object_paths:             
                do.download_log_file(log_file_object_path)
                
            # DBC decode MDF data to Parquet files
            logger.info(f"\n\nDBC DECODE MDF TO PARQUET")
            decoder_result = decode_log_file(decoder, tmp_input_dir, tmp_output_dir, logger)
            
            if decoder_result:   
                # If valid custom-messages.json, create custom Parquet messages 
                logger.info(f"\n\nADD CUSTOM MESSAGES")
                custom_messages_exist, custom_messages = do.download_json_file("custom-messages.json")  
                if custom_messages_exist:
                    ccm.create_custom_messages(custom_messages)
                
                # If valid events.json is found in S3 input bucket, detect events in decoded data
                logger.info(f"\n\nDETECT EVENTS")
                events_exists, events = do.download_json_file("events.json")
                if events_exists:
                    de.process_events(events)       
                
                # Perform final processing of data 
                logger.info(f"\n\nDO FINAL PROCESSING")
                process_result = process_decoded_data(cloud, storage_client, bucket_output, tmp_output_dir, logger)
    
    # Print and return the final result        
    if process_result:  
        result = {"statusCode": 200, "body": "Execution succeeded"}
        logger.info(result)   
        return result 
    else:      
        result = {"statusCode": 400, "body": "Execution failed"}
        logger.error(result)
        raise Exception("Manual exception to trigger error (for alerting)")  