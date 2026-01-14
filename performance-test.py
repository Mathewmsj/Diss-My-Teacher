#!/usr/bin/env python3
"""
Performance Bottleneck Analysis Script
Using Python requests library for HTTP stress testing
"""

import sys
import time
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
from statistics import mean, median
from collections import defaultdict
import argparse

def test_endpoint(url, num_requests, concurrency):
    """Test a single endpoint with concurrent requests"""
    results = {
        'url': url,
        'total_requests': num_requests,
        'concurrency': concurrency,
        'successful': 0,
        'failed': 0,
        'response_times': [],
        'status_codes': defaultdict(int),
        'errors': []
    }
    
    def make_request():
        """Make a single HTTP request"""
        try:
            start_time = time.time()
            response = requests.get(url, timeout=10)
            elapsed_time = (time.time() - start_time) * 1000  # Convert to ms
            
            results['response_times'].append(elapsed_time)
            results['status_codes'][response.status_code] += 1
            
            if response.status_code == 200:
                results['successful'] += 1
            else:
                results['failed'] += 1
                results['errors'].append(f"Status {response.status_code}")
            
            return response.status_code
        except Exception as e:
            results['failed'] += 1
            results['errors'].append(str(e))
            return None
    
    # Execute requests with thread pool
    start_time = time.time()
    with ThreadPoolExecutor(max_workers=concurrency) as executor:
        futures = [executor.submit(make_request) for _ in range(num_requests)]
        for future in as_completed(futures):
            future.result()  # Wait for completion
    
    total_time = time.time() - start_time
    
    # Calculate statistics
    if results['response_times']:
        results['mean_time'] = mean(results['response_times'])
        results['median_time'] = median(results['response_times'])
        results['min_time'] = min(results['response_times'])
        results['max_time'] = max(results['response_times'])
        results['requests_per_second'] = results['successful'] / total_time if total_time > 0 else 0
    else:
        results['mean_time'] = 0
        results['median_time'] = 0
        results['min_time'] = 0
        results['max_time'] = 0
        results['requests_per_second'] = 0
    
    results['total_time'] = total_time
    
    return results

def print_results(results):
    """Print test results in a formatted way"""
    print(f"\n{'='*60}")
    print(f"Endpoint: {results['url']}")
    print(f"{'='*60}")
    print(f"Total Requests: {results['total_requests']}")
    print(f"Concurrency Level: {results['concurrency']}")
    print(f"Successful Requests: {results['successful']}")
    print(f"Failed Requests: {results['failed']}")
    print(f"Total Time: {results['total_time']:.2f} seconds")
    print(f"\nPerformance Metrics:")
    print(f"  Requests per second: {results['requests_per_second']:.2f}")
    print(f"  Mean time per request: {results['mean_time']:.2f} ms")
    print(f"  Median time per request: {results['median_time']:.2f} ms")
    print(f"  Min time per request: {results['min_time']:.2f} ms")
    print(f"  Max time per request: {results['max_time']:.2f} ms")
    
    if results['status_codes']:
        print(f"\nStatus Codes:")
        for code, count in sorted(results['status_codes'].items()):
            print(f"  {code}: {count}")
    
    if results['errors']:
        print(f"\nErrors (first 5):")
        for error in results['errors'][:5]:
            print(f"  {error}")
    
    print(f"{'='*60}\n")

def main():
    parser = argparse.ArgumentParser(description='Performance Bottleneck Analysis')
    parser.add_argument('base_url', nargs='?', default='http://localhost:5009',
                        help='Base URL of the backend (default: http://localhost:5009)')
    parser.add_argument('-n', '--requests', type=int, default=1000,
                        help='Total number of requests (default: 1000)')
    parser.add_argument('-c', '--concurrency', type=int, default=10,
                        help='Concurrency level (default: 10)')
    
    args = parser.parse_args()
    
    # Test endpoints
    endpoints = [
        '/healthz',
        '/api/teachers/',
        '/api/ratings/',
        '/api/users/',
    ]
    
    print("="*60)
    print("Performance Bottleneck Analysis")
    print("="*60)
    print(f"\nTest Configuration:")
    print(f"  Base URL: {args.base_url}")
    print(f"  Total Requests: {args.requests}")
    print(f"  Concurrency Level: {args.concurrency}")
    print()
    
    all_results = []
    
    # Test each endpoint
    for endpoint in endpoints:
        url = f"{args.base_url}{endpoint}"
        print(f"Testing: {url}...")
        
        try:
            results = test_endpoint(url, args.requests, args.concurrency)
            all_results.append(results)
            print_results(results)
        except KeyboardInterrupt:
            print("\n\nTest interrupted by user")
            sys.exit(1)
        except Exception as e:
            print(f"❌ Error testing {url}: {e}\n")
            continue
    
    # Summary
    if all_results:
        print("="*60)
        print("Summary - Performance Comparison")
        print("="*60)
        print(f"\n{'Endpoint':<30} {'Req/sec':<12} {'Mean (ms)':<12} {'Failed':<10}")
        print("-"*70)
        
        # Sort by mean time (worst first)
        sorted_results = sorted(all_results, key=lambda x: x['mean_time'], reverse=True)
        
        for result in sorted_results:
            endpoint = result['url'].replace(args.base_url, '')
            print(f"{endpoint:<30} {result['requests_per_second']:>10.2f} {result['mean_time']:>10.2f} {result['failed']:>8}")
        
        # Identify worst performing endpoint
        worst = sorted_results[0]
        print(f"\n{'='*60}")
        print("Worst Performing Endpoint:")
        print(f"{'='*60}")
        print(f"Endpoint: {worst['url']}")
        print(f"Mean Response Time: {worst['mean_time']:.2f} ms")
        print(f"Requests per Second: {worst['requests_per_second']:.2f}")
        print(f"Failed Requests: {worst['failed']}")
        print(f"{'='*60}\n")

if __name__ == '__main__':
    main()

