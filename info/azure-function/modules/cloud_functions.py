import json
import os
import logging

def load_credentials(creds_file_path):
    """
    Load credentials from a JSON file and add them to environment variables.
    
    Args:
        creds_file_path (str): Path to the JSON credentials file
        
    Returns:
        bool: True if credentials were successfully loaded, False otherwise
    """
    try:
        if not os.path.exists(creds_file_path):
            logging.error(f"Credentials file not found: {creds_file_path}")
            return False
            
        with open(creds_file_path, 'r') as f:
            creds = json.load(f)
            
        # Add all credentials to environment variables
        for key, value in creds.items():
            os.environ[key] = str(value)
            
        logging.info(f"Successfully loaded credentials from {creds_file_path}")
        return True
    except Exception as e:
        logging.error(f"Error loading credentials from {creds_file_path}: {e}")
        return False
        
def get_log_file_object_paths(cloud, event, logger):
    """
    Extract a list of object paths from the event.
    Handles both single-record and multi-record events.
    
    Args:
        cloud (str): Cloud provider ("Amazon", "Google", or "Azure")
        event (list, dict or object): The event data structure
        logger: Logger object for logging messages
        
    Returns:
        list: List of Path objects representing object paths
    """
    from pathlib import Path
    from urllib.parse import unquote_plus
    
    # Valid log file extensions
    valid_extensions = [".MF4", ".MFC", ".MFE", ".MFM"]
    
    # Helper function to check if a file has valid extension
    def has_valid_extension(filename):
        return any(filename.upper().endswith(ext) for ext in valid_extensions)
    
    from urllib.parse import urlparse

    def extract_blob_path(blob_url):
        """
        Extract the object path from an Azure Storage blob URL, regardless of base URL or container name.
        Returns the full path including any subfolders within the container.
        """
        parsed_url = urlparse(blob_url)
        path_parts = parsed_url.path.split('/')
        if len(path_parts) >= 3:
            object_path = '/'.join(path_parts[2:])
            return object_path
        else:
            return None
    
    log_file_object_paths = []
    
    try:
        if cloud == "Amazon":
            if "Records" in event:
                for record in event["Records"]:
                    if "s3" in record and "object" in record["s3"] and "key" in record["s3"]["object"]:
                        object_key = unquote_plus(record["s3"]["object"]["key"])
                        log_file_object_paths.append(Path(object_key))
                        
        elif cloud == "Azure":
            # Handle both list of objects and single object
            if isinstance(event, list):
                pass
                # for item in event:
                #     # Handle dictionary items (for local testing)
                #     if isinstance(item, dict) and 'name' in item:
                #         file_name = item['name']
                #         # Check if the file has a valid extension
                #         if has_valid_extension(file_name):
                #             parts = file_name.split('/')
                #             object_key = '/'.join(parts[1:])
                #             log_file_object_paths.append(Path(object_key))
                #     # Handle Azure blob objects (for cloud execution)
                #     elif hasattr(item, 'name'):
                #         file_name = item.name
                #         # Check if the file has a valid extension
                #         if has_valid_extension(file_name):
                #             parts = file_name.split('/')
                #             object_key = '/'.join(parts[1:])
                #             log_file_object_paths.append(Path(object_key))
            else:
                data = event.get_json()
                url = data.get('url')
                object_key = extract_blob_path(url)
                logger.info(f"Extracted object key: {object_key}")
                if object_key and has_valid_extension(object_key):
                    log_file_object_paths.append(Path(object_key))
                
        elif cloud == "Google":
            # Handle list of events (for local testing)
            if isinstance(event, list):
                for item in event:
                    # Use CloudEvent attribute-style access
                    if hasattr(item, 'data') and 'name' in item.data:
                        file_name = item.data['name']
                        # Check if the file has a valid extension
                        if has_valid_extension(file_name):
                            log_file_object_paths.append(Path(file_name))
            # Handle single event with CloudEvent attribute-style access
            else:
                if hasattr(event, 'data') and 'name' in event.data:
                    file_name = event.data['name']
                    # Check if the file has a valid extension
                    if has_valid_extension(file_name):
                        log_file_object_paths.append(Path(file_name))
        else:
            logger.error(f"Unsupported cloud provider: {cloud}")
        
        logger.info(f"Log file object paths: {log_file_object_paths}")
        return log_file_object_paths
        
    except Exception as e:
        logger.error(f"Failed to extract object paths from event: {e}")
        return []
        

def normalize_object_path(path):
    # Convert to string if it's a Path object
    path_str = str(path) if not isinstance(path, str) else path
    
    # Replace backslashes with forward slashes
    return path_str.replace('\\', '/')


def download_object(cloud, client, bucket, object_path, local_path, logger):
    """
    Download an object from a cloud storage bucket to a local file.
    
    Args:
        cloud (str): Cloud provider ("Amazon", "Google", or "Azure")
        client: Cloud storage client
        bucket (str): Bucket or container name
        object_path (str): Path to the object in the bucket
        local_path (str): Local path to save the object
        logger: Logger object for logging messages
        
    Returns:
        bool: True if download was successful, False otherwise
    """
    object_path = normalize_object_path(object_path)
    if cloud == "Amazon":
        try:
            client.download_file(bucket, str(object_path), str(local_path))
            logger.info(f"Downloaded object from {bucket}/{object_path} to {local_path}")
            return True
        except Exception as e:
            logger.error(f"Failed to download object from {bucket}/{object_path}: {e}")
            return False
    elif cloud == "Google":
        try:
            # Get the bucket
            gcp_bucket = client.bucket(bucket)
            # Get the blob
            blob = gcp_bucket.blob(object_path)
            
            # Make sure the directory exists
            os.makedirs(os.path.dirname(str(local_path)), exist_ok=True)
            
            # Download the blob
            blob.download_to_filename(str(local_path))
            
            logger.info(f"Downloaded object from Google Cloud Storage bucket {bucket}/{object_path} to {local_path}")
            return True
        except Exception as e:
            logger.error(f"Failed to download object from Google Cloud Storage bucket {bucket}/{object_path}: {e}")
            return False
    elif cloud == "Azure":
        try:
            # Get the container client
            container_client = client.get_container_client(bucket)
            # Get the blob client
            blob_client = container_client.get_blob_client(object_path)
            
            # Download the blob
            with open(str(local_path), "wb") as file:
                download_stream = blob_client.download_blob()
                file.write(download_stream.readall())
                
            logger.info(f"Downloaded object from Azure container {bucket}/{object_path} to {local_path}")
            return True
        except Exception as e:
            logger.error(f"Failed to download object from Azure container {bucket}/{object_path}: {e}")
            return False
    else:
        logger.error(f"Unsupported cloud provider: {cloud}")
        return False


def upload_object(cloud, client, bucket, object_path, local_path, logger):
    """
    Upload a local file to a cloud storage bucket.
    
    Args:
        cloud (str): Cloud provider ("Amazon", "Google", or "Azure")
        client: Cloud storage client
        bucket (str): Bucket or container name
        object_path (str): Path to store the object in the bucket
        local_path (str): Local path of the file to upload
        logger: Logger object for logging messages
        
    Returns:
        bool: True if upload was successful, False otherwise
    """
    object_path = normalize_object_path(object_path)
    
    if cloud == "Amazon":
        try:
            client.upload_file(str(local_path), bucket, object_path)
            logger.info(f"Uploaded object to {bucket}/{object_path}")
            return True
        except Exception as e:
            logger.error(f"Failed to upload object to {bucket}/{object_path}: {e}")
            return False
    elif cloud == "Google":
        try:
            gcp_bucket = client.bucket(bucket)
            blob = gcp_bucket.blob(object_path)
            blob.upload_from_filename(str(local_path))
            logger.info(f"Uploaded object to Google Cloud Storage bucket {bucket}/{object_path}")
            return True
        except Exception as e:
            logger.error(f"Failed to upload object to Google Cloud Storage bucket {bucket}/{object_path}: {e}")
            return False
    elif cloud == "Azure":
        try:
            container_client = client.get_container_client(bucket)
            blob_client = container_client.get_blob_client(object_path)
            with open(str(local_path), "rb") as data:
                blob_client.upload_blob(data, overwrite=True)
            logger.info(f"Uploaded object to Azure container {bucket}/{object_path}")
            return True
        except Exception as e:
            logger.error(f"Failed to upload object to Azure container {bucket}/{object_path}: {e}")
            return False
    else:
        logger.error(f"Unsupported cloud provider: {cloud}")
        return False


def list_objects(cloud, client, bucket, logger, prefix=""):
    """
    List objects in a cloud storage bucket.
    
    Args:
        cloud (str): Cloud provider ("Amazon", "Google", or "Azure")
        client: Cloud storage client
        bucket (str): Bucket or container name
        logger: Logger object for logging messages
        prefix (str): Object prefix to filter results
        
    Returns:
        dict: Standardized response with 'objects' key containing a list of object dictionaries
              with 'name' and other metadata, or an empty list if no objects or error
    """
    if cloud == "Amazon":
        try:
            response = client.list_objects_v2(Bucket=bucket, Prefix=prefix)
            logger.info(f"Listed objects in {bucket} with prefix {prefix}")
            
            # Convert AWS-specific response to standardized format
            result = []
            if "Contents" in response:
                for item in response["Contents"]:
                    result.append({"name": item["Key"], "size": item["Size"], "last_modified": item["LastModified"]})
            
            return {"objects": result}
        except Exception as e:
            logger.error(f"Failed to list objects in {bucket} with prefix {prefix}: {e}")
            return {"objects": []}
    elif cloud == "Google":
        try:
            gcp_bucket = client.bucket(bucket)
            blobs = gcp_bucket.list_blobs(prefix=prefix)
            result = []
            for blob in blobs:
                result.append({
                    "name": blob.name,
                    "size": blob.size,
                    "last_modified": blob.updated
                })
                
            logger.info(f"Listed objects in GCP bucket {bucket} with prefix {prefix}")
            return {"objects": result}
        except Exception as e:
            logger.error(f"Failed to list objects in GCP bucket {bucket} with prefix {prefix}: {e}")
            return {"objects": []}
    elif cloud == "Azure":
        try:
            container_client = client.get_container_client(bucket)
            result = []
            blobs = container_client.list_blobs(name_starts_with=prefix)
            for blob in blobs:
                result.append({
                    "name": blob.name,
                    "size": blob.size,
                    "last_modified": blob.last_modified
                })
            
            logger.info(f"Listed objects in Azure container {bucket} with prefix {prefix}")
            return {"objects": result}
        except Exception as e:
            logger.error(f"Failed to list objects in Azure container {bucket} with prefix {prefix}: {e}")
            return {"objects": []}
    else:
        logger.error(f"Unsupported cloud provider: {cloud}")
        return {"objects": []}


def publish_notification(cloud, client, subject, message, logger):
    """
    Publish a notification to a cloud messaging service.
    
    Args:
        cloud (str): Cloud provider ("Amazon", "Google", or "Azure")
        client: Cloud notification client
        subject (str): Notification subject
        message (str): Notification message body
        message_attributes (dict): Additional message attributes
        logger: Logger object for logging messages
        
    Returns:
        bool: True if notification was published successfully, False otherwise
    """
    import os
    if cloud == "Amazon":
        if notification_client == None:
            logger.info(f"- No message client available")
            return False
        
        target = os.environ.get("SNS_ARN", "NONE")
        message_attributes = {'DeduplicationId': {'DataType': 'String','StringValue': subject.replace(' ', '_').replace("|","")}} 
        try:
            response = client.publish(
                TopicArn=target,
                Subject=subject,
                Message=message,
                MessageAttributes=message_attributes
            )
         
            logger.info(f"Published message with subject '{subject}' to SNS topic: {target}")
            return True
        except Exception as e:
            logger.error(f"Error publishing to SNS: {e}")
            return False
    elif cloud == "Google":
        # Below will trigger a GCP Metric --> Alert --> Notification based on the payload containing 'NEW EVENT'
        logger.info(f"NEW EVENT: {message}")
    elif cloud == "Azure":
        # Add NEW EVENT log pattern for Azure Monitor to detect
        logger.info(f"NEW EVENT: {message}")
        return True
    else:
        logger.error(f"Unsupported cloud provider: {cloud}")
        return False
