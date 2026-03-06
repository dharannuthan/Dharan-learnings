#!/bin/bash

# Function to check the exit status and display success or failure message
check_status() {
    if [ $1 -eq 0 ]; then
        echo "Success: $2"
    else
        echo "Failure: $2"
        exit 1
    fi
}

cd /var/lib/jenkins/workspace/snapmoney-dev/wflow-app || exit 1
mvn clean install package -DskipTests
check_status $? "Build wflow-app"
BUCKET_NAME="snapmoney-dev-internal"
DIRECTORY="backup"
CURRENT_DATE=$(date +%Y-%m-%d)
echo "Backing up the existing file on the remote server"

ssh root@34.131.58.53 "
if [ -f /root/micapps/apache-tomcat-9.0.68/webapps/jw.war ]; then
  mv /root/micapps/apache-tomcat-9.0.68/webapps/jw.war /root/micapps/apache-tomcat-9.0.68/webapps/jw.war.$CURRENT_DATE || exit 1
fi
"
check_status $? "Backup existing file on the remote server"

echo "Authenticate with Google Cloud and set project"
gcloud auth activate-service-account --key-file=/root/devops_service_Account/devops-353405-2c8da15af2a1.json
gcloud config set project snapmoney-dev
check_status $? "Authenticate with Google Cloud"

echo "Copy the renamed file to cloud storage"
scp root@34.131.58.53:/root/micapps/apache-tomcat-9.0.68/webapps/jw.war.$CURRENT_DATE /tmp/ && \
gsutil cp /tmp/jw.war.$CURRENT_DATE gs://$BUCKET_NAME/$DIRECTORY
check_status $? "Copy renamed file to cloud storage"

echo "Copy the newly generated war file to the remote server"
scp /var/lib/jenkins/workspace/snapmoney-dev/wflow-consoleweb/target/jw.war root@34.131.58.53:/root/micapps/apache-tomcat-9.0.68/webapps
check_status $? "Copy new war file to the remote server"

echo "Execute shutdown.sh on the remote server to stop Tomcat"
ssh root@34.131.58.53 "cd /root/micapps/apache-tomcat-9.0.68/bin && sh shutdown.sh"
check_status $? "Shutdown Tomcat"

echo "Remove backup file from VM"
ssh root@34.131.58.53 "cd /root/micapps/apache-tomcat-9.0.68/webapps && rm jw.war.$CURRENT_DATE"
check_status $? "Remove backup file from VM"

# Find PID of the Java process and kill it
JAVA_PID=$(ssh root@34.131.58.53 "ps aux | grep java | grep -v grep | awk '{print \$2}'")
if [ -n "$JAVA_PID" ]; then
    echo "Killing Java process with PID: $JAVA_PID"
    ssh root@34.131.58.53 "kill $JAVA_PID"
fi

sleep 5

echo "Execute startup.sh on the remote server to start Tomcat"
ssh root@34.131.58.53 "cd /root/micapps/apache-tomcat-9.0.68/bin && sh startup.sh"
check_status $? "Startup Tomcat"

echo "Deployment completed successfully"

