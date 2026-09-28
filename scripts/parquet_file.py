import random
import uuid
from datetime import datetime, timedelta
import pandas as pd

# Function to generate a random transaction record
def generate_transaction():
    return {
        "transaction_id": str(uuid.uuid4()),
        "user_id": str(uuid.uuid4()),
        "amount": round(random.uniform(10, 1000), 2),
        "transaction_date": (datetime.now() - timedelta(days=random.randint(0, 365))).strftime("%Y-%m-%d %H:%M:%S"),
        "currency": random.choice(["USD", "EUR", "GBP", "INR"]),
        "status": random.choice(["completed", "pending", "failed"])
    }

# Generate 1000 transaction records
transactions = [generate_transaction() for _ in range(1000)]

# Convert to DataFrame
df = pd.DataFrame(transactions)

# Save as Parquet
parquet_file_path = "transactions.parquet"

df.to_parquet(parquet_file_path, engine="pyarrow", index=False)

print(f"Parquet file saved to {parquet_file_path}")
