# Deployment of Rate My Teacher Application: A Step-by-Step Guide

**Author:** Mathew  
**Date:** January 2026

## Abstract

This document presents a comprehensive guide for deploying the Rate My Teacher web application on a Linux server. The deployment process covers both IP-based access and domain-based access configurations. The application consists of a Django REST API backend and a Vue.js frontend, deployed using a unified startup script that manages both services simultaneously.

## I. INTRODUCTION

The Rate My Teacher application is a full-stack web application designed to allow students to rate and review teachers. The system architecture comprises:

- **Backend**: Django 4.2.7 REST API with SQLite database
- **Frontend**: Vue.js 3 with Vite build tool
- **Deployment Platform**: Linux server with nginx reverse proxy

This paper documents the complete deployment process, including server setup, code deployment, service configuration, and access methods through both IP addresses and custom domains.

## II. DEPLOYMENT METHODOLOGY

### A. Prerequisites

Before deployment, ensure the following prerequisites are met:

1. **Server Access**: SSH access to the Linux server (IP: 110.40.153.38)
2. **Python Environment**: Python 3.9 or higher installed
3. **Node.js**: Node.js v22+ installed for frontend dependencies
4. **Git**: Git installed for code version control
5. **Domain Configuration**: Domain `mathew.yunguhs.com` configured in nginx

### B. Step-by-Step Deployment Process

#### Step 1: Server Connection

Connect to the server using SSH with your username:

```bash
ssh mathew@110.40.153.38
```

#### Step 2: Clone Repository

Clone the project repository from GitHub:

```bash
git clone https://github.com/Mathewmsj/Diss-My-Teacher.git
cd Diss-My-Teacher
```

If the repository already exists, update it:

```bash
cd Diss-My-Teacher
git pull
```

#### Step 3: Backend Setup

Navigate to the backend directory and create a Python virtual environment:

```bash
cd backend
python3.9 -m venv backend-env
source backend-env/bin/activate
```

Install Python dependencies:

```bash
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

The requirements include:
- Django==4.2.7
- djangorestframework==3.14.0
- django-cors-headers==4.6.0
- gunicorn==21.2.0
- dj-database-url==2.3.0
- psycopg2-binary==2.9.10

#### Step 4: Database Migration

Run database migrations to set up the database schema:

```bash
python manage.py migrate
```

Create a superuser account for administrative access:

```bash
python create_superadmin.py
```

This creates a superadmin account with:
- Username: `Starry`
- Password: `msj20070528`

#### Step 5: Frontend Setup

Return to the project root directory and install Node.js dependencies:

```bash
cd ..
npm install
```

#### Step 6: Configuration Verification

Verify the following configuration files:

**Backend Configuration** (`backend/backend/settings.py`):
- `ALLOWED_HOSTS = ['*']` - Allows access from any host
- Database configured for SQLite by default
- CORS headers enabled for cross-origin requests

**Frontend Configuration** (`vite.config.js`):
- Server host set to `0.0.0.0` for external access
- Port configuration via environment variable `PORT`

**API Configuration** (`src/api.js`):
- Automatic detection of access method (IP vs domain)
- IP access: Uses `http://IP:PORT/api`
- Domain access: Uses relative path `/api` (handled by nginx)

## III. SERVICE DEPLOYMENT

### A. IP-Based Access Deployment

For IP-based access, the application uses default ports:
- Backend: Port 5009
- Frontend: Port 5010

#### Starting Services

Execute the startup script:

```bash
./start.sh
```

Or specify custom ports:

```bash
./start.sh 5009 5010
```

The startup script performs the following operations:

1. **Port Cleanup**: Checks and terminates any processes using the target ports
2. **Backend Launch**: Starts Django development server on `0.0.0.0:5009`
3. **Frontend Launch**: Starts Vite development server on `0.0.0.0:5010`
4. **Process Management**: Saves process IDs to `backend.pid` and `frontend.pid`

#### Accessing the Application

After successful startup, access the application via:

- **Frontend**: `http://110.40.153.38:5010`
- **Backend API**: `http://110.40.153.38:5009/api`

#### Service Verification

Check service status using the diagnostic script:

```bash
./check.sh
```

This script verifies:
- Process status (running/stopped)
- Port listening status
- Recent log entries
- Firewall configuration
- Local connectivity

### B. Domain-Based Access Deployment

For domain-based access, the application uses assigned ports:
- Backend: Port 8806
- Frontend: Port 8807
- Domain: `mathew.yunguhs.com`

#### Starting Services with Domain Ports

Execute the startup script with domain-specific ports:

```bash
./start.sh 8806 8807
```

#### nginx Configuration

The nginx server (pre-configured by administrator) performs the following routing:

1. **Root Domain** (`mathew.yunguhs.com`):
   - Routes to frontend service on port 8807

2. **API Path** (`mathew.yunguhs.com/api`):
   - Routes to backend service on port 8806

#### Accessing the Application

After successful startup, access the application via:

- **Frontend**: `http://mathew.yunguhs.com` or `https://mathew.yunguhs.com`
- **Backend API**: `http://mathew.yunguhs.com/api` or `https://mathew.yunguhs.com/api`

#### Domain-Specific Configuration

The frontend automatically detects domain access and configures API endpoints accordingly:

```javascript
// Automatic API base URL detection
if (hostname.includes('yunguhs.com')) {
    return '/api';  // Relative path for nginx routing
}
```

The backend root path handler redirects to the appropriate frontend URL:

```python
def root(_request):
    host = _request.get_host()
    if 'mathew.yunguhs.com' in host:
        scheme = 'https' if _request.is_secure() else 'http'
        frontend_url = f'{scheme}://mathew.yunguhs.com'
        return HttpResponseRedirect(frontend_url)
```

## IV. OPERATIONAL PROCEDURES

### A. Service Management

#### Stopping Services

Stop all services using:

```bash
./stop.sh
```

This script:
- Reads process IDs from `backend.pid` and `frontend.pid`
- Terminates both processes gracefully
- Cleans up process ID files

#### Restarting Services

Restart services using:

```bash
./restart.sh
```

This script:
- Stops existing services
- Cleans port conflicts
- Verifies dependencies
- Restarts services

#### Viewing Logs

Monitor service logs in real-time:

```bash
# Backend logs
tail -f backend.log

# Frontend logs
tail -f frontend.log
```

### B. Troubleshooting

#### Port Conflict Resolution

If ports are already in use:

```bash
# Check port usage
lsof -i:5009
lsof -i:5010

# Kill processes using ports
lsof -ti:5009 | xargs kill -9
lsof -ti:5010 | xargs kill -9
```

#### Database Migration Issues

If migration fails:

```bash
cd backend
source backend-env/bin/activate
python manage.py migrate --run-syncdb
```

#### Virtual Environment Issues

Recreate virtual environment if corrupted:

```bash
cd backend
rm -rf backend-env
python3.9 -m venv backend-env
source backend-env/bin/activate
pip install -r requirements.txt
```

## V. SECURITY CONSIDERATIONS

### A. Network Security

1. **Firewall Configuration**: Ensure ports 5009, 5010, 8806, and 8807 are accessible
2. **HTTPS**: Use HTTPS for domain access when SSL certificates are configured
3. **CORS**: Configured to allow cross-origin requests from frontend domain

### B. Application Security

1. **Secret Key**: Change `SECRET_KEY` in production settings
2. **Debug Mode**: Set `DEBUG = False` in production
3. **Allowed Hosts**: Configure specific hosts instead of `['*']` in production
4. **Authentication**: Token-based authentication for API access

## VI. RESULTS AND VALIDATION

### A. IP-Based Access Validation

After deployment, validate IP-based access:

1. **Frontend Access**: Navigate to `http://110.40.153.38:5010`
   - Expected: Vue.js application loads successfully
   - API calls automatically use `http://110.40.153.38:5009/api`

2. **Backend API Access**: Test API endpoint `http://110.40.153.38:5009/api/healthz`
   - Expected: Returns `{"status": "ok"}`

3. **Service Status**: Run `./check.sh`
   - Expected: Both services running, ports listening on `0.0.0.0`

### B. Domain-Based Access Validation

After deployment, validate domain-based access:

1. **Frontend Access**: Navigate to `https://mathew.yunguhs.com`
   - Expected: Vue.js application loads successfully
   - API calls automatically use `/api` (relative path)

2. **Backend API Access**: Test API endpoint `https://mathew.yunguhs.com/api/healthz`
   - Expected: Returns `{"status": "ok"}`

3. **Root Path Redirect**: Navigate to `https://mathew.yunguhs.com/api/`
   - Expected: Redirects to `https://mathew.yunguhs.com`

### C. Performance Metrics

Monitor the following metrics:

- **Response Time**: API endpoints respond within 200ms
- **Uptime**: Services remain running after SSH disconnection (using `nohup`)
- **Resource Usage**: Backend ~40MB RAM, Frontend ~60MB RAM

## VII. CONCLUSION

This deployment guide provides a comprehensive methodology for deploying the Rate My Teacher application on a Linux server. The deployment supports both IP-based and domain-based access methods, with automatic configuration detection and routing.

Key achievements:

1. **Unified Deployment**: Single script manages both backend and frontend services
2. **Flexible Access**: Supports both IP and domain access methods
3. **Automated Configuration**: Frontend automatically detects access method and configures API endpoints
4. **Service Management**: Comprehensive scripts for start, stop, restart, and monitoring

The deployment process is reproducible and can be executed in approximately 10-15 minutes, including dependency installation and database migration.

## REFERENCES

[1] Django Software Foundation, "Django Documentation," https://docs.djangoproject.com/, accessed Jan. 2026.

[2] Vue.js Team, "Vite Documentation," https://vitejs.dev/, accessed Jan. 2026.

[3] Nginx Inc., "Nginx Documentation," https://nginx.org/en/docs/, accessed Jan. 2026.

[4] Python Software Foundation, "Python Virtual Environments," https://docs.python.org/3/tutorial/venv.html, accessed Jan. 2026.

[5] Node.js Foundation, "Node.js Documentation," https://nodejs.org/docs/, accessed Jan. 2026.

---

**Appendix A: File Structure**

```
Diss-My-Teacher/
├── backend/
│   ├── backend/
│   │   ├── settings.py      # Django settings
│   │   └── urls.py          # URL routing
│   ├── api/                 # API application
│   ├── manage.py
│   ├── requirements.txt
│   ├── backend-env/         # Python virtual environment
│   └── db.sqlite3           # SQLite database
├── src/                     # Frontend source code
├── start.sh                 # Startup script
├── stop.sh                  # Stop script
├── check.sh                 # Diagnostic script
└── package.json             # Node.js dependencies
```

**Appendix B: Port Configuration**

| Service | IP Access | Domain Access |
|---------|-----------|---------------|
| Backend | 5009      | 8806          |
| Frontend| 5010      | 8807          |

**Appendix C: Environment Variables**

- `DATABASE_URL`: PostgreSQL connection string (optional, for Render database)
- `FRONTEND_URL`: Frontend URL for redirects (optional)
- `PORT`: Frontend port (default: 8080, overridden by script)

