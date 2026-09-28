#!/usr/bin/env python3
from google.cloud import bigquery

# 1. Initialize BigQuery client
client = bigquery.Client()

# 2. Define Dataset ID and construct Dataset object
dataset_id = f"{client.project}.b543_dataset"
dataset = bigquery.Dataset(dataset_id)
dataset.location = "US"  # Set location (optional)

# Create Dataset (exists_ok=True avoids error if dataset already exists)
dataset = client.create_dataset(dataset, exists_ok=True)
print(f"Dataset '{dataset.dataset_id}' created successfully.")

# 3. Define Table ID and Schema
table_id = f"{dataset_id}.sample_table"

schema = [
    bigquery.SchemaField("id", "INTEGER", mode="REQUIRED"),
    bigquery.SchemaField("name", "STRING", mode="NULLABLE"),
    bigquery.SchemaField("age", "INTEGER", mode="NULLABLE"),
    bigquery.SchemaField("created_at", "TIMESTAMP", mode="NULLABLE"),
]

# Construct Table object
table = bigquery.Table(table_id, schema=schema)

# Create Table
table = client.create_table(table, exists_ok=True)
print(f"Table '{table.table_id}' created successfully inside '{dataset.dataset_id}'.")
print(f"Table '{table.table_id}' created successfully inside '{dataset.dataset_id}'.")
# code done
