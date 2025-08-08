#!/bin/bash

# Check if .env file exists
if [ ! -f .env ]; then
  {
    echo "APPWRITE_PROJECT_ID=$APPWRITE_PROJECT_ID"
    echo "APPWRITE_PROJECT_NAME=$APPWRITE_PROJECT_NAME"
    echo "APPWRITE_PUBLIC_ENDPOINT=$APPWRITE_PUBLIC_ENDPOINT"
  } >> .env
fi

# Read .env file and convert it to --dart-define arguments
ARGS=()
while IFS='=' read -r key value || [ -n "$key" ]; do
  # Ignore empty lines and comments
  if [[ -n "$key" && ! "$key" =~ ^# ]]; then
    ARGS+=("--dart-define=${key}=${value}")
  fi
done < .env

# Check if device parameter is provided
if [ -z "$1" ]; then
  echo "Usage: ./build.sh <device_id_or_name>"
  echo "Example: ./build.sh chrome"
  echo "Example: ./build.sh 'iPhone 15'"
  echo ""
  echo "Available devices:"
  flutter devices
  exit 1
fi

DEVICE_NAME="$1"

# Run Flutter app on specified device
echo "Running Flutter app on device: $DEVICE_NAME"
flutter run -d "$DEVICE_NAME" "${ARGS[@]}"
