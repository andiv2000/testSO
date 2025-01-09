#!/bin/bash

DEBUG=true

log_debug() {
    if $DEBUG; then
        echo "[DEBUG] $1" >&2
    fi
}

# Functie cu ajutorul careia se valideaza imput-ul datei din calendar
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

#Folosim functia de mai jos pentru a a determina data de modificare a fisierului
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

# Functia pentru a gasi fisierele in functie de durata
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

# Function prin care mutam fisierele in cloud
move_to_cloud() {
    read -p "Enter the files to upload (separated by space): " files
    read -p "Enter the Git repository URL: " repo_url
    local temp_dir
    temp_dir=$(mktemp -d)

    log_debug "Cloning repository: $repo_url into $temp_dir"
    git clone "$repo_url" "$temp_dir" || {
        echo "Failed to clone repository." >&2
        return
    }

    log_debug "Copying files to $temp_dir"
    cp $files "$temp_dir" || {
        echo "Failed to copy files to the repository directory." >&2
        return
    }

    (cd "$temp_dir" && git add . && git commit -m "Add backup files" && git push) || {
        echo "Failed to push files to the repository." >&2
        return
    }

    rm -rf "$temp_dir"
    echo "Files uploaded to cloud successfully!"
}


#Functia cu ajutorul careia 
schedule_deletion() {
    read -p "Enter the path for periodic deletion: " path
    echo "Choose deletion schedule:"
    echo "1. Weekly on Monday at 20:00"
    echo "2. Custom"
    read -p "Enter your choice (1 or 2): " schedule_type

    if [[ "$schedule_type" == "1" ]]; then
        (crontab -l 2>/dev/null; echo "0 20 * * 1 find $path -type f -exec rm {} \;") | crontab -
        echo "Scheduled weekly deletion on Monday at 20:00 successfully!"
    elif [[ "$schedule_type" == "2" ]]; then
        read -p "Enter cron schedule (e.g., 0 20 * * 1): " cron_time
        if [[ -n "$cron_time" ]]; then
            (crontab -l 2>/dev/null; echo "$cron_time find $path -type f -exec rm {} \;") | crontab -
            echo "Custom schedule set successfully!"
        else
            echo "Invalid cron schedule entered." >&2
        fi
    else
        echo "Invalid option." >&2
    fi
}

# Function to delete files
delete_files() {
    read -p "Enter the directory to delete files from: " directory
    read -p "Enter file pattern to delete (e.g., *.tmp): " pattern

    if [[ -d $directory ]]; then
        log_debug "Deleting files matching $pattern in $directory"
        find "$directory" -type f -name "$pattern" -exec rm {} \;
        echo "Files deleted successfully!"
    else
        echo "Invalid directory: $directory" >&2
    fi
}

# Function to rename files
rename_files() {
    read -p "Enter the directory to rename files in: " directory
    read -p "Enter file pattern to rename (e.g., *.log): " pattern
    read -p "Enter the suffix to add (e.g., .old): " suffix

    if [[ -d $directory ]]; then
        log_debug "Renaming files matching $pattern in $directory by adding suffix $suffix"
        for file in "$directory"/$pattern; do
            mv "$file" "${file}${suffix}"
        done
        echo "Files renamed successfully!"
    else
        echo "Invalid directory: $directory" >&2
    fi
}

# Function to edit file content
edit_file_content() {
    read -p "Enter the directory to edit files in: " directory
    read -p "Enter file pattern to edit (e.g., *.txt): " pattern
    read -p "Enter the line to append to each file: " line

    if [[ -d $directory ]]; then
        log_debug "Editing files matching $pattern in $directory by appending line: $line"
        for file in "$directory"/$pattern; do
            echo "$line" >> "$file"
        done
        echo "Content added to files successfully!"
    else
        echo "Invalid directory: $directory" >&2
    fi
}

# Function to modify file permissions
modify_file_permissions() {
    read -p "Enter the file to modify permissions for: " file
    read -p "Enter the new permissions (e.g., 644): " permissions

    if [[ -f $file ]]; then
        chmod $permissions "$file" && echo "Permissions for $file changed to $permissions" || {
            echo "Failed to change permissions for $file." >&2
        }
    else
        echo "Invalid file: $file" >&2
    fi
}

# Function to modify folder permissions
modify_folder_permissions() {
    read -p "Enter the folder to modify permissions for: " folder
    read -p "Enter the new permissions (e.g., 755): " permissions

    if [[ -d $folder ]]; then
        chmod -R $permissions "$folder" && echo "Permissions for $folder changed to $permissions" || {
            echo "Failed to change permissions for $folder." >&2
        }
    else
        echo "Invalid folder: $folder" >&2
    fi
}

# Configuration menu
configuration_menu() {
    while true; do
        echo "Configuration Menu"
        echo "1. Delete files"
        echo "2. Rename files"
        echo "3. Edit file content"
        echo "4. Back to main menu"
        read -p "Choose an option: " config_choice

        case $config_choice in
            1)
                delete_files
                ;;
            2)
                rename_files
                ;;
            3)
                edit_file_content
                ;;
            4)
                break
                ;;
            *)
                echo "Invalid option. Try again." >&2
                ;;
        esac
    done
}

# Main menu
main_menu() {
    while true; do
        echo "Backup Advanced - Main Menu"
        echo "1. Find files older than a date or duration"
        echo "2. Move files locally"
        echo "3. Move files to cloud"
        echo "4. Schedule periodic deletion"
        echo "5. Configuration options"
        echo "6. Modify file permissions"
        echo "7. Modify folder permissions"
        echo "8. Exit"
        read -p "Choose an option: " choice

        case $choice in
            1)
                read -p "Enter a date (YYYY-MM-DD) or a duration (e.g., 10 zile, 3 luni): " input
                read -p "Enter the directory to search: " directory
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
                    echo "Invalid input. Please try again." >&2
                fi
                ;;
            2)
                read -p "Enter the files to move (separated by space): " files
                read -p "Enter the destination directory: " destination
                mv $files "$destination" || {
                    echo "Failed to move files." >&2
                }
                echo "Files moved successfully!"
                ;;
            3)
                move_to_cloud
                ;;
            4)
                schedule_deletion
                ;;
            5)
                configuration_menu
                ;;
            6)
                modify_file_permissions
                ;;
            7)
                modify_folder_permissions
                ;;
            8)
                exit 0
                ;;
            *)
                echo "Invalid option. Try again." >&2
                ;;
        esac
    done
}

main_menu
