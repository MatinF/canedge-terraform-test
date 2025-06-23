.. _ref-google-bigquery:

Set up Google BigQuery
===================================

.. image:: https://canlogger1000.csselectronics.com/img/parquet-data-lake-google-bigquery.svg
            :alt: Google BigQuery interface
            :width: 70%

BigQuery makes it simple and fast to query data from your Google Parquet data lake via SQL. It can e.g. be used in e.g. :ref:`Grafana-BigQuery dashboards <ref-grafana-bigquery>` or Python scripts. 

In this section we explain how you can set up BigQuery. 

.. only:: html

  .. contents:: Table of Contents

----

Prerequisites 
--------------------------------------------------
#. :ref:`Set up Google Parquet data lake <ref-parquet-data-lake-google>` [~10 min]

.. note:: 

   The above steps are required before proceeding

----

Create 'admin' service account (for BigQuery  + Storage)
----------------------------------------------------------
1. Go to 'IAM and admin/Service accounts/Create'
2. Specify name as ``bigquery-storage-admin``
3. Add the below roles and click 'Done'\ [#fn-minimal-access]_

.. code-block:: text 

  BigQuery Admin
  Storage Admin

4. Open the service account and go to 'Keys/Add key/Create new key/JSON'
5. Download the key and name it ``bigquery-storage-admin-account.json``

-------------

Create 'user' service account (for BigQuery)
----------------------------------------------------
1. Go to 'IAM and admin/Service accounts/Create'
2. Specify name as ``bigquery-user``
3. Add the below roles and click 'Done'\ [#fn-minimal-access]_

.. code-block:: text 

  BigQuery Data Viewer
  BigQuery Job User
  Storage Object Viewer

4. Open the service account and go to 'Keys/Add key/Create new key/JSON'
5. Download the key and name it ``bigquery-user-account.json``

----------

Create BigQuery data set
--------------------------------------------------
#. In the GCP console go to BigQuery
#. In the Explorer view, click the '...' next to your project ID and select 'Create data set'
#. Name it ``lakedataset1`` and use the same region as your buckets (e.g. ``europe-west3``)

.. note::

  The dataset must be named as above for scripts/templates to work

------------

Map your Parquet data lake to tables
--------------------------------------------
#. Verify that your output bucket contains Parquet files\ [#fn-parquet-files]_
#. Download and unzip below script
#. Place the ``bigquery-storage-admin-account.json`` next to the Python script
#. Open the ``bigquery-map-tables.py`` via a text editor
#. Add your details (project ID, data set ID, output bucket name) and save the script
#. Run the script to map your current Parquet data lake to tables\ [#fn-run-script]_

:download:`BigQuery map tables script </_static/files/log-file-tools/mdf4-decoders/parquet-data-lake-interfaces/bigquery/bigquery-map-tables-vT.2.0.zip>` | :download:`changelog </_static/files/log-file-tools/mdf4-decoders/parquet-data-lake-interfaces/bigquery/changelogs/bigquery-map-tables-changelog.txt>`

.. note::

  The script adds 'meta data' about your output bucket. If new devices/messages are added to your Parquet data lake, the script should be run again (manually or by schedule)\ [#re-run-script]_

| 

You are now ready to use BigQuery as a data source in e.g. :ref:`Grafana-BigQuery dashboards <ref-grafana-bigquery>`.

----------

.. [#fn-minimal-access] Once you are done testing, you can optionally restrict the service account further if needed via e.g. IAM conditions

.. [#fn-parquet-files] If your output bucket is empty, you can upload a test MDF file to your input bucket to create some Parquet data

.. [#fn-run-script] This assumes that you have installed `Python 3.11 <https://www.python.org/downloads/release/python-3119/>`_ and the ``requirements.txt`` (we recommend using a virtual environment). You can set this up by running ``python -m venv env & env\Scripts\activate & pip install -r requirements.txt``

.. [#re-run-script] You only need to re-run the script if new tables are to be created, not if you simply add more data to an existing table