#!/bin/bash

# Configuration
MYSQL_USER="root"
MYSQL_PASSWORD="Raoinfotech@09"
DATABASE_NAME="aibe"
TABLE_NAME="cameras"
FIELD_NAME="stream_url"
IMAGE_DIR="images"
LOG_FILE="logs/capture.log" # Log file within the 'logs' directory
TIMEOUT_DURATION=5 # Timeout duration in seconds

# Ensure IMAGE_DIR and LOG_FILE directories exist
mkdir -p "$IMAGE_DIR"
mkdir -p "$(dirname "$LOG_FILE")" # Ensure the directory for LOG_FILE exists

# Function to check MySQL connection
check_mysql_connection() {
    mysqladmin ping -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent > /dev/null
}

# Function to fetch all RTSP URLs from MySQL
get_rtsp_urls() {
    local urls
    urls=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -D "$DATABASE_NAME" -se "SELECT $FIELD_NAME FROM $TABLE_NAME;")
    echo "$urls"
}

# Function to capture images from RTSP URLs
capture_images() {
    # Check database connection
    if check_mysql_connection; then
        echo "$(date) - Database connection successful" >> "$LOG_FILE"
    else
        echo "$(date) - Database connection failed" >> "$LOG_FILE"
        exit 1
    fi

    # Fetch all RTSP URLs
    RTSP_URLS=$(get_rtsp_urls)
    
    if [ -z "$RTSP_URLS" ]; then
        echo "$(date) - No RTSP URLs found in the database" >> "$LOG_FILE"
        return
    fi

    # Convert RTSP_URLS into an array
    IFS=$'\n' read -d '' -r -a URL_ARRAY <<< "$RTSP_URLS"
    
    # Loop through each RTSP URL and capture image
    for RTSP_URL in "${URL_ARRAY[@]}"; do
        # Trim leading and trailing whitespace from the RTSP URL
        RTSP_URL=$(echo "$RTSP_URL" | awk '{$1=$1;print}')
        
        # Log fetched RTSP URL
        echo "$(date) - RTSP URL fetched successfully: $RTSP_URL" >> "$LOG_FILE"
        
        # Ensure the URL is properly quoted to handle any special characters or spaces
        TIMESTAMP=$(date +"%Y_%m_%d_%H_%M_%S")
        IMAGE_FILE="$IMAGE_DIR/capture_${TIMESTAMP}_$(echo "$RTSP_URL" | md5sum | awk '{print $1}').jpg"
        
        # Run ffmpeg command with a timeout of 5 seconds and check its completion
        echo "$(date) - Starting capture from $RTSP_URL" >> "$LOG_FILE"
        if timeout "$TIMEOUT_DURATION" ffmpeg -rtsp_transport tcp -i "$RTSP_URL" -frames:v 1 "$IMAGE_FILE" > /dev/null 2>&1; then
            echo "$(date) - Captured image saved to $IMAGE_FILE" >> "$LOG_FILE"
        else
            echo "$(date) - Failed to capture image from $RTSP_URL" >> "$LOG_FILE"
        fi

        # Optional: Wait for a short period before proceeding to the next URL
        sleep 1
    done
}

# Execute the image capture function
capture_images

