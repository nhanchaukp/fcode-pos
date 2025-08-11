#!/bin/sh
set -e

# Script used during deployment on Appwrite Sites

# Replace [appwriteEndpoint] with APPWRITE_ENDPOINT in environment file
sed -i "s|\[appwriteEndpoint\]|$APPWRITE_ENDPOINT|g" lib/config/environment.dart

# Replace [appwriteProjectId] with APPWRITE_PROJECT_ID in environment file
sed -i "s|\[appwriteProjectId\]|$APPWRITE_PROJECT_ID|g" lib/config/environment.dart

# Replace [appwriteProjectName] with APPWRITE_PROJECT_NAME in environment file
sed -i "s|\[appwriteProjectName\]|$APPWRITE_PROJECT_NAME|g" lib/config/environment.dart
