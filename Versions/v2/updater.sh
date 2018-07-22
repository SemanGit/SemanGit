#!/bin/bash
# Set option variables
debug=false
help=false
fake=false
daily=false

debug_folder=""
debug_prefix=""
input="./ghtorrent.com/ghtorrent_links"

max_active_dumps=3
sleep_time=24h

echo "Starting Script" &
old_process=$!
new_process=$!

# Check options
for option in "$@"
do
	if [ "$option" == "-d" ] || [ "$option" == "-debug" ]; then
		debug=true
		debug_prefix="debug_"
	elif [ "$option" == "-h" ] || [ "$option" == "-help" ]; then
		help=true
	elif [ "$option" == "-f" ] || [ "$option" == "-fake" ]; then
		fake=true
		debug_prefix="fake_"
	elif [ 	$( echo "$option" |cut -d '=' -f1 ) == "-debug_folder" ]; then
		debug_folder=$( echo "$option" |cut -d '=' -f2 )
	elif [ 	$( echo "$option" |cut -d '=' -f1 ) == "-max_active_dumps" ]; then
		max_active_dumps=$( echo "$option" |cut -d '=' -f2 )
	elif [ 	$( echo "$option" |cut -d '=' -f1 ) == "-sleep_time" ]; then
		sleep_time=$( echo "$option" |cut -d '=' -f2 )
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
	echo '-debug, -d: 				Run in debug mode. Only one folder is evaluated. Script runs only once.'
	echo '-fake, -f: 				Run in fake mode. All folders are evaluated, but faked Data is used instead of Donloaded.'
	echo '-max_active_dumps=[N]:			Number of available dumps on the server.'
	echo '-sleep_time={[N]s,[N]m,[N]h,[N]d}:	Sleep time until update in seconds, minutes, hours and days'
	echo '-debug_folder=<folder_name>: 		Use specific folder for debugging. Default value is my-sql-2018-01-01'
	echo '-------------------'
	echo -e '-h , -help:				Print help file\n'

# Else run script.
else
	if [ ! -d "./logs" ]; then
		mkdir "./logs"
	fi
	if [ ! -d "./ghtorrent.com" ]; then
		mkdir "./ghtorrent.com/"
	fi

	while true; do
		timestamp=`date "+%Y_%m_%d_%H_%M_%S"`
		count_active_dumps="0"
		log="./logs/log_$timestamp"
		if [ "$debug" == true ]; then
			echo "Running in debug mode!" 
		elif [ "$debug_folder" == "" ]; then
				debug_folder="mysql-2018-01-01"				
		fi
		curl http://ghtorrent.org/downloads.html > ./ghtorrent.com/ghtorrent_new
	 	grep 'http://ghtorrent-downloads.ewi.tudelft.nl/mysql' ./ghtorrent.com/ghtorrent_new > ./ghtorrent.com/ghtorrent_links

		
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
				echo "Folder: $str_folder_name created" >> $log
			fi
			
			# Save information from the ghtorrent website in the folder
			echo "$str_link" > "$str_folder_name/SG_LINK"
			echo "$str_file_name" > "$str_folder_name/SG_FNAME"
			echo "$str_size" > "$str_folder_name/SG_FSIZE"

			# Start processing if file is new enough
			if (( "$count_active_dumps" < "$max_active_dumps" )); then

				# Start downloading iff file not exits or last attempt did not sucseed.
				if [ ! -f "$str_folder_name/SG_DOWNLOAD_DONE" ]; then
					echo "Folder: $str_folder_name no SG_DOWNLOAD_DONE" >> $log
					if [ -f "$str_folder_name/$str_file_name" ]; then
						rm $str_folder_name/$str_file_name
						echo "File: removing $str_folder_name/$str_file_name" >> $log
					fi
					if [ "$fake" == false ]; then
						curl -o "$str_folder_name/$str_file_name" "$str_link" 
						echo "File: Downloading $str_folder_name/$str_file_name" >> $log
						curl_exit_code=$?
					else
						cp "./example_data/example.tar.gz" "$str_folder_name/$str_file_name"
						curl_exit_code="0"
					fi
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
					echo "Call: ./processing.sh  $str_folder_name $str_file_name" >> $log
					./processing.sh "$str_folder_name" "$str_file_name"
				fi
			fi

			# Clean the mess up.
			if [ -f "$str_folder_name/SG_PROCESSING_DONE" ]; then
				count_active_dumps=$[$count_active_dumps +1]

				echo "File: $str_folder_name/$str_file_name processed" >> $log
				if [ -f "$str_folder_name/$str_file_name" ]; then
					rm -type f $str_folder_name/$str_file_name
					echo "File: removing .tar.gz" >> $log
				fi
				if [ "$count_active_dumps" == "1" ]; then
					echo "$str_folder_name/$str_folder_name/rdf/combined.ttl" > "SG_RECENT_DUMP"
				fi
				if [ "$count_active_dumps" -ge "$max_active_dumps" ]; then
					find "$str_folder_name/" -name "combined.ttl" -type f -delete
					cd $str_folder_name
					find "." -type d -delete >> /dev/null
					cd ../
					echo "Folder: removing $str_folder_name" >> $log
				fi
			fi

		done < "$input"
		if [ "$debug" == true ]; then
			break
		else
			sleep "$sleep_time"
		fi
	done
fi



