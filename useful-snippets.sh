#!/bin/bash

### Get the day's forcast of current location
# add it as an alias to make it easier to use
curl -s "wttr.in/$1?m1"


### Use this to track the time duration of running a script
# This goes at the very beginning of the script
START=$(date +%s)
# This goes at the very end, or at your exits.
END=$(date +%s)
DIFF=$(( $END - $START ))
if [ $DIFF -le 60 ]; then
		scripttime="$DIFF seconds.";
	else
		DIFF=$(( $DIFF / 60 ))
		scripttime="$DIFF minutes.";
	fi;
echo "The script took ${DIFF} minutes to run"


### This function can be used to log time of outputs with timestamps
# Call the function using 'log "my string to be logged"'
log() {
     echo [$(date +%Y-%m-%d\ %H:%M:%S)] "$*"
}


### Check if a process is running before executing the rest of a script
# Call using 'check_process service' where service is the name of the service you are checking
# EX: check_process postgresql
check_process() {
	echo "Checking if process $1 exists..."
	[ "$1" = "" ]  && return 0
	PROCESS_NUM=$(ps -ef | grep "$1" | grep -v "grep" | wc -l)
	if [ "$PROCESS_NUM" -ge 1 ];
	then
	        return 1
	else
	        return 0
	fi
}


### Read variables from a config file.
# Secrets should never be kept in a script being executed. Create a config file that defines variables
# then add this at the beginning of the script
. configfile



### Send an email. Set values for the email body ${content}, subject line ${subject}, and recipients ${recipients}
# Then call the function as needed. This will also include the runtime of the script.
START=$(date +%s)
sendEmail() {
	scripttime=0;
	END=$(date +%s)
	DIFF=$(( $END - $START ))
	if [ $DIFF -le 60 ]; then
		scripttime="$DIFF seconds.";
	else
		DIFF=$(( $DIFF / 60 ))
		scripttime="$DIFF minutes.";
	fi;
	content="$content. Exec Time: $scripttime"
	echo "$content" | mail -s "$subject" "$email_list"
	exit;
}


### Up directory function. If in a deep directory, you can use this to cd up N directories. Put this in /usr/local/bin or something
# EX: if you are in /a/long/directory/tree, "up 3" will cd you to /a
LIMIT=$1
P=$PWD
for ((i=1; i <= LIMIT; i++))
do
    P=$P/..
done
cd $P
