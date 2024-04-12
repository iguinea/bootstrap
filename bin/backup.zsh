#!/bin/zsh

function backup(){
	dir="$1"
	# -----------------------------------------------------------
	# bail out if the directory does not exist.
	# -----------------------------------------------------------
	if [ ! -d $dir ]
	then
	    echo "The directory '$dir' does not exist."
	    echo "Quitting without making a backup."
	    exit
	fi
	
	# -----------------------------------------------------------
	# create a backup filename with the date, time, and dir name.
	# write the backup to my other hard drive, which is mounted
	# at ~/ExternalDrive.
	# note that the filename is unique to the second of the day.
	# -----------------------------------------------------------
	d=`date +"%Y.%m.%d"`            # date format
	t=`date +"%H.%M.%S"`            # time format
	filename=${dir}-${d}-${t}.tgz
	canonFilename=~/Backups/$filename
	
	echo "Creating $canonFilename ..."
	
	# -----------------------------------------------------------
	# make the tar file
	# -----------------------------------------------------------
	tar czvf $canonFilename $dir

}
function kubectl2 (){
	dir="$1"
	# -----------------------------------------------------------
	# bail out if the directory does not exist.
	# -----------------------------------------------------------
	if [ ! -d $dir ]
	then
	    echo "The directory '$dir' does not exist."
	    echo "Quitting without making a backup."
	    exit
	fi
	
	# -----------------------------------------------------------
	# create a backup filename with the date, time, and dir name.
	# write the backup to my other hard drive, which is mounted
	# at ~/ExternalDrive.
	# note that the filename is unique to the second of the day.
	# -----------------------------------------------------------
	d=`date +"%Y.%m.%d"`            # date format
	t=`date +"%H.%M.%S"`            # time format
	filename=${dir}-${d}-${t}.tgz
	canonFilename=~/Backups/$filename
	
	echo "Creating $canonFilename ..."
	
	# -----------------------------------------------------------
	# make the tar file
	# -----------------------------------------------------------
	tar czvf $canonFilename $dir

}
