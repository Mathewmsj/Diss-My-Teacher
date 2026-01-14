# Performance Bottleneck Analysis Report

## Objective
Identify and analyze performance bottlenecks in the Rate My Teacher web system using HTTP stress testing with Apache Benchmark.

## Test Configuration
- **Tool**: Apache Benchmark (ab)
- **Total Requests**: 1000
- **Concurrency Level**: 10
- **Backend URL**: http://localhost:5009

## Test Endpoints

### 1. `/healthz` (Health Check)
- **Expected Performance**: Fastest endpoint
- **Operation**: Simple JSON response, no database queries
- **Expected Result**: Very high requests/second, low latency

### 2. `/api/teachers/` (GET Teachers List)
- **Expected Performance**: Moderate
- **Operation**: Database query with `select_related('department')`
- **Potential Issues**: 
  - Returns all teachers (no pagination visible)
  - Large result sets may impact performance
- **Expected Result**: Moderate requests/second

### 3. `/api/ratings/` (GET Ratings List)
- **Expected Performance**: Moderate to Slow
- **Operation**: Database query with `select_related('teacher', 'user')`
- **Potential Issues**:
  - Returns all ratings (no pagination visible)
  - Large result sets with multiple relationships
  - Serialization overhead for complex objects
- **Expected Result**: Moderate to low requests/second

### 4. `/api/users/` (GET Users List)
- **Expected Performance**: Moderate
- **Operation**: Database query with `select_related('school')`
- **Potential Issues**:
  - Requires authentication
  - Returns all users (no pagination visible)
- **Expected Result**: Moderate requests/second

## Expected Worst-Performing Endpoint

Based on code analysis, the **worst-performing endpoint** is expected to be:

### `/api/superadmin/stats/` (SuperAdmin Stats)

**Why this endpoint is likely the slowest:**

1. **Multiple Sequential COUNT Queries** (Lines 1094-1104 in `views.py`):
   ```python
   stats = {
       'schools': School.objects.count(),                    # Query 1
       'teachers': Teacher.objects.count(),                  # Query 2
       'users': User.objects.count(),                        # Query 3
       'admins': User.objects.filter(is_staff=True).count(), # Query 4
       'ratings': Rating.objects.count(),                    # Query 5
       'ratings_today': Rating.objects.filter(created_at__date=today).count(), # Query 6
       'pending_users': User.objects.filter(approval_status=User.APPROVAL_PENDING).count(), # Query 7
       'approved_users': User.objects.filter(approval_status=User.APPROVAL_APPROVED).count(), # Query 8
       'rejected_users': User.objects.filter(approval_status=User.APPROVAL_REJECTED).count(), # Query 9
       'total_likes': UserInteraction.objects.filter(interaction_type=UserInteraction.LIKE).count(), # Query 10
       'total_dislikes': UserInteraction.objects.filter(interaction_type=UserInteraction.DISLIKE).count(), # Query 11
   }
   ```

2. **Performance Issues**:
   - **11 separate database queries** executed sequentially
   - Each `count()` query scans the entire table (or filtered subset)
   - No database indexes mentioned for filtering fields (e.g., `approval_status`, `interaction_type`, `created_at__date`)
   - No caching mechanism
   - Sequential execution (not parallelized)

3. **Scalability Concerns**:
   - As data grows, each `count()` query becomes slower
   - Date filtering on `created_at` may be slow without proper indexing
   - Multiple filtered counts on the same table (User) could be optimized

## Performance Bottleneck Analysis

### Root Causes

1. **Inefficient Database Queries**:
   - Multiple sequential `count()` operations
   - Full table scans for counting operations
   - Date filtering without optimized indexes
   - No query optimization or aggregation

2. **Lack of Caching**:
   - Statistics are computed on every request
   - No caching layer (Redis, Memcached, or Django cache)
   - Real-time computation for data that changes infrequently

3. **Blocking Operations**:
   - All database queries execute sequentially
   - No async/parallel query execution
   - Synchronous database operations block the request

4. **Missing Database Indexes**:
   - Filtered fields may lack indexes:
     - `approval_status` on User table
     - `interaction_type` on UserInteraction table
     - `created_at` on Rating table
     - `is_staff` on User table

### Potential Solutions

1. **Optimize Database Queries**:
   - Use `annotate()` and `aggregate()` to combine multiple counts
   - Add database indexes on frequently filtered fields
   - Use database views or materialized views for statistics

2. **Implement Caching**:
   - Cache statistics for 5-15 minutes (depending on update frequency)
   - Use Django's cache framework (Redis/Memcached)
   - Invalidate cache on data changes

3. **Database Optimization**:
   - Add indexes: `approval_status`, `interaction_type`, `created_at`, `is_staff`
   - Consider using database-specific optimizations (e.g., partial indexes)

4. **Query Optimization**:
   - Combine related counts using conditional aggregation:
     ```python
     from django.db.models import Count, Q
     User.objects.aggregate(
         total=Count('id'),
         admins=Count('id', filter=Q(is_staff=True)),
         pending=Count('id', filter=Q(approval_status=User.APPROVAL_PENDING)),
         # ...
     )
     ```

## Test Commands

### Basic Test (1000 requests, 10 concurrent)
```bash
./performance-test.sh http://localhost:5009 1000 10
```

### Test Individual Endpoints
```bash
# Test health check
ab -n 1000 -c 10 http://localhost:5009/healthz

# Test teachers endpoint
ab -n 1000 -c 10 http://localhost:5009/api/teachers/

# Test ratings endpoint
ab -n 1000 -c 10 http://localhost:5009/api/ratings/

# Test stats endpoint (if authenticated)
ab -n 1000 -c 10 -H "Authorization: Token YOUR_TOKEN" http://localhost:5009/api/superadmin/stats/
```

## Submission Summary

### Test Commands Used
```bash
# Main test script
./performance-test.sh http://localhost:5009 1000 10

# Individual endpoint tests
ab -n 1000 -c 10 http://localhost:5009/healthz
ab -n 1000 -c 10 http://localhost:5009/api/teachers/
ab -n 1000 -c 10 http://localhost:5009/api/ratings/
```

### Worst-Performing Endpoint
**`/api/superadmin/stats/`** (SuperAdmin Statistics endpoint)

### Performance Bottleneck Explanation

The `/api/superadmin/stats/` endpoint performs poorly due to:

1. **11 Sequential Database COUNT Queries**: Each request executes 11 separate database queries sequentially, including multiple filtered counts on large tables.

2. **Full Table Scans**: `count()` operations on large tables without proper indexes result in full table scans, which are expensive operations.

3. **No Caching**: Statistics are computed in real-time on every request, even though this data changes infrequently.

4. **Sequential Execution**: All database queries execute one after another, blocking the request thread until all queries complete.

**Recommended Fix**: Implement caching (5-15 minute TTL), add database indexes on filtered fields, and optimize queries using conditional aggregation to reduce the number of database queries.

