#!/bin/bash

DEBUG=true

log_debug() {
    if $DEBUG; then
        echo "[DEBUG] $1" >&2
    fi
}

# Funcția pentru validarea întrării datei din calendar
parse_input() {
    local input="$1"
    log_debug "Se analizează întrarea: $input"
    if [[ $input =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "data"
    elif [[ $input =~ ^([0-9]+)[[:space:]]*(zile|luni|ani|săptămâni)$ ]]; then
        echo "durată"
    else
        echo "invalid"
    fi
}

# Funcția pentru a găsi fișierele mai vechi de o anumită dată
find_files_by_date() {
    local date_input="$1"
    local directory="$2"

    if [[ -d $directory ]]; then
        log_debug "Se caută fișiere mai vechi de $date_input în $directory"
        find "$directory" -type f ! -newermt "$date_input" 2>/dev/null
    else
        echo "Director invalid: $directory" >&2
    fi
}

# Funcția pentru a găsi fișierele mai vechi de o anumită durată
find_files_by_duration() {
    local number="$1"
    local unit="$2"
    local directory="$3"

    if [[ -d $directory ]]; then
        log_debug "Se caută fișiere mai vechi de $number $unit în $directory"
        case $unit in
            zile)
                find "$directory" -type f -mtime +$number 2>/dev/null
                ;;
            săptămâni)
                find "$directory" -type f -mtime +$((number * 7)) 2>/dev/null
                ;;
            luni)
                find "$directory" -type f -mtime +$((number * 30)) 2>/dev/null
                ;;
            ani)
                find "$directory" -type f -mtime +$((number * 365)) 2>/dev/null
                ;;
            *)
                echo "Unitate de timp necunoscută." >&2
                ;;
        esac
    else
        echo "Director invalid: $directory" >&2
    fi
}

# Funcția pentru a muta fișierele în cloud
# Funcția pentru a muta fișierele sau directoarele în cloud
move_to_cloud() {
    read -p "Introduceți fișierul sau directorul de încărcat: " item
    read -p "Introduceți URL-ul repository-ului Git: " repo_url
    local temp_dir
    temp_dir=$(mktemp -d)

    log_debug "Clonarea repository-ului: $repo_url în $temp_dir"
    git clone "$repo_url" "$temp_dir" || {
        echo "Clonarea repository-ului a eșuat." >&2
        return
    }

    if [[ -f $item ]]; then
        log_debug "Copierea fișierului $item în $temp_dir"
        cp "$item" "$temp_dir" || {
            echo "Copierea fișierului a eșuat." >&2
            return
        }
    elif [[ -d $item ]]; then
        log_debug "Copierea directorului $item în $temp_dir"
        cp -r "$item" "$temp_dir" || {
            echo "Copierea directorului a eșuat." >&2
            return
        }
    else
        echo "Fișierul sau directorul specificat nu există." >&2
        return
    fi

    log_debug "Commit și push în repository-ul Git"
    (
        cd "$temp_dir" || exit
        git add .
        git commit -m "Adăugare backup: $(basename "$item")"
        git push
    ) || {
        echo "Încărcarea în repository-ul Git a eșuat." >&2
        return
    }

    rm -rf "$temp_dir"
    echo "Fișierul sau directorul a fost încărcat cu succes în cloud!"
}


# Funcția pentru a programa ștergerea periodică
schedule_deletion() {
    read -p "Introduceți calea pentru ștergerea periodică: " path
    echo "Alegeți programul pentru ștergere:" 
    echo "1. Săptămânal, luni la ora 20:00"
    echo "2. Personalizat"
    read -p "Introduceți alegerea (1 sau 2): " schedule_type

    if [[ "$schedule_type" == "1" ]]; then
        (crontab -l 2>/dev/null; echo "0 20 * * 1 find $path -type f -exec rm {} \;") | crontab -
        echo "Ștergere săptămânală programată cu succes pentru luni la ora 20:00!"
    elif [[ "$schedule_type" == "2" ]]; then
        read -p "Introduceți programul cron (ex.: 0 20 * * 1): " cron_time
        if [[ -n "$cron_time" ]]; then
            (crontab -l 2>/dev/null; echo "$cron_time find $path -type f -exec rm {} \;") | crontab -
            echo "Program personalizat setat cu succes!"
        else
            echo "Program cron invalid." >&2
        fi
    else
        echo "Opțiune invalidă." >&2
    fi
}

# Funcția pentru ștergerea fișierelor
delete_files() {
    read -p "Introduceți directorul din care să ștergeți fișiere: " directory
    read -p "Introduceți modelul fișierelor pentru ștergere (ex.: *.tmp): " pattern

    if [[ -d $directory ]]; then
        log_debug "Se șterg fișierele care corespund modelului $pattern din $directory"
        find "$directory" -type f -name "$pattern" -exec rm {} \;
        echo "Fișierele au fost șterse cu succes!"
    else
        echo "Director invalid: $directory" >&2
    fi
}

# Funcția pentru redenumirea fișierelor
rename_files() {
    read -p "Introduceți directorul în care să redenumiți fișiere: " directory
    read -p "Introduceți modelul fișierelor pentru redenumire (ex.: *.log): " pattern
    read -p "Introduceți sufixul de adăugat (ex.: .vechi): " suffix

    if [[ -d $directory ]]; then
        log_debug "Se redenumesc fișierele care corespund modelului $pattern din $directory prin adăugarea sufixului $suffix"
        for file in "$directory"/$pattern; do
            mv "$file" "${file}${suffix}"
        done
        echo "Fișierele au fost redenumite cu succes!"
    else
        echo "Director invalid: $directory" >&2
    fi
}

# Funcția pentru editarea conținutului fișierelor
edit_file_content() {
    read -p "Introduceți directorul în care să editați fișierele: " directory
    read -p "Introduceți modelul fișierelor pentru editare (ex.: *.txt): " pattern
    read -p "Introduceți linia de adăugat în fiecare fișier: " line

    if [[ -d $directory ]]; then
        log_debug "Se editează fișierele care corespund modelului $pattern din $directory prin adăugarea liniei: $line"
        for file in "$directory"/$pattern; do
            echo "$line" >> "$file"
        done
        echo "Conținut adăugat cu succes în fișiere!"
    else
        echo "Director invalid: $directory" >&2
    fi
}

# Funcția pentru modificarea permisiunilor fișierelor
modify_file_permissions() {
    read -p "Introduceți fișierul pentru care să modificați permisiunile: " file
    read -p "Introduceți noile permisiuni (ex.: 644): " permissions

    if [[ -f $file ]]; then
        chmod $permissions "$file" && echo "Permisiunile pentru $file au fost schimbate în $permissions" || {
            echo "Eroare la schimbarea permisiunilor pentru $file." >&2
        }
    else
        echo "Fișier invalid: $file" >&2
    fi
}

# Funcția pentru modificarea permisiunilor folderelor
modify_folder_permissions() {
    read -p "Introduceți folderul pentru care să modificați permisiunile: " folder
    read -p "Introduceți noile permisiuni (ex.: 755): " permissions

    if [[ -d $folder ]]; then
        chmod -R $permissions "$folder" && echo "Permisiunile pentru $folder au fost schimbate în $permissions" || {
            echo "Eroare la schimbarea permisiunilor pentru $folder." >&2
        }
    else
        echo "Folder invalid: $folder" >&2
    fi
}

# Meniul de configurare
configuration_menu() {
    while true; do
        echo "Meniu de Configurare"
        echo "1. Șterge fișiere"
        echo "2. Redenumește fișiere"
        echo "3. Editează conținutul fișierelor"
        echo "4. Înapoi la meniul principal"
        read -p "Alegeți o opțiune: " config_choice

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
                echo "Opțiune invalidă. Încercați din nou." >&2
                ;;
        esac
    done
}

# Meniul principal
main_menu() {
    while true; do
        echo "Backup Avansat - Meniul Principal"
        echo "1. Găsește fișiere mai vechi de o dată sau durată"
        echo "2. Mută fișiere local"
        echo "3. Mută fișiere în cloud"
        echo "4. Programează ștergerea periodică"
        echo "5. Opțiuni de configurare"
        echo "6. Modifică permisiuni fișiere"
        echo "7. Modifică permisiuni foldere"
        echo "8. Ieșire"
        read -p "Alegeți o opțiune: " choice

        case $choice in
            1)
                read -p "Introduceți o dată (YYYY-MM-DD) sau o durată (ex.: 10 zile, 3 luni): " input
                read -p "Introduceți directorul pentru căutare: " directory
                format=$(parse_input "$input")

                if [[ $format == "data" ]]; then
                    log_debug "Se caută fișiere mai vechi de data: $input"
                    find_files_by_date "$input" "$directory"
                elif [[ $format == "durată" ]]; then
                    number=$(echo "$input" | grep -oE '^[0-9]+')
                    unit=$(echo "$input" | grep -oE '(zile|luni|ani|săptămâni)')
                    log_debug "Se caută fișiere mai vechi de durata: $number $unit"
                    find_files_by_duration "$number" "$unit" "$directory"
                else
                    echo "Întrare invalidă. Încercați din nou." >&2
                fi
                ;;
            2)
                read -p "Introduceți fișierele de mutat (separate prin spații): " files
                read -p "Introduceți directorul de destinație: " destination
                mv $files "$destination" || {
                    echo "Eroare la mutarea fișierelor." >&2
                }
                echo "Fișierele au fost mutate cu succes!"
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
                echo "Opțiune invalidă. Încercați din nou." >&2
                ;;
        esac
    done
}

main_menu
