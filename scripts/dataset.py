from google.cloud import bigquery

client = bigquery.Client()
dataset_id = f"{client.project}.b542_dataset"

dataset = bigquery.Dataset(dataset_id)
dataset.location = "US"

dataset = client.create_dataset(dataset)
print(f"Dataset {dataset.dataset_id} created successfully.")
