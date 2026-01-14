#!/bin/bash

# Simple test script for individual endpoints (Local Version)
# Test remote API endpoints from your local machine

echo "=========================================="
echo "Testing API Endpoints on Remote Server"
echo "=========================================="
echo ""

BACKEND_URL="http://110.40.153.38:5009"
REQUESTS=${1:-1000}
CONCURRENCY=${2:-10}

echo "Backend URL: $BACKEND_URL"
echo "Requests: $REQUESTS"
echo "Concurrency: $CONCURRENCY"
echo ""

# Check if ab is installed
if ! command -v ab &> /dev/null; then
    echo "❌ Apache Benchmark (ab) is not installed"
    echo ""
    echo "Install it with:"
    echo "  macOS: brew install httpd"
    echo "  Debian/Ubuntu: sudo apt-get install apache2-utils"
    echo "  CentOS/RHEL: sudo yum install httpd-tools"
    exit 1
fi

# Test endpoints
echo "1. Testing /healthz (Health Check)"
echo "----------------------------------------"
ab -n $REQUESTS -c $CONCURRENCY "$BACKEND_URL/healthz" 2>&1 | grep -E "(Requests per second|Time per request|Failed requests|Time taken)"
echo ""

echo "2. Testing /api/teachers/ (Teachers List)"
echo "----------------------------------------"
ab -n $REQUESTS -c $CONCURRENCY "$BACKEND_URL/api/teachers/" 2>&1 | grep -E "(Requests per second|Time per request|Failed requests|Time taken)"
echo ""

echo "3. Testing /api/ratings/ (Ratings List)"
echo "----------------------------------------"
ab -n $REQUESTS -c $CONCURRENCY "$BACKEND_URL/api/ratings/" 2>&1 | grep -E "(Requests per second|Time per request|Failed requests|Time taken)"
echo ""

echo "=========================================="
echo "Testing Complete"
echo "=========================================="

