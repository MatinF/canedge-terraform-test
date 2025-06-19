.. _ref-parquet-data-lake-google:

Google Parquet data lake
===================================

.. image:: https://canlogger1000.csselectronics.com/img/parquet-data-lake-google.svg
            :alt: Google Parquet data lake
            :width: 70%

Here we explain how to create a Google Parquet data lake (with Cloud Function automation). 

This can e.g. be used in :ref:`Grafana-BigQuery dashboards <ref-grafana-bigquery>` or :ref:`Python/MATLAB <ref-mdf4-decoders>`. 

.. note::

   This guide (and technical support on it) is intended for advanced users 

.. only:: html

  .. contents:: Table of Contents

----

Overview
--------------
            
This guide enables you to set up an automated data pre-processing workflow in your Google Cloud Platform (GCP). This includes an 'input bucket' (for MDF/DBC files) and an 'output bucket' (for Parquet files). It also includes a 'Cloud Function', which auto-processes new MDF files uploaded to the input bucket - and outputs them as decoded Parquet files in the output bucket. 


.. Note:: 

  The below assumes that you have a GCP account and input bucket\ [#fn-input-bucket]_ \ [#fn-active-input-bucket]_. If not, see :ref:`this <ref-clouds>`. Ensure that your input bucket is a single region bucket (e.g. ``europe-west3``)


.. note:: 

   Ensure you :ref:`test the MF4 decoders <ref-parquet-data-lake>` with your log files & DBC files locally before proceeding.


------------

1: Upload Cloud Function zip and DBC files to input bucket
-----------------------------------------------------------

#. Upload below zip and your :ref:`prepared DBC files <ref-parquet-data-lake>` to your input bucket root via the GCP console

:download:`Cloud Function zip </_static/files/log-file-tools/mdf4-decoders/parquet-data-lake/mdf-to-parquet-google-function-v1.3.0.zip>` | :download:`changelog </_static/files/log-file-tools/mdf4-decoders/parquet-data-lake/changelogs/mdf-to-parquet-google-function-changelog.txt>`


------------

2: Create output bucket
-----------------------------------------------------------

#. Ensure the active Project contains your input bucket 
#. Create an 'output bucket' with the name ``<your-input-bucket-name>-parquet``\ [#fn-output-bucket-name]_
#. Set the region to match your input bucket (e.g. ``europe-west3``) and click 'Create'

------------


3: Deploy Cloud Function 
-----------------------------------------------------------

1. In the GCP console, search for 'Cloud Run Functions' and 'Write a function' 
2. Agree to enable any APIs required during the setup when prompted
3. Agree to 'Grant all' permissions for internal service accounts when prompted 
4. In 'Configuration' use the below settings and click 'Next':

.. code-block:: text 

  Function name: mdf-to-parquet 
  Region: <enter your input/output bucket region>
  Runtime: Python 3.11
  Trigger type: Cloud Storage 
  Bucket: <select your input bucket>
  Memory allocated: 512 MiB 
  CPU: 1 
  Maximum concurrent requests per instance: 50 (modify this as per your scale)
  Minimum number of instances: 0
  Maximum number of instances: 100
  Runtime service account: Select the default account 

5. In 'Code' set runtime to ``Python 3.11`` and source code to 'ZIP from cloud storage'
6. Browse to select your uploaded Cloud Function zip in your input bucket
7. Set the 'Entry point' to ``process_mdf_file``
8. Click 'Deploy' and verify that the function is deployed correctly 

--------------

4: Test Cloud Function 
-----------------------------------------------------------
#. Upload a test MDF file from your CANedge into your input bucket via the GCP console
#. Verify that the decoded Parquet files are created in your output bucket

Your data lake will now get auto-filled when new MDF files are uploaded to the input bucket.

.. note:: 

  If you are not seeing the expected results, review the 'Logs' of your Cloud Function
  
|

Next, you can e.g. set up :ref:`Google BigQuery <ref-google-bigquery>` to enable :ref:`Grafana-BigQuery dashboards <ref-grafana-bigquery>`.


----

.. [#fn-input-bucket] If you have connected a CANedge2/CANedge3 to a Google Cloud Storage bucket then this is your input bucket 

.. [#fn-active-input-bucket] If this is your first time deploying this integration, consider creating a 'playground' input bucket that is separate from your 'production' input bucket (where your CANedge units are uploading data to). This allows you to test the full integration with sample MDF files - after which you can deploy the setup on your production input bucket.

.. [#fn-output-bucket-name] If your input bucket is named ``my-bucket``, your output bucket must be named ``my-bucket-parquet`` (the Cloud Function automation relies on this)
