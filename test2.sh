#!/bin/bash

# Debugging mode default
DEBUG=true

# Log debug messages
log_debug() {
    if $DEBUG; then
        echo "[DEBUG] $1" >&2
    fi
}

# Function to parse and validate input
parse_input() {
    local input="$1"
    log_debug "Parsing input: $input"
    if [[ $input =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "date"
    elif [[ $input =~ ^([0-9]+)[[:space:]]*(zile|luni|ani|saptamani)$ ]]; then
        echo "duration"
    else
        echo "invalid"
    fi
}

# Function to find files by date
find_files_by_date() {
    local date_input="$1"
    local directory="$2"

    if [[ -d $directory ]]; then
        log_debug "Finding files older than $date_input in $directory"
        find "$directory" -type f ! -newermt "$date_input" 2>/dev/null
    else
        echo "Invalid directory: $directory" >&2
    fi
}

# Function to find files by duration
find_files_by_duration() {
    local number="$1"
    local unit="$2"
    local directory="$3"

    if [[ -d $directory ]]; then
        log_debug "Finding files older than $number $unit in $directory"
        case $unit in
            zile)
                find "$directory" -type f -mtime +$number 2>/dev/null
                ;;
            saptamani)
                find "$directory" -type f -mtime +$((number * 7)) 2>/dev/null
                ;;
            luni)
                find "$directory" -type f -mtime +$((number * 30)) 2>/dev/null
                ;;
            ani)
                find "$directory" -type f -mtime +$((number * 365)) 2>/dev/null
                ;;
            *)
                echo "Unknown time unit." >&2
                ;;
        esac
    else
        echo "Invalid directory: $directory" >&2
    fi
}

# Main functionality for terminal
main_terminal() {
    echo "Introduceți o dată (YYYY-MM-DD) sau o durată (ex.: 10 zile, 3 luni):"
    read input
    echo "Introduceți directorul în care doriți să căutați fișierele:"
    read directory

    format=$(parse_input "$input")
    if [[ $format == "date" ]]; then
        log_debug "Searching files older than date: $input"
        find_files_by_date "$input" "$directory"
    elif [[ $format == "duration" ]]; then
        number=$(echo "$input" | grep -oE '^[0-9]+')
        unit=$(echo "$input" | grep -oE '(zile|luni|ani|saptamani)')
        log_debug "Searching files older than duration: $number $unit"
        find_files_by_duration "$number" "$unit" "$directory"
    else
        echo "Input invalid. Reîncercați."
    fi
}

# Start script in terminal mode
main_terminal
