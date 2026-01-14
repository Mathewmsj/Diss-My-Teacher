#!/bin/bash

# Performance Bottleneck Analysis Script
# Using Apache Benchmark (ab) to test API endpoints

echo "=========================================="
echo "Performance Bottleneck Analysis"
echo "=========================================="
echo ""

# Configuration
BACKEND_URL=${1:-"http://localhost:5009"}
REQUESTS=${2:-1000}
CONCURRENCY=${3:-10}

echo "Test Configuration:"
echo "  Backend URL: $BACKEND_URL"
echo "  Total Requests: $REQUESTS"
echo "  Concurrency Level: $CONCURRENCY"
echo ""

# Check if ab is installed
if ! command -v ab &> /dev/null; then
    echo "❌ Apache Benchmark (ab) is not installed"
    echo "Install it with: sudo apt-get install apache2-utils (Debian/Ubuntu)"
    echo "                 or: sudo yum install httpd-tools (CentOS/RHEL)"
    exit 1
fi

# Create results directory
RESULTS_DIR="performance-test-results"
mkdir -p "$RESULTS_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Results will be saved to: $RESULTS_DIR/"
echo ""

# Test endpoints (sorted by expected performance - fastest to slowest)
declare -a ENDPOINTS=(
    "/healthz"
    "/api/teachers/"
    "/api/ratings/"
    "/api/users/"
)

# Test results file
RESULTS_FILE="$RESULTS_DIR/results_${TIMESTAMP}.txt"
SUMMARY_FILE="$RESULTS_DIR/summary_${TIMESTAMP}.txt"

echo "=========================================="
echo "Testing Endpoints"
echo "=========================================="
echo ""

# Test each endpoint
for endpoint in "${ENDPOINTS[@]}"; do
    echo "Testing: $endpoint"
    echo "----------------------------------------"
    
    OUTPUT_FILE="$RESULTS_DIR/$(echo $endpoint | tr '/' '_')_${TIMESTAMP}.txt"
    
    # Run Apache Benchmark
    ab -n $REQUESTS -c $CONCURRENCY \
        -g "${OUTPUT_FILE%.txt}.tsv" \
        "$BACKEND_URL$endpoint" > "$OUTPUT_FILE" 2>&1
    
    # Extract key metrics
    if [ $? -eq 0 ]; then
        # Parse results
        REQUESTS_PER_SEC=$(grep "Requests per second" "$OUTPUT_FILE" | awk '{print $4}')
        TIME_PER_REQUEST=$(grep "Time per request.*mean" "$OUTPUT_FILE" | head -1 | awk '{print $4}')
        FAILED_REQUESTS=$(grep "Failed requests" "$OUTPUT_FILE" | awk '{print $3}' | head -1)
        TOTAL_TIME=$(grep "Time taken for tests" "$OUTPUT_FILE" | awk '{print $5}')
        
        echo "  ✅ Requests per second: $REQUESTS_PER_SEC"
        echo "  ✅ Time per request (ms): $TIME_PER_REQUEST"
        echo "  ✅ Failed requests: $FAILED_REQUESTS"
        echo "  ✅ Total time (s): $TOTAL_TIME"
        
        # Save to summary
        echo "$endpoint|$REQUESTS_PER_SEC|$TIME_PER_REQUEST|$FAILED_REQUESTS|$TOTAL_TIME" >> "$SUMMARY_FILE"
    else
        echo "  ❌ Test failed - check $OUTPUT_FILE for details"
        echo "$endpoint|FAILED|FAILED|FAILED|FAILED" >> "$SUMMARY_FILE"
    fi
    echo ""
done

# Generate summary report
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo ""
echo "Endpoint | Requests/sec | Time/req (ms) | Failed | Total (s)"
echo "---------|--------------|---------------|--------|----------"

# Sort by time per request (worst first)
sort -t'|' -k3 -nr "$SUMMARY_FILE" 2>/dev/null | while IFS='|' read endpoint req_per_sec time_per_req failed total; do
    printf "%-30s | %10s | %13s | %6s | %8s\n" "$endpoint" "$req_per_sec" "$time_per_req" "$failed" "$total"
done

echo ""
echo "Full results saved in: $RESULTS_DIR/"
echo "Summary saved in: $SUMMARY_FILE"
echo ""

# Identify worst performing endpoint
echo "=========================================="
echo "Performance Analysis"
echo "=========================================="
echo ""

WORST_ENDPOINT=$(sort -t'|' -k3 -nr "$SUMMARY_FILE" 2>/dev/null | head -1 | cut -d'|' -f1)
WORST_TIME=$(sort -t'|' -k3 -nr "$SUMMARY_FILE" 2>/dev/null | head -1 | cut -d'|' -f3)

if [ "$WORST_TIME" != "FAILED" ] && [ -n "$WORST_ENDPOINT" ]; then
    echo "Worst Performing Endpoint: $WORST_ENDPOINT"
    echo "Average Response Time: ${WORST_TIME}ms"
    echo ""
    echo "For detailed analysis, check the corresponding output file in $RESULTS_DIR/"
else
    echo "Could not determine worst performing endpoint"
fi

echo ""
echo "=========================================="
echo "Testing Complete"
echo "=========================================="

