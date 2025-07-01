from .cloud_functions import download_object, list_objects, upload_object, publish_notification

# Class for downloading objects required by the Lambda
class DownloadObjects:
    def __init__(self, cloud, storage_client, bucket_input, tmp_input_dir, log_file_object_path, logger):
        self.logger = logger
        self.cloud = cloud
        self.storage_client = storage_client
        self.bucket_input = bucket_input
        self.tmp_input_dir = tmp_input_dir
        self.log_file_object_path = log_file_object_path

    # -----------------------------------------------
    # Extract device ID (note: Only works if the CANedge S3 file structure is used)
    def extract_device_id(self):
        import re
        
        device_id = ""
        parts = self.log_file_object_path.parts
        
        # Check if the path has at least 3 parts and 1st part matches device ID syntax
        if len(parts) == 3 and re.match("[0-9A-F]{8}$", parts[0]):
            # The device_id is expected to be the first part of the path
            device_id = parts[0]
            self.logger.info(f"Device ID: {device_id}")
        else:
            self.logger.info(f"Unable to extract device_id (log file does not use CANedge S3 path)")
        
        return device_id
    
    # -----------------------------------------------    
    # Download dbc-groups.json file (if it exists) and use device ID to extract relevant DBC list
    def get_device_dbc_list(self,device_id):
        import json 
        
        # If no match is found, the script simply applies all DBC files across any device ID
        device_dbc_list = [] 
        if device_id != "":
            fs_dbc_groups_file_path = self.tmp_input_dir / "dbc-groups.json"
            try:
                download_object(self.cloud, self.storage_client, self.bucket_input, "dbc-groups.json", str(fs_dbc_groups_file_path), self.logger)

                with open(fs_dbc_groups_file_path, "r") as file:
                    data = json.load(file)

                # Iterate over the groups in the JSON
                for group in data["dbc_groups"]:
                    self.logger.info(f"Evaluating DBC group {group}")
                    # Check if the device_id is in the current group
                    if device_id in group["devices"]:
                        # Add the dbc_files list to the variable
                        device_dbc_list = group["dbc_files"]
                        self.logger.info(f"Device specific DBC files: {device_dbc_list}")
                        break
            except Exception as e:
                self.logger.info(f"Applying all DBC files across all devices: {e}")
        
        return device_dbc_list
                        
    # -----------------------------------------------
    # Download DBC files
    def download_dbc_files(self, device_dbc_files):
        dbc_files = []
        result = True
        
        for type in ["can", "lin"]:
            try:
                response = list_objects(self.cloud, self.storage_client, self.bucket_input, self.logger, type)
                
                # Process the standardized response format
                for object_info in response["objects"]:
                    dbc_object_name = object_info["name"]
                    if dbc_object_name.endswith(".dbc") and (len(device_dbc_files) == 0 or dbc_object_name in device_dbc_files):
                        local_path = self.tmp_input_dir / dbc_object_name
                        download_object(self.cloud, self.storage_client, self.bucket_input, dbc_object_name, str(local_path), self.logger)
                        dbc_files.append(dbc_object_name)
            except Exception as e:
                self.logger.error(f"Unable to list or download DBC files from {self.bucket_input}:\n {e}")
                result = False
        
        if len(dbc_files) == 0:
            self.logger.error(f"No DBC files with valid prefix in input bucket")
            result = False
        else:
            self.logger.info(f"Downloaded {len(dbc_files)} DBC files with valid prefix from input bucket")
            result = True
        
        return result

    # -----------------------------------------------
    # Download trigger log file
    def download_log_file(self, log_file_object_path):
        object_path = log_file_object_path
        fs_file_path = self.tmp_input_dir / "logfiles" / object_path.name

        download_object(self.cloud, self.storage_client, self.bucket_input, str(object_path), str(fs_file_path), self.logger)

    # -----------------------------------------------   
    # Download passwords.json file if needed
    def download_password_file(self):
        if str(self.log_file_object_path).split(".")[-1] in ["MFE","MFM"]:   
            object_path = "passwords.json"
            fs_file_path = self.tmp_input_dir / object_path
            download_object(self.cloud, self.storage_client, self.bucket_input, object_path, str(fs_file_path), self.logger)
            
    # -----------------------------------------------   
    # Check for and download JSON file if it exists
    def download_json_file(self, object_path):
        import json

        fs_json_file_path = self.tmp_input_dir / object_path
        download_object(self.cloud, self.storage_client, self.bucket_input, object_path, str(fs_json_file_path), self.logger)

        try:
            with open(fs_json_file_path, 'r') as f:
                json_data = json.load(f)
                return True, json_data
        except Exception as e:
            self.logger.info(f"No {object_path} found in {self.bucket_input} or file is invalid: {str(e)}")
            return False, []
        

# -----------------------------------------------
# DBC decode MDF file to Parquet via MF4 decoder
def decode_log_file(decoder, tmp_input_dir, tmp_output_dir, logger):
    import subprocess, os, shutil
    
    fs_logfiles_path = tmp_input_dir / "logfiles" 
    
    # Check if the logfiles folder contains any files
    logfiles = list(fs_logfiles_path.glob('*.*'))
    if not logfiles:
        logger.error("No log files available for decoding")
        return False
    
    shutil.copy("./" + decoder, tmp_input_dir)
    subprocess.run([os.path.join(tmp_input_dir, decoder), "-v"], cwd=str(tmp_input_dir),)
    subprocess_result = subprocess.run([os.path.join(tmp_input_dir, decoder),"-i",str(fs_logfiles_path),"-O",str(tmp_output_dir), "--verbosity=1","-X",],cwd=str(tmp_input_dir),)
            
    if subprocess_result.returncode != 0:
        logger.error(f"MF4 decoding failed (returncode {subprocess_result.returncode})")
        result = False 
    else:
        logger.info(f"MF4 decoding created {len(list(tmp_output_dir.rglob('*.*'))) } Parquet files")
        result = True 

    return result

# -----------------------------------------------------------           
# -----------------------------------------------------------
# Class for loading decoded files into a data frame, applying custom processing and store result as Parquet 
class CreateCustomMessages:
    def __init__(self, tmp_output_dir, logger):
        self.logger = logger
        self.tmp_output_dir =  tmp_output_dir     
    
    def create_custom_messages(self, custom_messages):
        import pyarrow as pa
        import pyarrow.parquet as pq
        from pathlib import Path
        from .custom_message_functions import apply_custom_function

        # List all decoded Parquet files and message paths
        decoded_files = list(self.tmp_output_dir.rglob("*.parquet"))
        all_message_paths = get_all_message_paths(decoded_files)

        # Loop through each custom message
        for idx, custom_message in enumerate(custom_messages, start=1):
            custom_message_name = custom_message["custom_message_name"]
            messages_filtered_list = get_messages_filtered_list(self.tmp_output_dir, custom_message)
            self.logger.info(f"Processing custom message {idx}/{len(custom_messages)}: {custom_message_name}")
            self.logger.info(f"- Input messages: {messages_filtered_list}")
            
            # Loop through each input message per custom message
            for messages_filtered in messages_filtered_list:
                
                # Extract list of related decoded message file paths
                related_message_paths = get_related_message_paths(all_message_paths, messages_filtered)

                if len(related_message_paths) == 0:
                    self.logger.info(f"- No matching decoded files found: {messages_filtered}")
                    continue
                
                # Loop through each unique path per set of related messages
                for (device, date, file_name), messages in related_message_paths.items():           
                
                    # Load message data. If empty, skip
                    df_messages = self.create_df_messages(messages, device, date, file_name, custom_message)     
                    if df_messages.empty:
                        self.logger.info(f"- Decoded file found, but data frame is empty (typically due to short file): {(messages_filtered, device, date, file_name)}")
                        continue 
                    
                    # Update data frame by applying apply custom functions 
                    df_messages = apply_custom_function(df_messages, custom_message["function"])
                                      
                    # Write the new custom file as Parquet to unique path                     
                    custom_file = self.tmp_output_dir / device / custom_message_name / date / file_name 
                    Path(custom_file).parent.mkdir(parents=True, exist_ok=True)
                    table = pa.Table.from_pandas(df_messages.reset_index())
                    pq.write_table(table, custom_file)  
                    self.logger.info(f"- Wrote custom Parquet file to {custom_file}")               

    # -----------------------------------------------
    # create_custom_messages helper function: Extract input message data 
    def create_df_messages(self, messages, device, date, file_name, custom_message):
        import pandas as pd
        
        dfs = []
        for message in messages:
            decoded_file = self.tmp_output_dir / device / message / date / file_name
            df = load_parquet_to_df(decoded_file, message, custom_message["raster"], custom_message["prefix"])
            df["Message"] = message
            dfs.append(df)
        
        # If resampling is disabled, stack the data (requires identical column names to be meaningful)
        # If resampling is enabled, create a single data frame with all signals in columns 
        if custom_message["raster"] == "":
            df_messages = pd.concat(dfs, axis=0) 
        else:
            df_messages = pd.concat(dfs, axis=1, join="inner")  
        
        return df_messages     

# -----------------------------------------------------------           
# -----------------------------------------------------------
# Class for detecting signal events based on events.json
class DetectEvents:
    def __init__(self, cloud, storage_client, notification_client, bucket_input, tmp_input_dir, tmp_output_dir, logger):
        self.logger = logger
        self.cloud = cloud
        self.storage_client = storage_client
        self.notification_client = notification_client
        self.bucket_input = bucket_input
        self.tmp_input_dir =  tmp_input_dir     
        self.tmp_output_dir =  tmp_output_dir     
    
    def process_events(self, events):
        import pyarrow as pa
        import pyarrow.parquet as pq
        from pathlib import Path
        
        # Extract events list and general configuration
        general_cfg = events.get("general", {})
        events_cfg = events.get("events", [])
                
        # Get general event info incl. GPS details and SNS body content from the events JSON file
        messages_gps = general_cfg.get("messages_gps", ["CAN9_GnssPos"])
        include_gps_data = general_cfg.get("include_gps_data", True)
        signal_latitude = general_cfg.get("signal_latitude", "Latitude")
        signal_longitude = general_cfg.get("signal_longitude", "Longitude")
        static_body_content = general_cfg.get("static_body_content", "Review details via e.g. your event dashboard") # enables you to add more information to the notification message
        
        # List all decoded Parquet files and message paths
        decoded_files = list(self.tmp_output_dir.rglob("*.parquet"))
        all_message_paths = get_all_message_paths(decoded_files)
        
        # Loop through each event
        for idx, event in enumerate(events_cfg, start=1):
            event_name = event["event_name"]   
            messages_filtered_list = get_messages_filtered_list(self.tmp_output_dir, event)[0]

            self.logger.info(f"Processing event {idx}/{len(events_cfg)}: {event_name}")
            self.logger.info(f"- Input messages: {messages_filtered_list}")
            message_sent = False
                        
            # Loop through each input message per event 
            # Note: The use of [0] forces the script to evaluate lists of messages one-by-one
            for messages_filtered in messages_filtered_list:
                messages_filtered = [messages_filtered]
                
                # Extract list of related decoded message file paths
                related_message_paths = get_related_message_paths(all_message_paths, messages_filtered)
                if len(related_message_paths) == 0:
                    self.logger.info(f"- No matching decoded files found: {messages_filtered}")
                    continue
                                                        
                # Loop through each unique path per set of related messages
                for (device, date, file_name), messages in related_message_paths.items():           
                                        
                    # Load message data. If empty, skip
                    df_messages = self.create_df_messages(messages, device, date, file_name, event, messages_gps, include_gps_data)
                    if df_messages.empty:
                        self.logger.info(f"- Decoded file found, but data frame is empty (typically due to short file): {(messages_filtered, device, date, file_name)}")
                        continue 
                
                    # Loop through each trigger signal for the event
                    for trigger_signal in event["trigger_signals"]:
                        
                        # Test if trigger signal value crosses event thresholds. If so, extract the start/stop event-related subset of data. If empty, skip
                        df_signal_event = self.create_df_signal_event(trigger_signal, event, df_messages)                      
                        if df_signal_event.empty:
                            self.logger.info(f"- No events found: {(messages_filtered, trigger_signal, device, date, file_name)}")
                            pass           
                        else:
                            # Add the event data to the consistent event meta data structure
                            df_signal_event_meta, schema = self.create_df_signal_event_meta(df_signal_event, trigger_signal, event_name, device, messages, include_gps_data, signal_latitude, signal_longitude)
                            
                            # Write the new custom file as Parquet to unique path 
                            custom_file = self.tmp_output_dir / "aggregations" / "events" / date / (device + "_" + messages[0] + "_" + trigger_signal + "_" + event_name + "_"+ file_name)
                            Path(custom_file).parent.mkdir(parents=True, exist_ok=True)
                            table = pa.Table.from_pandas(df_signal_event_meta.reset_index(), schema=schema)
                            pq.write_table(table, custom_file)  
                            self.logger.info(f"- Wrote event Parquet file to {custom_file}")
                            
                            # Upon first identified 'rising edge' event, publish message to SNS topic
                            df_start_events = df_signal_event_meta[df_signal_event_meta["EventValue"] == 1]

                            if message_sent == False and df_start_events.empty == False:
                                subject = f"- EVENT: {event_name} | {device} | {df_start_events.index[0]}"
                                body = f"{event_name} was triggered. {static_body_content}\n\nDetails:\n- device: {device}\n- message(s): {messages_filtered}\n- file: {file_name}\n- time: {df_start_events.index[0]}"
                                message_sent = self.publish_message(subject, body)
            
    # -----------------------------------------------
    # process_events helper function: Send message to SNS topic for use in event notification
    def publish_message(self, subject, body):
        try:
            result = publish_notification(self.cloud, self.notification_client, subject, body, self.logger)
            return result
        except Exception as e:
            self.logger.error(f"- Error publishing notification: {e}")
            return False
    
    # -----------------------------------------------
    # process_events helper function: Extract event message data frame incl. GPS data
    def create_df_messages(self, messages, device, date, file_name, event, messages_gps, include_gps_data):
        import pandas as pd
        dfs = []
        
        for message in messages:
            decoded_file = self.tmp_output_dir / device / message / date / file_name
            dfs.append(load_parquet_to_df(decoded_file, message, event["raster"]))
        
        # If GPS position data is to be included, try to extract this
        if include_gps_data:
            for gps_message in messages_gps:
                try:
                    decoded_file = self.tmp_output_dir / device / gps_message / date / file_name 
                    dfs.append(load_parquet_to_df(decoded_file, messages[0], event["raster"]))
                    break
                except:
                    pass
        
        # If resampling is disabled, stack the data (requires identical column names to be meaningful)
        # If resampling is enabled, create a single data frame with all signals in columns                       
        if event["raster"] == "":
            df_messages = pd.concat(dfs, axis=0) 
        else:
            df_messages = pd.concat(dfs, axis=1, join="inner") 
        
        return df_messages
                    
    # -----------------------------------------------
    # process_events helper function: Detect trigger signal rising and falling edge events
    def create_df_signal_event(self, trigger_signal, event, df):
        import pandas as pd
        
        if event["exact_match"]:
            df['below_lower'] = df[trigger_signal] == event["lower_threshold"]
            df['above_upper'] = df[trigger_signal] == event["upper_threshold"]
        else:
            df['below_lower'] = df[trigger_signal] <= event["lower_threshold"]
            df['above_upper'] = df[trigger_signal] >= event["upper_threshold"]

        # Track when the signal was last below the lower threshold or above the upper threshold
        df['was_below_lower'] = df['below_lower'].rolling(window=len(df), min_periods=1).max().shift(1, fill_value=0)
        df['was_above_upper'] = df['above_upper'].rolling(window=len(df), min_periods=1).max().shift(1, fill_value=0)

        # Create event groups to detect transitions from below_lower to above_upper or vice versa
        df['event_group_rise'] = (df['below_lower'] != df['below_lower'].shift(1)).cumsum()
        df['event_group_fall'] = (df['above_upper'] != df['above_upper'].shift(1)).cumsum()

        # Identify rising/falling edges in the data
        df_rising = df[df['above_upper'] & (df['was_below_lower'] == 1)].drop_duplicates(subset='event_group_rise', keep='first')
        df_falling = df[df['below_lower'] & (df['was_above_upper'] == 1)].drop_duplicates(subset='event_group_fall', keep='first')
        
        # Depending on the detection logic, assign event start/stop to either rising/falling edges
        if event["rising_as_start"]:
            df_start = df_rising
            df_stop = df_falling
        else:
            df_start = df_falling
            df_stop = df_rising
        
        # Assign meta information
        df_start['EventType'] = 'Start'
        df_start['EventValue'] = 1
        df_stop['EventType'] = 'Stop'
        df_stop['EventValue'] = 0

        # Combine start/stop events, and sort by index
        df_signal_event = pd.concat([df_start, df_stop]).sort_index()
    
        return df_signal_event
    
    # -----------------------------------------------
    # process_events helper function: Create events meta dataframe
    def create_df_signal_event_meta(self, df_signal_event, trigger_signal, event_name, device, messages, include_gps_data, signal_latitude, signal_longitude):
        import pandas as pd
        import pyarrow as pa

        # Create new data frame based on the event data
        df_signal_event_meta = pd.DataFrame()
        df_signal_event_meta.index = df_signal_event.index 
        df_signal_event_meta["EventName"] = event_name
        df_signal_event_meta["DeviceID"] = device 
        df_signal_event_meta["EventId"] = df_signal_event_meta.index.strftime(f"{event_name}_{device}_%Y%m%dT%H%M%S")
        df_signal_event_meta["SignalValue"] = df_signal_event[trigger_signal]
        df_signal_event_meta["EventType"] = df_signal_event["EventType"]
        df_signal_event_meta["EventValue"] = df_signal_event["EventValue"]
        df_signal_event_meta["Message"] = messages[0] 
        df_signal_event_meta["Signal"] = trigger_signal
        
        # If GPS data is to be included, ensure consistent column structure (even if no valid GPS data was extracted)
        if include_gps_data:
            try:
                df_signal_event_meta["Latitude"] = df_signal_event[signal_latitude]
                df_signal_event_meta["Longitude"] = df_signal_event[signal_longitude]
            except:
                df_signal_event_meta["Latitude"] = pd.NA
                df_signal_event_meta["Longitude"] = pd.NA
                                            
        # Define a Parquet schema to ensure correct and consistent type mapping
        schema = pa.schema(
            [
                ("t", pa.timestamp("us")),
                ("EventName", pa.string()),
                ("DeviceID", pa.string()),
                ("EventId", pa.string()),
                ("Message", pa.string()),
                ("Signal", pa.string()),
                ("EventType", pa.string()),
                ("EventValue", pa.int64()),
                ("SignalValue", pa.float64()),
                ("Latitude", pa.float64()),
                ("Longitude", pa.float64())
            ]
        )    
        
        return df_signal_event_meta, schema
    

# -----------------------------------------------------------           
# -----------------------------------------------------------
# Below are useful functions for customizing your Lambda (see CANedge Intro for details)

# -----------------------------------------------
# process_events helper function: Extract messages_filtered_list depending on matching logic for event or custom message data
def get_messages_filtered_list(tmp_output_dir, data):
    if data["messages_match_type"] == "equals":
        messages_filtered_list = data["messages_filtered_list"]
    elif data["messages_match_type"] == "contains":
        messages_filtered_list = [[path.parts[-5] for path in tmp_output_dir.rglob(f'*/*{data["messages_filtered_list"]}*/**/*.parquet') or [None]]]
    elif data["messages_match_type"] == "all_messages":
        messages_filtered_list = [["ALL"]]
    return messages_filtered_list 

# Upload all files in dir to cloud storage
def upload_files_to_cloud(cloud, storage_client, bucket_output, dir):
    from pathlib import Path
    import logging
    import os
    
    logger = logging.getLogger()
    
    # Create list of all local Parquet files and count non-empty folders
    parquet_files = []
    non_empty_folders = 0
    
    for folder in dir.glob("**"):
        if any(folder.glob("*")):
            non_empty_folders += 1
            for file in folder.glob("*.parquet"):
                parquet_files.append(file)
    
    # Upload files to cloud storage
    uploaded_files = 0    
    for file in parquet_files:
        relative_path = str(file.relative_to(dir)).replace(os.sep, '/')
        upload_object(cloud, storage_client, bucket_output, relative_path, str(file), logger)
        uploaded_files += 1
        
    # Print results
    logger.info(f"Uploaded {uploaded_files} Parquet files")
    
    # Return result
    if uploaded_files > 0:
        result = True
    else:
        result = False
        
    return result

# -----------------------------------------------------------
# Load Parquet file to data frame (optionally rename columns for uniqueness, optionally resample)
def load_parquet_to_df(fs_output_file, message, raster="", prefix=False):
    import pyarrow.parquet as pq
    import pandas as pd

    table = pq.read_table(fs_output_file)
    df = table.to_pandas()
    df["t"] = pd.to_datetime(df["t"])
    df.set_index("t", inplace=True)

    if prefix:
        df.columns = [f"{message}_{col}" for col in df.columns]
    
    if raster != "":
        df = df.resample(raster).ffill(limit=1)
        df.index = df.index.round(raster)
        df = df.dropna(how='all')
        
    return df

# -----------------------------------------------------------
# Build a dictionary of all valid paths with key tuples of devices, dates, file_names and messages as values.
def get_all_message_paths(decoded_files):
    all_message_paths = {}
    
    # Iterate over all decoded files, create keys from path components and add messages as values
    for decoded_file in decoded_files:
        p = decoded_file.parts
        device, message, yyyy, mm, dd, file_name = p[-6], p[-5], p[-4], p[-3], p[-2], p[-1]
        date = f"{yyyy}/{mm}/{dd}"
        key = (device, date, file_name)
        
        if key not in all_message_paths:
            all_message_paths[key] = []
        
        all_message_paths[key].append(message)
    
    return all_message_paths

# -----------------------------------------------------------
# Build a dictionary of filtered paths with key tuples of devices, dates, file_names and messages as values.
def get_related_message_paths(all_message_paths, messages_filtered): 
    
    if messages_filtered == ["ALL"]:
        return all_message_paths
    elif len(messages_filtered) > 0:    
        related_message_paths = {
                key: [msg for msg in msgs if msg in messages_filtered]  # Reduce to relevant messages
                for key, msgs in all_message_paths.items()
                if all(msg in msgs for msg in messages_filtered)  # Ensure all filtered messages are present
            }
        return related_message_paths
    else:
        return {}

# -----------------------------------------------------------
# Haversine function to calculate distance in km between two lat/lon points (used in calculated signals example)
def haversine(lat1, lon1, lat2, lon2):
    import math 
        
    lat1_rad, lon1_rad = math.radians(lat1), math.radians(lon1)
    lat2_rad, lon2_rad = math.radians(lat2), math.radians(lon2)
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    a = math.sin(dlat / 2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    distance_in_km = 6371.0 * c
    
    return distance_in_km

# -----------------------------------------------------------
# Function to check if a point is inside any geofence and return the name and ID
def check_geofence(row, signal_latitude, signal_longitude, geofences):
    lat, lon = row[signal_latitude], row[signal_longitude]
    
    for geofence in geofences:
        geofence_id, geofence_name, (geofence_lat, geofence_lon), geofence_radius = geofence
        distance_in_km = haversine(lat, lon, geofence_lat, geofence_lon)
        
        if distance_in_km <= geofence_radius:
            return geofence_id

    return 0 # return 0 if no geofence is matched
