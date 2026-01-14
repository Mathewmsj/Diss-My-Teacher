#!/bin/bash

# Install Apache Benchmark (ab) tool

echo "=========================================="
echo "Installing Apache Benchmark (ab)"
echo "=========================================="
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ Cannot detect OS"
    exit 1
fi

echo "Detected OS: $OS"
echo ""

# Install based on OS
case $OS in
    "centos"|"rhel"|"opencloudos"|"rocky"|"almalinux")
        echo "Installing httpd-tools using yum/dnf..."
        if command -v dnf > /dev/null 2>&1; then
            sudo dnf install -y httpd-tools
        elif command -v yum > /dev/null 2>&1; then
            sudo yum install -y httpd-tools
        else
            echo "❌ Neither dnf nor yum found"
            exit 1
        fi
        ;;
    "ubuntu"|"debian")
        echo "Installing apache2-utils using apt..."
        sudo apt-get update
        sudo apt-get install -y apache2-utils
        ;;
    *)
        echo "❌ Unsupported OS: $OS"
        echo "Please install manually:"
        echo "  - CentOS/RHEL/OpenCloudOS: sudo yum install httpd-tools"
        echo "  - Ubuntu/Debian: sudo apt-get install apache2-utils"
        exit 1
        ;;
esac

# Verify installation
if command -v ab > /dev/null 2>&1; then
    echo ""
    echo "✅ Apache Benchmark installed successfully!"
    echo ""
    ab -V
    echo ""
    echo "You can now run performance tests:"
    echo "  ./performance-test.sh http://localhost:5009 1000 10"
else
    echo ""
    echo "❌ Installation failed or ab command not found"
    exit 1
fi

