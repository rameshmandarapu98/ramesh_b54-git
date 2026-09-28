#!/bin/bash
set -e

# ============================================================================
# PIPELINE CONFIGURATION & STANDARDS
# ============================================================================
JOB_ID=$(date +%Y%m%d%H%M%S)
PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "rameshb54")

LANDING_DIR="${HOME}/my_folder1"
FILENAME="customers_data_10_09_2026.csv"
LOCAL_FILE="${LANDING_DIR}/${FILENAME}"

GCS_BUCKET="gs://b51_customer/customers"
GCS_ARCHIVE="gs://b51_customer_archive/customers"

STG_TABLE="${PROJECT_ID}:cust_stage_ds_dev.customer_stg"
HIST_TABLE="${PROJECT_ID}:cust_hist_ds_dev.cust_hist"
AUDIT_TABLE="${PROJECT_ID}:cust_audit_ds_dev.pipeline_audit_log"
VIEW_NOPII="${PROJECT_ID}:cust_views_ds_dev.v_cust_nopii"

echo "========================================================"
echo "STARTING CUSTOMER DATA PIPELINE JOB: ${JOB_ID}"
echo "========================================================"

# -------------------------------------------------------------
# STEP 1: Verify Local Landing File & Upload to GCS
# -------------------------------------------------------------
if [ ! -f "$LOCAL_FILE" ]; then
    echo "ERROR: File $LOCAL_FILE not found in landing zone!"
    exit 1
fi

echo "[1/5] Uploading local file to Cloud Storage..."
gcloud storage cp "$LOCAL_FILE" "${GCS_BUCKET}/${FILENAME}"
gcloud storage ls "${GCS_BUCKET}/${FILENAME}"

# -------------------------------------------------------------
# STEP 2: Load to Stage Table & Record Audit Entry
# -------------------------------------------------------------
echo "[2/5] Ingesting CSV into Stage Table..."
START_TIME=$(date -u +"%Y-%m-%d %H:%M:%S")

bq query --use_legacy_sql=false \
"INSERT INTO \`${AUDIT_TABLE}\` (job_id, pipeline_name, source_file, target_table, pipeline_stage, status, start_time) \
 VALUES ('$JOB_ID', 'CUSTOMER_PIPELINE', '$FILENAME', 'customer_stg', 'GCS_TO_STAGE', 'STARTED', '$START_TIME')"

bq load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --replace=true \
  "$STG_TABLE" \
  "${GCS_BUCKET}/${FILENAME}"

STG_COUNT=$(bq query --use_legacy_sql=false --format=csv "SELECT COUNT(1) FROM \`${STG_TABLE}\`" | tail -n 1)
END_TIME=$(date -u +"%Y-%m-%d %H:%M:%S")

bq query --use_legacy_sql=false \
"UPDATE \`${AUDIT_TABLE}\` \
 SET status='SUCCESS', records_loaded=$STG_COUNT, end_time='$END_TIME' \
 WHERE job_id='$JOB_ID' AND pipeline_stage='GCS_TO_STAGE'"

# -------------------------------------------------------------
# STEP 3: Transform & Load Stage to History Table
# -------------------------------------------------------------
echo "[3/5] Loading Stage data into History Table..."
START_TIME=$(date -u +"%Y-%m-%d %H:%M:%S")

bq query --use_legacy_sql=false \
"INSERT INTO \`${AUDIT_TABLE}\` (job_id, pipeline_name, source_file, target_table, pipeline_stage, status, start_time) \
 VALUES ('$JOB_ID', 'CUSTOMER_PIPELINE', 'customer_stg', 'cust_hist', 'STAGE_TO_HIST', 'STARTED', '$START_TIME')"

bq query --use_legacy_sql=false \
"INSERT INTO \`${HIST_TABLE}\` \
 SELECT * FROM \`${STG_TABLE}\`;"

HIST_COUNT=$(bq query --use_legacy_sql=false --format=csv "SELECT COUNT(1) FROM \`${HIST_TABLE}\`" | tail -n 1)
END_TIME=$(date -u +"%Y-%m-%d %H:%M:%S")

bq query --use_legacy_sql=false \
"UPDATE \`${AUDIT_TABLE}\` \
 SET status='SUCCESS', records_loaded=$HIST_COUNT, end_time='$END_TIME' \
 WHERE job_id='$JOB_ID' AND pipeline_stage='STAGE_TO_HIST'"

# -------------------------------------------------------------
# STEP 4: Archive Raw Landing File
# -------------------------------------------------------------
echo "[4/5] Archiving processed file..."
gcloud storage mv "${GCS_BUCKET}/${FILENAME}" "${GCS_ARCHIVE}/${FILENAME}" || echo "Archive bucket upload skipped."

# -------------------------------------------------------------
# STEP 5: Validate Downstream View
# -------------------------------------------------------------
echo "[5/5] Validating views data..."
bq query --use_legacy_sql=false "SELECT * FROM \`${VIEW_NOPII}\` LIMIT 5"

echo "========================================================"
echo "PIPELINE COMPLETED SUCCESSFULLY FOR JOB ID: ${JOB_ID}"
echo "========================================================"
