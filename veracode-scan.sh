#!/bin/bash

# Veracode Software Composition Analysis (SCA) Script
# This script triggers a Veracode SCA scan to identify vulnerable open source components

set -e

echo "Starting Veracode Software Composition Analysis (SCA) Scan..."

# Check if Veracode API credentials are set
# if [ -z "$VERACODE_API_KEY_ID" ] || [ -z "$VERACODE_API_KEY_SECRET" ]; then
    # echo "Error: VERACODE_API_KEY_ID and VERACODE_API_KEY_SECRET environment variables must be set"
    # exit 1
# fi

# Check if Veracode CLI is installed
if ! command -v veracode &> /dev/null; then
    echo "Error: Veracode CLI is not installed."
    echo "Or visit: https://docs.veracode.com/r/Veracode_CLI"
    exit 1
fi

echo "Veracode CLI found: $(veracode version)"

# Project configuration
PROJECT_NAME="VeraDemo-Java"
PROJECT_URL="https://github.com/veracode/verademo"

# Check if pom.xml exists (Maven project)
if [ ! -f "pom.xml" ]; then
    echo "Warning: pom.xml not found. This script expects a Maven project."
fi

# Run SCA scan
echo ""
echo "Running SCA scan for project: $PROJECT_NAME"
echo "Scanning directory: $(pwd)"
echo ""

veracode scan \
    --source . \
    --type directory \
    --output results-sca.json

SCAN_EXIT_CODE=$?

echo ""
echo "SCA scan completed with exit code: $SCAN_EXIT_CODE"

if [ $SCAN_EXIT_CODE -eq 0 ]; then
    echo "✓ SCA scan passed - no high or critical vulnerabilities found"
else
    echo "✗ SCA scan failed - vulnerabilities detected"
    echo "Check results-sca.json for details"
fi

echo ""
echo "Scan results saved to: results-sca.json"
echo ""

exit $SCAN_EXIT_CODE
