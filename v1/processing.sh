#!/bin/bash
# Init Arguments
str_folder_name="$1"
str_file_name="$2"
timestamp=`date "+%Y_%m_%d_%H_%M_%S"`
log="log_$timestamp"

#Check validity
if [ -d "$str_folder_name" ] && [ -f  "$str_folder_name/$str_file_name" ] ; then
	cd "$str_folder_name"
	if [ -f "SG_DOWNLOAD_DONE" ]; then
		tar xvzf "$str_file_name" >> $log
		
		tar_exit_code=$?
		if [ "$tar_exit_code" == "0" ]; then
			echo "" > "SG_UNPACKING_DONE"
			echo "Unpacking finished successfully" >> $log
			rm $str_file_name
		else
			echo "Tar exit code: $tar_exit_code" >> $log		
			exit 3
		fi
	else
		echo "Download-File not found. This message should never appear"
		exit 2
	fi
	if [ -f "SG_UNPACKING_DONE" ]; then
		for d in */ ; do
			java -cp ../com.semangit.jar MainClass "$d"
		done
		echo "" > "SG_PROCESSING_DONE"
	fi
else 
	echo "Faulty Parameters set."
	exit 1
fi


