FROM python:3.11-slim

LABEL org.opencontainers.image.source=https://github.com/CSS-Electronics/canedge-azure-cloud-terraform

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY synapse-map-tables.py .

# Make the script executable
RUN chmod +x synapse-map-tables.py

# Run the script when the container starts
CMD ["python", "synapse-map-tables.py"]
