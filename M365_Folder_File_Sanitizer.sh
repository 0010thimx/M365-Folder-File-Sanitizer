#!/bin/bash
DATE=$(date +%Y-%m-%d_%H:%M)
LOGFILE="./logs/"$DATE"_M365_Rename_Log.txt"
PROGRESS=0

sanitizeName() {
    local name="$1"
    local newName="$name"

    while true; do
        local oldName="$newName"
        
        newName=$(echo "$newName" | sed -e 's/[\\/:*?"<>|#%]/_/g' -e 's/[[:space:]]\{2,\}/ /g' -e 's/[[:space:].]*$//g'  -e 's/ \{1,\}\././g' -e 's/\.\{2,\}/./g')

        if [[ "$newName" == "$oldName" ]]; then
            break
        fi
    done

    echo "$newName"
}


checkPathLength() {
    local path="$1"
    local max_path_length=400
    if [[ ${#path} -gt $max_path_length ]]; then
        echo "WARNUNG: Pfad zu lang ($path)" >> "$LOGFILE"
    fi
}

checkFileNameLength() {
    local filename="$1"
    local max_filename_length=250
    if [[ ${#filename} -gt $max_filename_length ]]; then
        echo "WARNUNG: Dateiname zu lang ($filename)" >> "$LOGFILE"
    fi
}


updateProgress() {
    local current="$1"
    local total="$2"
    local percent=$(( 100 * current / total ))
    echo -ne "Fortschritt: $percent% ($current von $total)\r"
}


processDirectory() {
    local dir="$1"
    

    local total_items=$(find "$dir" -depth | wc -l)
    local current_item=0
    
    find "$dir" -depth | while read -r path; do
        current_item=$((current_item + 1))
        updateProgress "$current_item" "$total_items"

       
        dirPath=$(dirname "$path")
        baseName=$(basename "$path")

        
        newBaseName=$(sanitizeName "$baseName")
        
    
        if [[ "$baseName" != "$newBaseName" ]]; then
            if [[ ! -e "$dirPath/$newBaseName" ]]; then
                if [ -d "$path" ]; then
                    mv -v "$path" "$dirPath/$newBaseName" >> "$LOGFILE" 2>&1 || echo "Fehler beim Umbenennen von $path" >> "$LOGFILE"
                fi

                if [ -f "$path" ]; then
                   mv -v "$path" "$dirPath/$newBaseName" >> "$LOGFILE" 2>&1 || echo "Fehler beim Umbenennen von $path" >> "$LOGFILE"
                fi
            else
                echo "WARNUNG: $dirPath/$newBaseName existiert bereits. Umbenennung übersprungen." >> "$LOGFILE"
            fi
        fi

        checkPathLength "$dirPath/$newBaseName"
        checkFileNameLength "$newBaseName"
    done
    
    echo -e "\n Verarbeitung abgeschlossen. Details siehe $LOGFILE"
}

if [[ $# -ne 1 ]]; then
    echo "Verwendung: $0 <Ordner>"
    exit 1
fi

echo "Log-Datei für Umbenennungen und Warnungen" > "$LOGFILE"

processDirectory "$1"
