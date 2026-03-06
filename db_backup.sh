#!/bin/bash

set -e

BACKUP_BASE_DIR="/var/lib/jenkins/scripts/jenkins/jenkins-backups"
# Current date in YYYY-MM-DD format
TODAY=$(date +%F)

# Backup directory for today
BACKUP_DIR="${BACKUP_BASE_DIR}/${TODAY}"

# GCP Configuration
GCP_BUCKET="git_daily_backup/DB_BACKUP"
GCP_SERVICE_ACCOUNT_KEY="/var/lib/jenkins/service_account/devops-353405-2c8da15af2a1.json"  # Update this path
ARCHIVE_NAME="backup_${TODAY}.tar.gz"

# Function to print error messages
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

echo "Creating backup directory: ${BACKUP_DIR}"
mkdir -p "$BACKUP_DIR"

echo "Checking the version of PostgreSQL"
psql --version

echo "Taking cta_dev database backup"

# Set the password for cta_dev_user
export PGPASSWORD='usKJ68tHCw+fCTA4'

# Create a custom format dump (.backup)
pg_dump -h 34.145.206.207 -U cta_dev_user -d cta_dev -Fc > "${BACKUP_DIR}/cta_dev.backup"

# Create a plain text dump (.sql)
pg_dump -h 34.145.206.207 -U cta_dev_user -d cta_dev -Fp > "${BACKUP_DIR}/cta_dev.sql"


echo "Taking cta_dev_Admin database backup"

# Set the password for cta_dev_joget_user
export PGPASSWORD='usKJ68tHCw+fjogA4'

# Create a custom format dump (.backup)
pg_dump -h 34.145.206.207 -U cta_dev_joget_user -d cta_Admin -Fc > "${BACKUP_DIR}/cta_Admin.backup"

# Create a plain text dump (.sql)
pg_dump -h 34.145.206.207 -U cta_dev_joget_user -d cta_Admin -Fp > "${BACKUP_DIR}/cta_Admin.sql"

echo "Taking CTA-HARBOR-PROD database backup"

# Set the password for cta_prod_user
export PGPASSWORD='usKJ68tHCCTA+pr+od4'

# Create a custom format dump (.backup)
pg_dump -h 34.145.206.207 -U cta_prod_user -d cta_prod -Fc > "${BACKUP_DIR}/cta_prod.backup"

# Create a plain text dump (.sql)
pg_dump -h 34.145.206.207 -U ccta_prod_user -d cta_prod -Fp > "${BACKUP_DIR}/cta_prod.sql"

echo "Taking cta_Admin_prod database backup"

# Set the password for cta_Admin_prod
export PGPASSWORD='usKJ6pr+odCw+fjogA4'

# Create a custom format dump (.backup)
pg_dump -h 34.145.206.207 -U cta_prod_joget_user -d cta_Admin_prod -Fc > "${BACKUP_DIR}/cta_Admin_prod.backup"

# Create a plain text dump (.sql)
pg_dump -h 34.145.206.207 -U cta_prod_joget_user -d cta_Admin_prod -Fp > "${BACKUP_DIR}/cta_Admin_prod.sql"


echo "Taking snapmoney_dev database backup"

# Set the password for snapmoney_dev_user
export PGPASSWORD='C=x9R-+VL>{qtsvd'

# Create a custom format dump (.backup)
pg_dump -h 34.131.204.60 -U snapmoney_dev_user -d snapmoney_dev -Fc > "${BACKUP_DIR}/snapmoney_dev.backup"

# Create a plain text dump (.sql)
pg_dump -h 34.131.204.60 -U snapmoney_dev_user -d snapmoney_dev -Fp > "${BACKUP_DIR}/snapmoney_dev.sql"

echo "Taking Snapmoney-TEST database backup"

# Set the password for snapmoney_test
export PGPASSWORD='C=x9R-+VL>{qtsvt'

# Create a custom format dump (.backup)
pg_dump -h 34.131.204.60 -U snapmoney_test_user -d snapmoney_test -Fc > "${BACKUP_DIR}/snapmoney_test.backup"

# Create a plain text dump (.sql)
pg_dump -h 34.131.204.60 -U snapmoney_test_user -d snapmoney_test -Fp > "${BACKUP_DIR}/snapmoney_test.sql"

echo "Taking Snapmoney-PROD database backup"

# Set the password for snapmoney_jw_prod
export PGPASSWORD='Microgrid@123'

# Create a custom format dump (.backup)
pg_dump -h 34.131.204.60 -U snapmoney_jw_prod -d snapmoney_user -Fc > "${BACKUP_DIR}/snapmoney_jw_prod.backup"

# Create a plain text dump (.sql)
pg_dump -h 34.131.204.60 -U snapmoney_jw_prod -d snapmoney_user -Fp > "${BACKUP_DIR}/snapmoney_jw_prod.sql"


echo "Backup process completed for both databases."

echo "Compressing backup directory into ${ARCHIVE_NAME}..."
tar -czvf "${BACKUP_BASE_DIR}/${ARCHIVE_NAME}" -C "${BACKUP_BASE_DIR}" "${TODAY}" || {
    error_exit "Failed to compress backup directory."
}

echo "Backup compressed successfully."

echo "Authenticating with Google Cloud..."

# Check if the service account key file exists
if [ ! -f "${GCP_SERVICE_ACCOUNT_KEY}" ]; then
    error_exit "Service account key file not found at ${GCP_SERVICE_ACCOUNT_KEY}"
fi

# Authenticate using the service account key
gcloud auth activate-service-account --key-file="${GCP_SERVICE_ACCOUNT_KEY}" || {
    error_exit "GCP authentication failed."
}

echo "Authenticated with Google Cloud successfully."

echo "Uploading ${ARCHIVE_NAME} to GCP bucket: ${GCP_BUCKET}/DB_BACKUP/"

gsutil cp "${BACKUP_BASE_DIR}/${ARCHIVE_NAME}" "gs://${GCP_BUCKET}/DB_BACKUP/" || {
    error_exit "Failed to upload backup to GCP bucket."
}

echo "Backup uploaded to GCP bucket successfully."

echo "Cleaning up local backups..."

# Remove the backup directory and the compressed archive
rm -rf "${BACKUP_DIR}" "${BACKUP_BASE_DIR}/${ARCHIVE_NAME}" || {
    echo "Warning: Failed to remove local backups. Please check manually."
}

echo "Local backups cleaned up successfully."

# -------------------------------
# Completion Message
# -------------------------------

echo "Backup process completed successfully on ${TODAY}."

# Exit successfully
exit 0
