    #!/bin/bash

    # Define file paths
    OUTPUT_FILE="/var/www/html/server_monitoring_report.html"
    NGINX_LOG="/var/log/nginx/access.log"
    WP_UPLOAD_DIR="/var/www/html/aibe/False-Detection-Photos/False-Detection/images"
    MYSQL_DB="aibe"
    MYSQL_USER="root"
    MYSQL_PASS="Raoinfotech@09"
    MYSQL_HOST="localhost"
    TABLE_NAME="cameras"

    # Function to generate timestamp for the last 30 minutes
    get_last_30_minutes() {
        date --date='30 minutes ago' +"%d/%b/%Y:%H:%M:%S"
    }

    # Get Nginx request logs for the last 30 minutes
    last_30_min=$(get_last_30_minutes)
    nginx_logs=$(awk -v date="$last_30_min" '$0 > date' $NGINX_LOG | wc -l)

    # Get memory usage
    memory_usage=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')

    # Get storage used
    storage_used=$(df -h / | awk '/\// {print $3 " / " $2}')

    # Count photos in the WordPress uploads directory
    photo_count=$(find $WP_UPLOAD_DIR -type f -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.gif' | wc -l)

    # Get MySQL database size
    db_size=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -h$MYSQL_HOST -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size (MB)' FROM information_schema.tables WHERE table_schema='$MYSQL_DB';" -s -N)

    # Get MySQL table size
    table_size=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -h$MYSQL_HOST -e "SELECT ROUND((data_length + index_length) / 1024 / 1024, 2) AS 'Table Size (MB)' FROM information_schema.tables WHERE table_schema='$MYSQL_DB' AND table_name='$TABLE_NAME';" -s -N)

    # Create HTML report
    echo "<html>" > $OUTPUT_FILE
    echo "<head><title>Server Monitoring Report</title></head>" >> $OUTPUT_FILE
    echo "<body>" >> $OUTPUT_FILE
    echo "<h1>Server Monitoring Report</h1>" >> $OUTPUT_FILE
    echo "<h2>Nginx Requests in the Last 30 Minutes</h2>" >> $OUTPUT_FILE
    echo "<p>$nginx_logs requests</p>" >> $OUTPUT_FILE
    echo "<h2>Memory Usage</h2>" >> $OUTPUT_FILE
    echo "<p>$memory_usage</p>" >> $OUTPUT_FILE
    echo "<h2>Storage Used</h2>" >> $OUTPUT_FILE
    echo "<p>$storage_used</p>" >> $OUTPUT_FILE
    echo "<h2>WordPress Upload Photos Count</h2>" >> $OUTPUT_FILE
    echo "<p>$photo_count photos</p>" >> $OUTPUT_FILE
    echo "<h2>MySQL Database Size</h2>" >> $OUTPUT_FILE
    echo "<p>$db_size MB</p>" >> $OUTPUT_FILE
    echo "<h2>MySQL Table Size ($TABLE_NAME)</h2>" >> $OUTPUT_FILE
    echo "<p>$table_size MB</p>" >> $OUTPUT_FILE
    echo "</body>" >> $OUTPUT_FILE
    echo "</html>" >> $OUTPUT_FILE

    # Set permissions
    chmod 644 $OUTPUT_FILE
