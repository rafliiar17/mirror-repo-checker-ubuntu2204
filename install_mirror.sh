#!/bin/bash

# Define the log file with current date
LOG_DIR="log"
LOG_FILE="${LOG_DIR}/log-update-mirror-$(date +"%Y-%m-%d").txt"

# Create log directory if it does not exist
mkdir -p $LOG_DIR

# Function to get current timestamp
current_time() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Function to log messages with timestamp
log_message() {
    local message="$1"
    echo "$(current_time) -> $message" >> $LOG_FILE
}

# Function to display a loading bar
show_loading_bar() {
    local total=$1
    local current=$2
    local bar_length=50

    # Calculate the number of filled blocks
    filled=$((current * bar_length / total))
    bar=$(printf "%-${bar_length}s" "" | tr ' ' '#')

    # Calculate percentage with two decimal places
    if [ "$total" -gt 0 ]; then
        percentage=$(printf "%.2f" $(echo "scale=4; $current * 100 / $total" | bc))
    else
        percentage="0.00"
    fi

    # Print the progress bar to stderr
    printf "\rProcess Checking Host [${bar:0:$filled}] ${current}/${total} (${percentage}%%)" >&2
}

# Function to handle cleanup on interrupt
cleanup() {
    log_message "Script interrupted. Performing cleanup..."
    # Add any cleanup commands here if needed
    exit 1
}

# Trap SIGINT (Ctrl+C) and call cleanup function
trap cleanup SIGINT

# Start logging
echo "$(current_time) -> Starting update mirror process" | tee -a $LOG_FILE
log_message "Starting update mirror process"

# Create a backup of the current sources list
echo "$(current_time) -> Creating backup of /etc/apt/sources.list" | tee -a $LOG_FILE
log_message "Creating backup of /etc/apt/sources.list"
cp /etc/apt/sources.list /etc/apt/sources.list.backup 2>&1 | tee -a $LOG_FILE

# Remove cached files
echo "$(current_time) -> Removing cached files" | tee -a $LOG_FILE
log_message "Removing cached files"
rm -rf /var/lib/apt/lists/* 2>&1 | tee -a $LOG_FILE

# Check if netselect is already installed
if ! command -v netselect &> /dev/null; then
    # Install netselect if not present
    ARCH=$(dpkg --print-architecture)
    VERSION="0.3.ds1-30.1"
    URL="http://ftp.debian.org/debian/pool/main/n/netselect/netselect_${VERSION}_${ARCH}.deb"

    echo "$(current_time) -> Downloading netselect from $URL" | tee -a $LOG_FILE
    log_message "Downloading netselect from $URL"
    wget -q $URL -O netselect.deb 2>&1 | tee -a $LOG_FILE

    echo "$(current_time) -> Installing netselect" | tee -a $LOG_FILE
    log_message "Installing netselect"
    sudo apt install -y ./netselect.deb 2>&1 | tee -a $LOG_FILE
else
    echo "$(current_time) -> netselect is already installed. Skipping installation." | tee -a $LOG_FILE
    log_message "netselect is already installed. Skipping installation."
fi

# Download the list of mirrors
echo "$(current_time) -> Fetching list of mirrors" | tee -a $LOG_FILE
log_message "Fetching list of mirrors"
wget -q -O- "https://launchpad.net/ubuntu/+archivemirrors" > mirrors.txt 2>&1 | tee -a $LOG_FILE

# Filter and extract available mirrors
echo "$(current_time) -> Filtering mirrors" | tee -a $LOG_FILE
log_message "Filtering mirrors"
grep -P -B8 "statusUP" mirrors.txt | grep -o -P "(f|ht)tp://[^\"]*" > filtered_mirrors.txt 2>&1 | tee -a $LOG_FILE

# Count the number of mirrors to process
total_mirrors=$(wc -l < filtered_mirrors.txt)
valid_mirrors=0
unknown_mirrors=0

# Find the best mirror using curl with a timeout
echo "$(current_time) -> Selecting the best mirror" | tee -a $LOG_FILE
log_message "Selecting the best mirror"
current=0
count=0
while read -r mirror; do
    count=$((count + 1))
    start_time=$(date +%s%3N)

    # Use curl to check the mirror with a 5-second timeout
    result=$(curl -o /dev/null -s -w "%{http_code} %{time_total}\n" --max-time 5 "$mirror")

    end_time=$(date +%s%3N)
    connection_time=$((end_time - start_time))

    # Parse curl result
    http_code=$(echo "$result" | awk '{print $1}')
    time_total=$(echo "$result" | awk '{print $2}')

    # Log result for all hosts
    if [ "$connection_time" -le 5000 ]; then
        if [ "$http_code" -eq 200 ]; then
            log_message "[$count] host [${mirror}] : [valid] : connected on ${connection_time}ms"
            valid_mirrors=$((valid_mirrors + 1))
        else
            log_message "[$count] host [${mirror}] : [invalid] : try in ${connection_time}ms"
            unknown_mirrors=$((unknown_mirrors + 1))
        fi
    else
        log_message "[$count] host [${mirror}] : [too long connecting] : ${connection_time}ms"
    fi

    # Update progress bar
    current=$((current + 1))
    show_loading_bar $total_mirrors $current
done < filtered_mirrors.txt
echo  # Move to the next line after progress bar

# Find the best mirror from valid results
if [ $valid_mirrors -gt 0 ]; then
    best_mirror=$(sudo netselect -s10 -t20 $(cat filtered_mirrors.txt) | head -n1 | awk "{print \$2}" | sed -e "s#^http://##" -e "s#^https://##") 2>&1 | tee -a $LOG_FILE
    echo "$(current_time) -> Best mirror found: ${best_mirror}" | tee -a $LOG_FILE
    log_message "Best mirror found: ${best_mirror}"
else
    echo "$(current_time) -> No valid mirrors found." | tee -a $LOG_FILE
    log_message "No valid mirrors found."
    exit 1
fi

# Update sources.list with the best mirror
echo "$(current_time) -> Updating sources.list with the best mirror: ${best_mirror}" | tee -a $LOG_FILE
log_message "Updating sources.list with the best mirror: ${best_mirror}"
sed -i "s|deb [a-z]*://[^ ]* |deb http://${best_mirror} |g" /etc/apt/sources.list 2>&1 | tee -a $LOG_FILE

# Remove cached files and update package list
rm -rf /var/lib/apt/lists/* 2>&1 | tee -a $LOG_FILE
echo "$(current_time) -> Updating package list" | tee -a $LOG_FILE
log_message "Updating package list"
sudo apt update -y 2>&1 | tee -a $LOG_FILE

echo "$(current_time) -> Update mirror process completed" | tee -a $LOG_FILE
log_message "Update mirror process completed"
