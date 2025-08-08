#!/bin/sh
set -e

# Script used during deployment on Appwrite Sites

# Replace [appwriteEndpoint] with APPWRITE_ENDPOINT in environments files
sed -i "s|appwrite-endpoint|$APPWRITE_ENDPOINT|g" lib/config/environment.dart

# Replace [appwriteProjectId] with APPWRITE_PROJECT_ID in environments files
sed -i "s|appwrite-project-id|$APPWRITE_PROJECT_ID|g" lib/config/environment.dart

# Replace [appwriteProjectName] with APPWRITE_PROJECT_NAME in environments files
sed -i "s|appwrite-project-name|$APPWRITE_PROJECT_NAME|g" lib/config/environment.dart
