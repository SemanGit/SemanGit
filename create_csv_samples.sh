#!/bin/bash
for option in "$@"; do
	mkdir "head"
	mkdir "head/"$option;
	mkdir "tail"
	mkdir "tail/"$option;
done;

for file in *.csv ; 
do
	
	total_lines=$(cat $file | wc -l)
		for option in "$@"; do
			extract=$((1 + $total_lines / 33920 * $option))
			head -n $extract $file > "head/"$option/$file
			tail -n $extract $file > "tail/"$option/$file
		done;
done;
for option in "$@"; do
	cp schema.sql "head/"$option"/schema.sql"
	cp schema.sql "tail/"$option"/schema.sql"
done;

