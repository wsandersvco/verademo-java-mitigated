#!/bin/bash

# Veracode SrcClr Agent Scan Script
# This script performs Software Composition Analysis using the SrcClr agent

set -e

echo "Starting Veracode SRCCLR Agent Scan..."

# Configuration
WORKSPACE_NAME="VeraDemo-Java"
PROJECT_URL="https://github.com/veracode/verademo"

# Download and run SrcClr agent
echo "Downloading and running SRCCLR agent..."
echo ""

# SrcClr scan command with common options
SRCCLR_SCAN_OPTIONS=(
    --url "$PROJECT_URL"
    --ref "main"
    --json srcclr-results.json
)

# Add conditional options based on scan preferences
# Uncomment the options you want to enable:

# Skip build step (scan dependencies only, faster)
# SRCCLR_SCAN_OPTIONS+=(--skip-compile)

# Include development dependencies
# SRCCLR_SCAN_OPTIONS+=(--allow-dirty)

# Recursive scanning for multi-module projects
SRCCLR_SCAN_OPTIONS+=(--recursive)

# Set update advisories to get latest vulnerability data
SRCCLR_SCAN_OPTIONS+=(--update-advisor)

echo "Running SRCCLR agent with options: ${SRCCLR_SCAN_OPTIONS[@]}"
echo ""

# Run the scan
curl -sSL https://download.sourceclear.com/ci.sh | \
    SRCCLR_API_TOKEN="$SRCCLR_API_TOKEN" \
    sh -s -- scan "${SRCCLR_SCAN_OPTIONS[@]}"

SCAN_EXIT_CODE=$?

echo ""
echo "========================================="
echo "SrcClr Agent Scan Completed"
echo "========================================="
echo "Exit code: $SCAN_EXIT_CODE"

if [ $SCAN_EXIT_CODE -eq 0 ]; then
    echo "✓ SrcClr scan completed successfully"
else
    echo "✗ SrcClr scan completed with findings or errors"
fi

echo ""
echo "Results saved to: srcclr-results.json"
echo ""

# Display summary if jq is available
if command -v jq &> /dev/null && [ -f "srcclr-results.json" ]; then
    echo "=== Vulnerability Summary ==="
    echo ""
    
    # Try to extract vulnerability counts
    TOTAL_VULNS=$(jq -r '.records[0].vulnerabilities | length' srcclr-results.json 2>/dev/null || echo "N/A")
    echo "Total vulnerabilities found: $TOTAL_VULNS"
    
    # Try to count by severity
    if [ "$TOTAL_VULNS" != "N/A" ] && [ "$TOTAL_VULNS" != "null" ] && [ "$TOTAL_VULNS" -gt 0 ]; then
        CRITICAL=$(jq -r '[.records[0].vulnerabilities[] | select(.severity >= 9)] | length' srcclr-results.json 2>/dev/null || echo "0")
        HIGH=$(jq -r '[.records[0].vulnerabilities[] | select(.severity >= 7 and .severity < 9)] | length' srcclr-results.json 2>/dev/null || echo "0")
        MEDIUM=$(jq -r '[.records[0].vulnerabilities[] | select(.severity >= 4 and .severity < 7)] | length' srcclr-results.json 2>/dev/null || echo "0")
        LOW=$(jq -r '[.records[0].vulnerabilities[] | select(.severity < 4)] | length' srcclr-results.json 2>/dev/null || echo "0")
        
        echo "  Critical: $CRITICAL"
        echo "  High: $HIGH"
        echo "  Medium: $MEDIUM"
        echo "  Low: $LOW"
    fi
    echo ""
fi

# Optional: Fail build on vulnerabilities
# Uncomment the following lines to fail the build if vulnerabilities are found
# if [ $SCAN_EXIT_CODE -ne 0 ]; then
#     echo "Build failed due to security vulnerabilities"
#     exit 1
# fi

exit $SCAN_EXIT_CODE
