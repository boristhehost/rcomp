#!/bin/bash



extract_baseFileName(){
    echo $(basename -- "$1")
}

extract_extension(){
    local fname=$(extract_baseFileName $1)
    extension="${fname##*.}"
    echo $extension
}

extract_filename_without_extension(){
    local fname=$(extract_baseFileName $1)
    fname_w_e="${fname%.*}"
    echo $fname_w_e


}



added_zipped_files(){

    local n1=$1
    local n2=$2
    shift 2
    local arr=("$@")


    old=()
    new=()
    i=0
     for ele in "${arr[@]}"; do
        # echo "ele: $ele"
        if [[ i -ge $n1 ]]; then
            new+=($ele)
        else
            old+=($ele)
        fi
        ((i++))
    done




    # echo "old: ${old[@]}"
    # echo "new: ${new[@]}"

    new_Elements_Added=()

    for second in "${new[@]}"; do
        f=0
        for first in "${old[@]}"; do
            # echo "second: $second"
            # echo "first: $first"
            if [[ $(extract_baseFileName $first) == $(extract_baseFileName $second) ]]; then
                f=1
                break
            fi
        done

        if [[ $f -eq 0 ]]; then
            new_Elements_Added+=($second)
        fi
    done

    echo "${new_Elements_Added[@]}"

}



FILES_TO_ARCHIVE=$1
ARCHIVE_NAME="archive.zip"
REMOTE_DEST=$2

DOWNLOAD_FLAG="-d"
ALTERNATE_DOWNLOAD_FLAG="--download"
EXTRACT_FLAG="-e"
ALTERNATE_EXTRACT_FLAG="--extract"
ARCHIVE_NAME_FLAG="-n"
ALTERNATE_ARCHIVE_NAME_FLAG="--name"
PASS_ARGUMENT_FLAG="--passargs"

OTHER_ARGUMENTS_TO_BE_ADDED=""
passargs=""

isDownload=0
isExtract=0

echo "files to be uploaded: $FILES_TO_ARCHIVE"
echo "remote destination $REMOTE_DEST"

for arg in "$@"; do
    case $arg in
        "$DOWNLOAD_FLAG"|"$ALTERNATE_DOWNLOAD_FLAG")
            isDownload=1
            echo "download flag detected"
        ;;
        "$EXTRACT_FLAG"|$ALTERNATE_EXTRACT_FLAG)
            isExtract=1
            echo "extract flag detected"
        ;;
        $ARCHIVE_NAME_FLAG=*|$ALTERNATE_ARCHIVE_NAME_FLAG=*)
            echo "archive name flag detected"
            echo "arch arg: $arg"
            name=""
            if [[ $arg == $ARCHIVE_NAME_FLAG=* ]]; then
                name="${arg#$ARCHIVE_NAME_FLAG=}"
            else
                name="${arg#$ALTERNATE_ARCHIVE_NAME_FLAG=}"
            fi
            echo "name of archive: $name"
            # removing double quotes
#             trimmed_name=$(echo "$name" | sed -e 's/^"//' -e 's/"$//')

#             ARCHIVE_NAME="$trimmed_name.zip"
            ARCHIVE_NAME="$name.zip"

            echo "updated archive name: $trimmed_name"
        ;;
        $PASS_ARGUMENT_FLAG=*)
            echo "passargs flag detected"
            echo "arg got: $arg"
            passargs="${arg#$PASS_ARGUMENT_FLAG=}"
            passrgs=$(echo "$passargs" | sed -e 's/^"//' -e 's/"$//')

        ;;
        *)
            if [[ $arg != $1 && $arg != $2 ]]; then
                echo "other argument $arg"
                OTHER_ARGUMENTS_TO_BE_ADDED="$OTHER_ARGUMENTS_TO_BE_ADDED $arg"
            fi
        ;;
    esac


done

if [[ $isDownload == 1 ]] ; then
    REMOTE_DEST=$1
    LOCAL_DEST=$2
    if [[ $isExtract == 1 ]]  &&  [[ ! -d $LOCAL_DEST  ]] ; then

        echo "need a directory to extract files"
    else
         echo "download ya"
         local_dest_old_files=( $(ls $LOCAL_DEST/*.z*) )
         echo "downloading"

#          touch test.txt fgt.txt
#          zip  -r $ARCHIVE_NAME test.txt fgt.txt
#          rm test.txt fgt.txt

         # touch qwe.zip
         # touch qwe2.zip


#         echo "downloaded"
        if [[ $isExtract == 1 ]]; then
            if [[ -f $REMOTE_DEST ]]; then
                fname_w_e=$(extract_filename_without_extension $REMOTE_DEST)
                ext=$(extract_extension $REMOTE_DEST)
                if [[ ext=="zip" ]]; then
                    all_archives=$( $( rclone  ls $(dirname $REMOTE_DEST)/$fname_w_e.z* ) )
#                     rclone copy $(dirname $REMOTE_DEST)/$fname_w_e.z* $LOCAL_DEST $OTHER_ARGUMENTS_TO_BE_ADDED
                    for ele in ${all_archives[@]}; do
                        echo "ele d: $ele"
                        rclone copy $ele $LOCAL_DEST $OTHER_ARGUMENTS_TO_BE_ADDED
                    done

                else

                    rclone copy $REMOTE_DEST $LOCAL_DEST $OTHER_ARGUMENTS_TO_BE_ADDED
                fi
            else
                echo "remote is a directory"
                rclone copy $REMOTE_DEST $LOCAL_DEST $OTHER_ARGUMENTS_TO_BE_ADDED
            fi
            local_dest_new_files=( $(ls $LOCAL_DEST/*.z*) )
#             (added_zipped_files ${#arr1[@]} ${#arr2[@]} ${arr1[@]} ${arr2[@]})
            newly_added_zip_files=( $(added_zipped_files ${#local_dest_old_files[@]} ${#local_dest_new_files[@]}  ${local_dest_old_files[@]} ${local_dest_new_files[@]}) )
            echo "added: ${newly_added_zip_files[@]}"

            found_zips=()
            for files in ${newly_added_zip_files[@]}; do
                found_zips+=($(echo $files | grep -E "*.zip"))
            done


#             found=$(echo $newly_added_zip_files | grep -E "*.zip")
            echo "found_zips: ${found_zips[@]}"

             for zip in "${found_zips[@]}"; do
#                 output_archive="$( extract_filename_without_extension $zip )-full.zip"

                7z x $zip -o$LOCAL_DEST
                rm $zip
                echo "unzipping done"
            done

#             unzip $fnam -d $LOCAL_DEST

            rm ${newly_added_zip_files[@]}
            # rm qwe.zip
            # rm qwe2.zip
        else
            rclone copy $REMOTE_DEST $LOCAL_DEST $OTHER_ARGUMENTS_TO_BE_ADDED
        fi
    fi






#         rclone copy



else

    # exlcude folder feature have to be added properly
    # todo: pass arguments of zip command in passargs flag like --passargs="-x '*/node_modules/*'"
     echo "passargs: $passargs"
#      echo "zip -r $ARCHIVE_NAME $FILES_TO_ARCHIVE $passargs"
    declare -a "passargs2=($passargs)"
#     passargs=(-x '*/node_modules/*')

#     for ele in "${passargs2[@]}"; do
#         echo "ele: $ele"
# #         echo "$ele"
# #         echo $ele
#     done






     zip -r "$(dirname $FILES_TO_ARCHIVE)/$ARCHIVE_NAME"  $FILES_TO_ARCHIVE "${passargs2[@]}"
#    echo "zip -r "$ARCHIVE_NAME" "$FILES_TO_ARCHIVE" -x '*/node_modules/*'"

     ARCHIVE_NAMES=$( extract_filename_without_extension $ARCHIVE_NAME ).z*
    declare -a archives_full_path=( $(ls $(dirname $FILES_TO_ARCHIVE)/$ARCHIVE_NAMES ) )

#     archive_full_path_pattern=$( dirname $FILES_TO_ARCHIVE )/$ARCHIVE_NAMES

    echo "Zipped now uploading"

    for ele in "${archives_full_path[@]}"; do
         rclone copy   $ele "$REMOTE_DEST" $OTHER_ARGUMENTS_TO_BE_ADDED
    done

#     rclone copy   $archive_full_path_pattern "$REMOTE_DEST" $OTHER_ARGUMENTS_TO_BE_ADDED
    echo ${archives_full_path[@]}
    rm ${archives_full_path[@]}

    echo "Uploading complete"
    echo "uploaded ya"
fi

