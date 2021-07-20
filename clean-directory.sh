#!/bin/bash
set -e

move_all_to_root() {
    local current_root=$1
    # loop through things in current root
    local things=("$current_root"/*)
    for thing in "${things[@]}"; do
        # if thing is a directory
        if [[ -d "$thing" ]]; then
            # clean directory name if needed
            local directory_name
            directory_name=$(echo "${thing// /-}" | tr '[:upper:]' '[:lower:]')
            if [[ "$thing" != "$directory_name" ]]; then
                mv -T "$thing" "$directory_name"
            fi
            # if directory is not empty
            # apply the function to the directory (recursion)
            if [[ -n $(ls -A "$directory_name") ]]; then
                move_all_to_root "$directory_name"
            fi
        # if thing is a file
        elif [[ ! -d "$thing" ]]; then
            # log info
            local counter=$(( counter + 1 ))
            local item_name
            item_name=$( basename "$thing" )
            echo -ne "\r\033[0KFile $counter: $item_name "
            # clean file name
            local filename
            filename=$(basename "${thing// /-}" | tr '[:upper:]' '[:lower:]')
            # take "$global_root" from the scope of the clean_directory function
            local filepath="$global_root/$filename"
            # move file to target file path
            if [[ ! -f "$filepath" ]]; then
                mv -T "$thing" "$filepath"
            elif [[ -f "$filepath" ]]; then
                # if filepath exists already, add name-conflict tag
                mv -T "$thing" "${filepath}£"
            fi
        fi
    done
}

remove_empty_directories() {
    local empty_count
	empty_count=$(find "$global_root" -empty -type d | wc -l)
	while [[ "$empty_count" != "0" ]]; do
		find "$global_root" -empty -type d -exec rm --dir '{}' +
		empty_count=$(find "$global_root" -empty -type d | wc -l)
	done
}

flatten_directory() {
    local global_root=$1
    local counter=0
    move_all_to_root "$global_root"
    remove_empty_directories "$global_root"
}

remove_exact_duplicates() {
    local things=( "$global_root"/* )
    # loop over files and remove if the same md5sum as before
    declare -A count_table
    local counter=0
    for thing in "${things[@]}"; do
        # log info
        local counter=$(( counter + 1 ))
        local item_name
        item_name=$( basename "$thing" )
        echo -ne "\r\033[0KFile $counter: $item_name "
        local checksum
        checksum=$( md5sum "$thing" )
        # for first pass count is 1 (false), for next passes 2+ (true)
        if (( count_table[$checksum[0]]++ )); then
            rm "$thing"
        fi
    done
    # remove name-conflict tags
    local things=("$global_root"/*)
    for thing in "${things[@]}"; do
        if [[ "$thing" =~ "£" ]]; then
            mv -T "$thing" "${thing//£}"
        fi
    done
}

organize_files() {
    local files=( "$global_root"/* )
    local counter=0
    for file in "${files[@]}"; do
        if [[ ! -d "$file" ]]; then
            local counter=$(( counter + 1 ))
            local item_name
            item_name=$(basename "$file")
        	echo -ne "\r\033[0KFile $counter: $item_name "
            local modification_time
            modification_time=( "$( stat --format=%y "$file" )" )
            local date
            date="${modification_time[0]//-/ }"
            local year
            year="$date"
            local filename
            filename=$(basename "$file")
            local extension
            extension="${filename##*.}"
            # use 'unknown' for missing extensions
            if [[ -z "$extension" ]]; then
                extension="unknown"
            fi
            local filepath
            filepath="$global_root/$extension/$year/$filename"
            mkdir --parents "$(dirname "$filepath")"
            mv -T "$file" "$filepath"
        fi
    done
}

clean_directory() {
    local input=$1
    # use lower case paths without spaces
    global_root=$(echo "${input// /-}" | tr '[:upper:]' '[:lower:]')
    if [[ "$input" != "$global_root" ]]; then
    	mkdir --parents "$global_root"
        mv -T "$input" "$global_root"
    fi
    local n_files
    n_files=$(ls --recursive --classify "$global_root" | grep -c \\*)
    printf "Input directory has %s files.\n" "$n_files"
    printf "Flattening directory...\n"
    flatten_directory "$global_root"
    printf "\nDone.\n"
    printf "Removing exact duplicates...\n"
    remove_exact_duplicates "$global_root"
    printf "\nDone.\n"
    printf "Organizing files by file extension and the last modification year...\n"
    organize_files "$global_root"
    printf "\nDone.\n"
    n_files=$(ls --recursive --classify "$global_root" | grep -c \\*)
    printf "Output directory has %s files.\n" "$n_files"
    printf "Output directory: %s\n" "$global_root"
}

input_path=$1
if [[ ! -d "$input_path" ]]; then
    # print to standard error
    echo "Input path is not a directory." >&2; exit 1
fi
printf "Input directory: %s\n" "$input_path"
while true; do
    read -r -p "Are you sure [y|n]? " yn
    case $yn in
        [Yy]* ) clean_directory "$input_path"; break;;
        [Nn]* ) exit 0;;
        * ) echo "Please type 'yes' or 'no' and press enter.";;
    esac
done
