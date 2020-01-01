#!/bin/bash
# ARGUMENTS: FULL PATH TO ROOT DIRECTORY WITHOUT SLASH AT THE END
flatten_directory() {
    local current_root=$1
    # loop through things in current root
    local things=($current_root/*)
    for thing in "${things[@]}"; do
        # if thing is a directory
        if [[ -d "$thing" ]]; then
            # clean directory name if needed
            local directory_name=$(echo "${thing// /-}" | tr '[:upper:]' '[:lower:]')
            if [[ "$thing" != "$directory_name" ]]; then
                mv -T "$thing" "$directory_name"
            fi
            # if directory is not empty
            # apply the function to the directory (recursion)
            if [[ -n $(ls -A "$directory_name") ]]; then
                flatten_directory "$directory_name"
            fi
        # if thing is a file
        elif [[ ! -d "$thing" ]]; then
            # clean file name
            local filename=$(basename "${thing// /-}" | tr '[:upper:]' '[:lower:]')
            # take $global_root from the scope of the clean_directory function
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
    local empty_directories=($(ls -A $(find $global_root -empty -type d)))
    echo "${#empty_directories[@]}"
    while [[ "${#empty_directories[@]}" != "1" ]]; do
        find $global_root -empty -type d -exec rm --dir '{}' +
    done
}
remove_exact_duplicates() {
    local things=($global_root/*)
    # loop over files and remove if the same md5sum as before
    declare -A count_table
    for thing in "${things[@]}"; do
        local checksum=($(md5sum $thing))
        # for first pass count is 1 (false), for next passes 2+ (true)
        if ((count_table[$checksum[0]]++)); then
            rm "$thing"
        fi
    done
    # remove name-conflict tags
    for thing in "${things[@]}"; do
        if [[ "$thing" =~ "£" ]]; then
            mv -T "$thing" "${thing//£}"
        fi
    done
}
organize_files() {
    local files=($global_root/*)
    for file in "${files[@]}"; do
        local modification_time=($(stat --format=%y "$file"))
        local date=($(echo "${modification_time[0]//-/ }"))
        local year=$(echo $date)
        local filename=$(basename $file)
        local extension="${filename##*.}"
        local filepath="$global_root/$extension/$year/$filename"
        mkdir --parents `dirname "$filepath"`
        mv -T "$file" "$filepath"
    done
}
# main function
clean_directory() {
    local input=$1
    # clean global root directory names
    global_root=$(echo "${input// /-}" | tr '[:upper:]' '[:lower:]')
    if [[ "$input" != "$global_root" ]]; then
        mv -T "$input" "$global_root"
    fi  
    echo "Moving files to input directory..."
    flatten_directory "$global_root"
    echo -e "Files moved to input directory\n"
    echo "Removing empty directories..."
    remove_empty_directories "$global_root"
    echo -e "Empty directories removed\n"
    echo "Removing exact duplicates..."
    remove_exact_duplicates "$global_root"
    echo -e "Exact duplicates removed\n"
    echo "Organizing files by extension and last modification year..."
    organize_files "$global_root"
    echo -e "Files organized by extension and last modification year\n"
    echo "Done"
}
# run program
clean_directory "$1"