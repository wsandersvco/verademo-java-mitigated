#!/bin/bash

# Veracode Pipeline Scan Script for verademo.war
# This script triggers a Veracode Pipeline Scan on the verademo.war file

set -e

echo "Starting Veracode Pipeline Scan..."

# Check if Veracode API credentials are set
# if [ -z "$VERACODE_API_KEY_ID" ] || [ -z "$VERACODE_API_KEY_SECRET" ]; then
#     echo "Error: VERACODE_API_KEY_ID and VERACODE_API_KEY_SECRET environment variables must be set"
#     exit 1
# fi

# Define the WAR file location
WAR_FILE="app/target/verademo.war"

# Check if the WAR file exists
if [ ! -f "$WAR_FILE" ]; then
    echo "Error: $WAR_FILE not found. Please build the project first."
    echo "Run: mvn clean package"
    exit 1
fi

echo "Found WAR file: $WAR_FILE"

# Download pipeline scanner if not present
SCANNER_JAR="pipeline-scan.jar"
if [ ! -f "$SCANNER_JAR" ]; then
    echo "Downloading Veracode Pipeline Scanner..."
    curl -sSO https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip
    unzip -o pipeline-scan-LATEST.zip
    rm pipeline-scan-LATEST.zip
    echo "Pipeline Scanner downloaded successfully"
fi

# Run the pipeline scan
echo "Running Veracode Pipeline Scan on $WAR_FILE..."
java -jar pipeline-scan.jar \
    --veracode_api_id "$VERACODE_API_KEY_ID" \
    --veracode_api_key "$VERACODE_API_KEY_SECRET" \
    --file "$WAR_FILE" \
    --project_name "VeraDemo" \
    --project_url "https://github.com/veracode/verademo" \
    --project_ref "main" \
    --fail_on_severity="Very High, High" \
    --fail_on_cwe="79,89,78" \
    --json_output_file "results.json"

SCAN_EXIT_CODE=$?

echo "Pipeline scan completed with exit code: $SCAN_EXIT_CODE"

if [ $SCAN_EXIT_CODE -eq 0 ]; then
    echo "✓ Pipeline scan passed - no policy violations found"
else
    echo "✗ Pipeline scan failed - policy violations detected"
    echo "Check results.json for details"
fi

exit $SCAN_EXIT_CODE
