#!/usr/bin/bash

function backup {

    if [ ! -d "/home/$1" ]; then
        echo "Requested $1 user home directory doesn't exist!"
        exit 1
    fi
    
    user=$1
    input=/home/$user
    output=/tmp/${user}_home_$(date +%d-%m-%Y_%H%M%S).tar.gz

    function total_files {
        find $1 -type f
    }

    function total_directories {
        find $1 -type d
    }

    function total_archived_files {
        tar -tzf $1 | grep -v /$
    }

    function total_archived_directories {
        tar -tzf $1 | grep /$ 
    }

    tar -czf $output $input 2> /tmp/errorLog.txt

    src_files=$( total_files $input | wc -l )
    src_directories=$( total_directories $input | wc -l )

    arch_files=$( total_archived_files $output | wc -l )
    arch_directories=$( total_archived_directories $output | wc -l )

    echo -e "\n########## $user ##########\n"
    echo "Files to be included: $src_files"
    echo "Directories to be included: $src_directories"
    echo "Files to be archived: $arch_files"
    echo -e "Directories to be archived: $arch_directories\n"

    if [ $src_files -eq $arch_files ]; then
        echo -e "Backup of $input complete!\n"
        echo "Details about the backup file are:"
        ls -l $output
    else

        output_file=/tmp/${user}_files.txt
        output_dir=/tmp/${user}_dir.txt
        output_arch_file=/tmp/${user}_arch_files.txt
        output_arch_dir=/tmp/${user}_arch_dir.txt
        
        total_files $input > $output_file

        total_directories $input > $output_dir

        total_archived_files $output | sed 's/^/\//' > $output_arch_file

        total_archived_directories $output | sed 's/^/\//' > $output_arch_dir


        diff_files=$(( $src_files - $arch_files ))
        diff_dir=$(( $src_directories - $arch_directories ))
        
        if [ $diff_files -lt 0 ]; then
            echo -e "########## ERROR ##########\n"
            echo "There are ${diff_files#-} files that were archived which were not seen in ${user}'s home directory!"

            echo "The following additional files have been included in the archive:" | tee -a /tmp/errorLog.txt
            grep -vxFf $output_file $output_arch_file | tee -a /tmp/errorLog.txt
            echo
            ls -l $output
            ls -l /tmp/errorLog.txt

        elif [ $diff_files -gt 0 ]; then
            echo -e "########## ERROR ##########\n"
            echo "There are $diff_files files that were not archived successfully!"

            echo "The following files were not archived:" | tee -a /tmp/errorLog.txt
            grep -xvFf $output_arch_file $output_file | tee -a /tmp/errorLog.txt
            echo
            ls -l $output
            ls -l /tmp/errorLog.txt

        elif [ $diff_dir -lt 0 ]; then
            echo -e "########## ERROR ##########\n"
            echo "There were ${diff_dir#-} directories that were archived which were not seen in ${user}'s home directory!"

            echo "The following additional directories have been included in the archive:" | tee -a /tmp/errorLog.txt
            grep -xvFf $output_file $output_arch_file | tee -a /tmp/errorLog.txt
            echo
            ls -l $output
            ls -l /tmp/errorLog.txt
            
        elif [ $diff_dir -gt 0 ]; then
            echo -e "########## ERROR ##########\n"
            echo "There were $diff_dir directories that were not archived successfully!"

            echo "The following directories were not archived:" | tee -a /tmp/errorLog.txt
            grep -xvFf $output_file $output_file | tee -a /tmp/errorLog.txt
            echo
            ls -l $output
            ls -l /tmp/errorLog.txt

        fi
    fi
}

if [ -z $1 ]; then
    directory=$(whoami)
    backup $directory
    let all=$all+$arch_files+$arch_directories
    echo -e "\nTOTAL FILES AND DIRECTORIES: $all\n"
    rm /tmp/${directory}*.txt
else
    for directory in $*; do
        backup $directory
        let all=$all+$arch_files+$arch_directories
        rm /tmp/${directory}*.txt
    done;
        echo -e "\nTOTAL FILES AND DIRECTORIES: $all\n"
        
fi
