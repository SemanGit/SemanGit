#!/bin/bash
# Init Arguments
str_folder_name="$1"
str_file_name="$2"
timestamp=`date "+%Y_%m_%d_%H_%M_%S"`
log="log_$timestamp"

#Check validity
if [ -d "$str_folder_name" ] ; then
	cd "$str_folder_name"
	if [ -f "SG_PROCESSING_DONE" ]; then
		exit 0
	fi
	if [ -f "SG_DOWNLOAD_DONE" ] && [ ! -f "SG_UNPACKING_DONE" ]; then
		timestamp=`date "+%Y_%m_%d_%H_%M_%S"`
		echo "$timestamp --- Starting Extraction" >> $log
		tar -I pigz -xvf "$str_file_name" >> $log
		tar_exit_code=$?
		if [ "$tar_exit_code" == "0" ]; then
			echo "" > "SG_UNPACKING_DONE"
			timestamp=`date "+%Y_%m_%d_%H_%M_%S"`
			echo "$timestamp --- Unpacking finished successfully" >> $log
			rm $str_file_name
		else
			timestamp=`date "+%Y_%m_%d_%H_%M_%S"`		
			echo "$timestamp --- Tar exit code: $tar_exit_code" >> $log
			exit 3
		fi
	elif [ ! -f "SG_UNPACKING_DONE" ]; then
		echo "Download-File not found. This message should never appear"
		exit 2
	fi
	if [ -f "SG_UNPACKING_DONE" ] ; then
		timestamp=`date "+%Y_%m_%d_%H_%M_%S"`
		echo "$timestamp --- Starting Conversion" >> $log
		for d in */ ; do
			java -cp ../com.semangit_main.jar MainClass "$d" >> $log 2>&1 ; java_exit_code=$?
		done
		if [ "$java_exit_code" == "0" ]; then 
			timestamp=`date "+%Y_%m_%d_%H_%M_%S"`		
			echo "$timestamp --- Translation sucseeded. Removing .csv and unused .ttl ." >> $log
			rm **/* >/dev/null 2>&1
			echo "" > "SG_PROCESSING_DONE"
		elif [ "$java_exit_code" == "2" ]; then
			timestamp=`date "+%Y_%m_%d_%H_%M_%S"`		
			echo "$timestamp --- Translation sucseeded partially, as some input lines are corrupted. Removing .ttl" >> $log
			echo "" > "SG_PROCESSING_DONE"
		else
			timestamp=`date "+%Y_%m_%d_%H_%M_%S"`		
			echo "$timestamp --- Translation did not sucseed. Check for Java Errors" >> $log
			exit 4
		fi
	fi
else 
	echo "Faulty Parameters set."
	exit 1
fi


