#!/usr/bin/env bash

# Function to check the exit status and display success or failure message
check_status() {
    if [ $1 -eq 0 ]; then
        echo "Success: $2"
    else
        echo "Failure: $2"
        exit 1
    fi
}

cd "${WORKSPACE}" || { echo "Failed to change directory to ${WORKSPACE}"; exit 1; }

echo "PWD: ${WORKSPACE}"
echo "CURRENT USER: $(whoami)"

# Clean target directory
sudo rm -rf /var/lib/jenkins/workspace/CTA-Harbour-Dev/target/*

echo "To check the version of maven code"
mvn -N io.takari:maven:wrapper
check_status $? "Maven wrapper set up"

echo "To install Maven Package modules"
cd /var/lib/jenkins/workspace/CTA-Harbour-Dev || { echo "Failed to change directory to project directory"; exit 1; }
mvn clean install
check_status $? "Maven build"

# Define variables
PROJECT_NAME="cta-harbour"
BUCKET_NAME="ctaharbour-dev"
VERSION="0.0.1-SNAPSHOT"
JAR_FILE="cta-harbour-0.0.1-SNAPSHOT.jar"
TARGET_DIR="backup"
CURRENT_DATE=$(date +%Y-%m-%d)

echo "Backing up the existing file on the remote server"
ssh root@34.72.23.66 "
if [ -f /root/cta-harbour/$JAR_FILE ]; then mv /root/cta-harbour/$JAR_FILE /root/cta-harbour/$JAR_FILE.$CURRENT_DATE || exit 1
fi
"
check_status $? "Backup existing file on the remote server"

echo "Authenticate with Google Cloud and set project"
gcloud auth activate-service-account --key-file=/root/devops_service_Account/devops-353405-2c8da15af2a1.json
gcloud config set project "actual-project-id"  # Replace with the actual project ID
check_status $? "Authenticate with Google Cloud"

echo "Copy the renamed file to cloud storage"
scp root@34.72.23.66:/root/cta-harbour/$JAR_FILE.$CURRENT_DATE /tmp/ && \
gsutil cp /tmp/$JAR_FILE.$CURRENT_DATE gs://$BUCKET_NAME/$TARGET_DIR
check_status $? "Copy renamed file to cloud storage"

# Find PID of the Java process and kill it
JAVA_PID=$(ssh root@34.72.23.66 "ps aux | grep java | grep -v grep | awk '{print \$2}'")
if [ -n "$JAVA_PID" ]; then
    echo "Killing Java process with PID: $JAVA_PID"
    ssh root@34.72.23.66 "kill $JAVA_PID"
    check_status $? "Kill Java process"
else
    echo "No Java process found"
fi

echo "Remove backup file from VM"
ssh root@34.72.23.66 "rm -f /root/cta-harbour/$JAR_FILE.$CURRENT_DATE"
check_status $? "Remove backup file from VM"

echo "Copy the newly generated jar file to the remote server"
scp /var/lib/jenkins/workspace/CTA-Harbour-Dev/target/$JAR_FILE root@34.72.23.66:/root/cta-harbour/
check_status $? "Copy new jar file to the remote server"

# Start the new JAR file on the remote server
echo "Starting the new JAR file on the remote server..."
ssh root@34.72.23.66 "
nohup java -jar /root/cta-harbour/$JAR_FILE > /root/cta-harbour/application.log 2>&1 &
"
check_status $? "Start new JAR file on the remote server"

echo "Deployment completed successfully"

