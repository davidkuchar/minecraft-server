#!/bin/bash

echo "Testing Pterodactyl login functionality..."

# Step 1: Get a session cookie and CSRF token
echo "Step 1: Getting session and CSRF token..."
COOKIE_JAR="/tmp/pterodactyl_cookies.txt"
rm -f "$COOKIE_JAR"

# Get login page and extract CSRF token
LOGIN_PAGE=$(curl -s -c "$COOKIE_JAR" http://localhost/auth/login)
CSRF_TOKEN=$(echo "$LOGIN_PAGE" | grep 'csrf-token' | sed 's/.*content="\([^"]*\)".*/\1/')

echo "CSRF Token: $CSRF_TOKEN"

if [ -z "$CSRF_TOKEN" ]; then
    echo "ERROR: Could not extract CSRF token"
    exit 1
fi

# Step 2: Attempt login with proper session
echo "Step 2: Attempting login..."
LOGIN_RESPONSE=$(curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "X-Requested-With: XMLHttpRequest" \
    -d "_token=$CSRF_TOKEN&email=newtest@test.com&password=test123" \
    http://localhost/auth/login)

echo "Login response:"
echo "$LOGIN_RESPONSE" | head -10

# Check if we got redirected to dashboard (success) or error page
if echo "$LOGIN_RESPONSE" | grep -q "dashboard" || echo "$LOGIN_RESPONSE" | grep -q "admin"; then
    echo "SUCCESS: Login appears to have worked!"
elif echo "$LOGIN_RESPONSE" | grep -q "419"; then
    echo "ERROR: Still getting 419 (Page Expired) error"
elif echo "$LOGIN_RESPONSE" | grep -q "500"; then
    echo "ERROR: Got 500 Internal Server Error"
else
    echo "UNKNOWN: Got unexpected response"
fi

# Step 3: Try to access dashboard
echo "Step 3: Testing dashboard access..."
DASHBOARD_RESPONSE=$(curl -s -b "$COOKIE_JAR" http://localhost/admin)
if echo "$DASHBOARD_RESPONSE" | grep -q "dashboard\|admin"; then
    echo "SUCCESS: Can access admin dashboard!"
else
    echo "ERROR: Cannot access admin dashboard"
fi

echo "Test complete."