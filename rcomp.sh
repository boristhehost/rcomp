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






    new_Elements_Added=()

    for second in "${new[@]}"; do
        f=0
        for first in "${old[@]}"; do

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

         local_dest_old_files=( $(ls $LOCAL_DEST/*.z*) )
         echo "downloading"









        if [[ $isExtract == 1 ]]; then
            if [[ -f $REMOTE_DEST ]]; then
                fname_w_e=$(extract_filename_without_extension $REMOTE_DEST)
                ext=$(extract_extension $REMOTE_DEST)
                if [[ ext=="zip" ]]; then
                    all_archives=$( $( rclone  ls $(dirname $REMOTE_DEST)/$fname_w_e.z* ) )

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

            newly_added_zip_files=( $(added_zipped_files ${#local_dest_old_files[@]} ${#local_dest_new_files[@]}  ${local_dest_old_files[@]} ${local_dest_new_files[@]}) )
            echo "added: ${newly_added_zip_files[@]}"

            found_zips=()
            for files in ${newly_added_zip_files[@]}; do
                found_zips+=($(echo $files | grep -E "*.zip"))
            done



            echo "found_zips: ${found_zips[@]}"

             for zip in "${found_zips[@]}"; do


                7z x $zip -o$LOCAL_DEST
                rm $zip
                echo "unzipping done"
            done



            rm ${newly_added_zip_files[@]}

        else
            rclone copy $REMOTE_DEST $LOCAL_DEST $OTHER_ARGUMENTS_TO_BE_ADDED
        fi
    fi










else


     echo "passargs: $passargs"

    declare -a "passargs2=($passargs)"







     zip -r "$(dirname $FILES_TO_ARCHIVE)/$ARCHIVE_NAME"  $FILES_TO_ARCHIVE "${passargs2[@]}"


     ARCHIVE_NAMES=$( extract_filename_without_extension $ARCHIVE_NAME ).z*
    declare -a archives_full_path=( $(ls $(dirname $FILES_TO_ARCHIVE)/$ARCHIVE_NAMES ) )



    echo "Zipped now uploading"

    for ele in "${archives_full_path[@]}"; do
         rclone copy   $ele "$REMOTE_DEST" $OTHER_ARGUMENTS_TO_BE_ADDED
    done


    echo ${archives_full_path[@]}
    rm ${archives_full_path[@]}

    echo "Uploading complete"

fi

