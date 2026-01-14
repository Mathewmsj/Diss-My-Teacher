# Performance Testing Guide

## Prerequisites

Since you don't have sudo permissions, we'll use Python-based testing instead of Apache Benchmark (ab).

### Required Python Package

The script uses the `requests` library. Install it if needed:

```bash
# In your virtual environment (backend-env)
pip install requests
```

Or if you're not in a virtual environment:

```bash
pip3 install requests --user
```

## Running Performance Tests

### Basic Usage

```bash
# Test with default settings (1000 requests, 10 concurrent)
python3 performance-test.py http://localhost:5009

# Custom configuration
python3 performance-test.py http://localhost:5009 -n 1000 -c 10

# Test different backend URL
python3 performance-test.py http://110.40.153.38:5009 -n 1000 -c 10
```

### Command Line Options

- `base_url`: Base URL of the backend (default: http://localhost:5009)
- `-n, --requests`: Total number of requests (default: 1000)
- `-c, --concurrency`: Concurrency level (default: 10)

### Example Output

The script will:
1. Test multiple endpoints
2. Show detailed results for each endpoint
3. Provide a summary comparison
4. Identify the worst-performing endpoint

## Tested Endpoints

The script tests the following endpoints:

1. `/healthz` - Health check (should be fastest)
2. `/api/teachers/` - Teachers list (may require authentication)
3. `/api/ratings/` - Ratings list (may require authentication)
4. `/api/users/` - Users list (requires authentication)

## Notes

- Some endpoints may require authentication. If you see 401/403 errors, those endpoints won't be tested properly.
- The script measures response times, requests per second, and failure rates.
- Results are sorted to identify the worst-performing endpoint.

## Alternative: Install Apache Benchmark

If you can get sudo access or contact your system administrator, you can install Apache Benchmark:

```bash
# For OpenCloudOS/CentOS/RHEL
sudo yum install -y httpd-tools

# Then use the bash script
./performance-test.sh http://localhost:5009 1000 10
```

