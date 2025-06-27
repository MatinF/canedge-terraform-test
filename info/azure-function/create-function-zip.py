#!/usr/bin/env python
"""
Script to create a properly structured Azure Functions ZIP package
that ensures dependencies are correctly installed.
"""

import os
import shutil
import zipfile
from pathlib import Path

# Configuration
SOURCE_DIR = os.path.join(os.path.dirname(os.path.realpath(__file__)), "updated-azure-function")
OUTPUT_ZIP = os.path.join(SOURCE_DIR, "function-deploy-package.zip")

# Ensure we start with a fresh ZIP
if os.path.exists(OUTPUT_ZIP):
    os.remove(OUTPUT_ZIP)

print(f"Creating function ZIP package from {SOURCE_DIR}")
print(f"Output ZIP: {OUTPUT_ZIP}")

# Create a clean ZIP file with proper structure
with zipfile.ZipFile(OUTPUT_ZIP, 'w', zipfile.ZIP_DEFLATED) as zipf:
    # Add all files except existing ZIP files
    for root, _, files in os.walk(SOURCE_DIR):
        for file in files:
            if not file.endswith('.zip'):
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, SOURCE_DIR)
                print(f"Adding: {rel_path}")
                zipf.write(full_path, rel_path)

print("\nDone! Upload this ZIP file to your Azure Storage container and update")
print("the 'function_zip_name' variable in your Terraform deployment script.")
