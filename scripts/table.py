from google.cloud import bigquery

# 1. Initialize BigQuery client
client = bigquery.Client()

# 2. Define full table ID (project.dataset.table)
table_id = f"{client.project}.b542_dataset.sample_table"

# 3. Define table schema (columns and data types)
schema = [
    bigquery.SchemaField("id", "INTEGER", mode="REQUIRED"),
    bigquery.SchemaField("name", "STRING", mode="NULLABLE"),
    bigquery.SchemaField("age", "INTEGER", mode="NULLABLE"),
    bigquery.SchemaField("created_at", "TIMESTAMP", mode="NULLABLE"),
]

# 4. Construct table object
table = bigquery.Table(table_id, schema=schema)

# 5. Send API request to create table (exists_ok=True prevents error if table exists)
table = client.create_table(table, exists_ok=True)

print(f"Table {table.table_id} created successfully in dataset {table.dataset_id}.")
