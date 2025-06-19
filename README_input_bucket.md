# CANedge Input Bucket Deployment

Deploy input bucket for connecting CANedge devices.

## How to deploy

1. **Make the deployment script executable**:
   ```bash
   chmod +x deploy_input_bucket.sh
   ```

2. **Run the deployment with your project details**:
   ```bash
   ./deploy_input_bucket.sh --project YOUR_PROJECT_ID --region YOUR_REGION --bucket YOUR_BUCKET_NAME
   ```

   Example:
   ```bash
   ./deploy_input_bucket.sh --project my-project-123 --region europe-west1 --bucket canedge-test-bucket-gcp
   ```

3. **When prompted, type `yes` to proceed**

---------

### Notes

- Ensure you select a region near your deployment (see [this link](https://cloud.google.com/storage/docs/locations#location-r) for available regions)
- Your project ID can be found by clicking your project in the Google Cloud console
- The bucket will be created with CORS settings that allow access from any origin (needed for CANcloud access)
- Choose a globally unique bucket name that follows Google Cloud naming requirements
