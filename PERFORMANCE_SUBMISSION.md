# Performance Bottleneck Analysis - Submission

## Test Commands Used

### Main Test Script
```bash
./performance-test.sh http://localhost:5009 1000 10
```

### Individual Endpoint Tests
```bash
# Health check endpoint (baseline)
ab -n 1000 -c 10 http://localhost:5009/healthz

# Teachers list endpoint
ab -n 1000 -c 10 http://localhost:5009/api/teachers/

# Ratings list endpoint
ab -n 1000 -c 10 http://localhost:5009/api/ratings/

# Users list endpoint
ab -n 1000 -c 10 http://localhost:5009/api/users/

# SuperAdmin stats endpoint (requires authentication)
ab -n 1000 -c 10 -H "Authorization: Token YOUR_TOKEN" http://localhost:5009/api/superadmin/stats/
```

## Test Results Summary

(Results should be filled in after running the tests on your server)

| Endpoint | Requests/sec | Time/req (ms) | Failed Requests | Total Time (s) |
|----------|--------------|---------------|-----------------|----------------|
| `/healthz` | [To be filled] | [To be filled] | [To be filled] | [To be filled] |
| `/api/teachers/` | [To be filled] | [To be filled] | [To be filled] | [To be filled] |
| `/api/ratings/` | [To be filled] | [To be filled] | [To be filled] | [To be filled] |
| `/api/users/` | [To be filled] | [To be filled] | [To be filled] | [To be filled] |
| `/api/superadmin/stats/` | [To be filled] | [To be filled] | [To be filled] | [To be filled] |

## Worst-Performing Endpoint

**Endpoint**: `/api/superadmin/stats/`

This endpoint is identified as the worst-performing endpoint based on code analysis.

## Performance Bottleneck Analysis

### Root Cause

The `/api/superadmin/stats/` endpoint performs poorly due to **inefficient database queries**:

1. **11 Sequential COUNT Queries**: The endpoint executes 11 separate database `count()` operations sequentially:
   - `School.objects.count()`
   - `Teacher.objects.count()`
   - `User.objects.count()`
   - `User.objects.filter(is_staff=True).count()`
   - `Rating.objects.count()`
   - `Rating.objects.filter(created_at__date=today).count()`
   - `User.objects.filter(approval_status=User.APPROVAL_PENDING).count()`
   - `User.objects.filter(approval_status=User.APPROVAL_APPROVED).count()`
   - `User.objects.filter(approval_status=User.APPROVAL_REJECTED).count()`
   - `UserInteraction.objects.filter(interaction_type=UserInteraction.LIKE).count()`
   - `UserInteraction.objects.filter(interaction_type=UserInteraction.DISLIKE).count()`

2. **Full Table Scans**: Each `count()` query scans the entire table (or filtered subset) without optimized indexes, which becomes slower as data grows.

3. **No Caching**: Statistics are computed in real-time on every request, even though this data changes infrequently.

4. **Blocking Operations**: All database queries execute sequentially, blocking the request thread until all queries complete.

### Contributing Factors

- **Lack of caching**: No caching mechanism to store computed statistics
- **Missing database indexes**: Filtered fields (e.g., `approval_status`, `interaction_type`, `created_at`) may lack proper indexes
- **Sequential execution**: All queries execute one after another instead of being optimized or parallelized
- **Synchronous operations**: Blocking database operations prevent concurrent request handling

### Recommended Solutions

1. **Implement caching** (5-15 minute TTL) using Django's cache framework
2. **Add database indexes** on frequently filtered fields
3. **Optimize queries** using conditional aggregation to reduce the number of database queries
4. **Consider materialized views** or database-level optimizations for statistics

