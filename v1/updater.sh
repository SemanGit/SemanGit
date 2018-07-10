#!/bin/bash

# Set option variables
debug=false
help=false
daily=false
debug_folder=""
debug_prefix=""
echo "Starting Script" &
old_process=$!
new_process=$!


# Check options
for option in "$@"
do
	if [ "$option" == "-debug"  ]; then
		debug=true
		debug_prefix="debug_"
	elif [ "$option" == "-h" ] || [ "$option" == "-help" ]; then
		help=true
	elif [ "$option" == "-daily" ]; then
		daily=true
	elif [ 	$( echo "$option" |cut -d '=' -f1 ) == "-debug_folder" ]; then
		debug_folder=$( echo "$option" |cut -d '=' -f2 )
	else 
		echo "Unkown option $option. Help will be automatically printed"
		help=true	
	fi
done

# Print help if option -help -h is chosen
if [ "$help" == true ]; then	
	echo -e  '\n\n-------------------'
	echo 'Options:'
	echo '-------------------'
	echo '-debug: Run in debug mode. Only one folder is evaluated. Script runs only once.'
	echo '-daily: Use the daily mongo dumps'
	echo '-debug_folder=<folder_name>: Use specific folder for debugging. Default values are mongo-dump-2018-01-01 and my-sql-2018-01-01'
	echo -e '-h , -help : Print help file\n'

# Else run script.
else
	while true; do
		timestamp=`date "+%Y_%m_%d_%H_%M_%S"`
		log="log_$timestamp"
		if [ "$debug" == true ]; then
			echo "Running in debug mode!" 
			if [ "$debug_folder" == "" ] && [ "$daily" == true ]; then
				debug_folder="mongo-dump-2018-01-01"
			elif [ "$debug_folder" == "" ]; then
				debug_folder="mysql-2018-01-01"				
			fi
		fi
		curl http://ghtorrent.org/downloads.html > ghtorrent_new
		if [ "$daily" == true ]; then
			grep 'http://ghtorrent-downloads.ewi.tudelft.nl/mongo-daily' ghtorrent_new > ghtorrent_links
		else
		 	grep 'http://ghtorrent-downloads.ewi.tudelft.nl/mysql' ghtorrent_new > ghtorrent_links
		fi

		input="ghtorrent_links"
		while IFS= read -r line
		do

			str_link=$( echo "$line" |cut -d '"' -f2 )
			str_file_name=$( echo "$str_link"| cut -s -d/ -f5)
			str_folder_name=$( echo "$str_file_name"| cut -s -d "." -f1)
			str_size=$( echo "$line"| cut -s -d "(" -f2 |cut -s -d " " -f1)

			# Only use a single folder in debug mode
			if [ "$debug" == true ] && [ "$str_folder_name" != "$debug_folder" ]; then
				continue
			fi
			str_folder_name=$debug_prefix$str_folder_name


			if [ ! -d "$str_folder_name" ]; then
				mkdir "$str_folder_name"
				echo "Folder: $str_folder_name created" >> log
			fi
			
			# Save information from the ghtorrent website in the folder
			echo "$str_link" > "$str_folder_name/SG_LINK"
			echo "$str_file_name" > "$str_folder_name/SG_FNAME"
			echo "$str_size" > "$str_folder_name/SG_FSIZE"

			# Start downloading if file not exits or last attempt did not sucseed.
			if [ ! -f "$str_folder_name/SG_DOWNLOAD_DONE" ]; then
				echo "Folder: $str_folder_name no SG_DOWNLOAD_DONE" >> $log
				if [ -f "$str_folder_name/$str_file_name" ]; then
					rm $str_folder_name/$str_file_name
					echo "File: removing $str_folder_name/$str_file_name" >> $log
				fi
				curl -o "$str_folder_name/$str_file_name" "$str_link" 
				echo "File: Downloading $str_folder_name/$str_file_name" >> $log
				curl_exit_code=$?
				if [ "$curl_exit_code" == "0" ]; then
					echo "File: Downloading $str_folder_name/$str_file_name sucseeded" >> $log
					tar -tzf "$str_folder_name/$str_file_name" >/dev/null
					tar_exit_code=$?
					if [ "$tar_exit_code" == "0" ]; then
						echo "" > "$str_folder_name/SG_DOWNLOAD_DONE"
						echo "File: $str_folder_name/$str_file_name is extractable" >> $log
						echo "File: Creating $str_folder_nam/SG_DOWNLOAD_DONE" >> $log
					fi
				fi
			else
				echo "File: $str_folder_name/$str_file_name already Downloaded" >> $log
			fi
			# Start processing if last processing did not suceeded
			if [  -f "$str_folder_name/SG_DOWNLOAD_DONE" ] && [ ! -f "$str_folder_name/SG_PROCESSING_DONE" ]; then
				wait $old_process
				if [ "$debug" == true ]; then
					
					echo "Call: ./processing.sh  $str_folder_name $str_file_name" >> $log
					./processing.sh "$str_folder_name" "$str_file_name"
					old_process=$new_process
					new_process=$!
				else
					echo "Call: ./processing.sh  $str_folder_name $str_file_name" >> $log
				  	./processing.sh "$str_folder_name" "$str_file_name" & disown
					old_process=$new_process
					new_process=$!
					
				fi
			else
				echo "File: $str_folder_name/$str_file_name already processed" >> $log
				if [ -f "$str_folder_name/$str_file_name" ]; then
					rm $str_folder_name/$str_file_name
				fi
			fi
		done < "$input"

		if [ "$debug" == true ]; then
			break
		else
			break
#			sleep 1m
		fi
	done
fi



