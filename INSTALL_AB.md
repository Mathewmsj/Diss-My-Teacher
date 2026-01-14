# Installing Apache Benchmark (ab)

## Quick Install

On your server, run:

```bash
# Download and run the install script
./install-ab.sh
```

Or install manually:

### For OpenCloudOS/CentOS/RHEL:
```bash
sudo yum install -y httpd-tools
```

Or if using dnf:
```bash
sudo dnf install -y httpd-tools
```

### For Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y apache2-utils
```

## Verify Installation

After installation, verify that `ab` is available:

```bash
ab -V
```

You should see output like:
```
This is ApacheBench, Version 2.3 <$Revision: 1879490 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/
```

## Run Performance Tests

Once installed, you can run the performance tests:

```bash
# Run the test script
./performance-test.sh http://localhost:5009 1000 10

# Or test individual endpoints
ab -n 1000 -c 10 http://localhost:5009/healthz
ab -n 1000 -c 10 http://localhost:5009/api/teachers/
ab -n 1000 -c 10 http://localhost:5009/api/ratings/
```

