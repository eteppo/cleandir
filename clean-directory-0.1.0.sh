#!/bin/bash
# ARGUMENTS: FULL PATH TO ROOT DIRECTORY WITHOUT SLASH AT THE END
flatten_directory() {
    local things=($1/*)
    local root=$1
    for thing in "${things[@]}"; do
        if [[ -d "$thing" ]]; then
        	# fix directory name
        	local directory_name=`echo "${thing// /-}" | tr '[:upper:]' '[:lower:]'`
        	echo "DEBUG ----- $directory_name -----"
        	mkdir --parents "$directory_name"
        	mv "$thing" "$directory_name"
            # apply function to non-empty directory (recursion)
            if [[ -n $(ls -A "$directory_name") ]]; then
                flatten_directory "$directory_name"
            fi
        elif [[ -f "$thing" ]]; then
            # make target file name
            local target_filename=`basename "${thing// /-}" | tr '[:upper:]' '[:lower:]'`
            # make target file path
            local target_path="$root/$target_filename"
            # move file to target file path
            if [[ ! -f "$target_path" ]]; then
                mv "$thing" "$target_path"
            elif [[ -f "$target_path" ]]; then
                # if target file exists, add name conflict tag to name
                mv "$thing" "${target_path}£"
            fi
        fi
    done
}
remove_empty_directories() {
	find $1 -empty -type d -exec rm --dir '{}' +
}
remove_exact_duplicates() {
    local things=($1/*)
    # loop over files and remove if the same md5sum as before
    declare -A count_table
    for thing in "${things[@]}"; do
        if [[ -f "$thing" ]]; then
            local checksum=($(md5sum $thing))
            # for first pass count is 1 (false), for next passes 2+ (true)
            if ((count_table[$checksum[0]]++)); then
                rm "$thing"
            fi
        fi
    done
    # remove name-conflict tags
    for thing in "${things[@]}"; do
        if [[ "$thing" =~ "£" ]]; then
            mv "$thing" "${thing//£}"
        fi
    done
}
organize_files() {
    local files=($1/*)
    for file in "${files[@]}"; do
        local modification_time=($(stat --format=%y "$file"))
        local date=($(echo "${modification_time[0]//-/ }"))
        local year=`echo $date`
        local filename=$(basename $file)
        local extension="${filename##*.}"
        local target_path="$1/$extension/$year/$filename"
        mkdir --parents `dirname "$target_path"`
        mv "$file" "$target_path"
    done
}
# main function
clean_directory() {
    local root=$1
    echo "Moving files to input directory..."
    flatten_directory "$root"
    echo -e "Files moved to input directory\n"

    echo "Removing empty directories..."
    remove_empty_directories "$root"
    echo -e "Empty directories removed\n"

    echo "Removing exact duplicates..."
    remove_exact_duplicates "$root"
    echo -e "Exact duplicates removed\n"

    echo "Organizing files by extension and last modification year..."
    organize_files "$root"
    echo -e "Files organized by extension and last modification year\n"

    echo "Done"
}
# run program
clean_directory "$1"