#!/bin/bash

 ################################################################################
# This script is to collect error logs from all RDS postgresql instances         #
# and ingest them into a Sumologic http connector                                #
#                                                                                #
#                                                                                #
# Note: Requires the aws and rds cli tools                                       #
# http://docs.aws.amazon.com/AmazonRDS/latest/CommandLineReference/StartCLI.html #
#                                                                                #
# Usage: replace REDACTED in url to match your collector url.                    #
 ################################################################################

URL='https://collectors.us2.sumologic.com/receiver/v1/http/REDACTED'
DB=$(rds-describe-db-instances |grep DBINSTANCE |awk '{print $2}'| sed 's/:.*//')

for rds in $DB
do
    for logfile in $(aws rds describe-db-log-files --db-instance-identifier "$rds" | jq '.DescribeDBLogFiles|.[]|.LogFileName')
    do
        aws rds download-db-log-file-portion --db-instance-identifier "$rds" --log-file-name "${logfile}" | curl -X POST -H "X-Sumo-Name:$rds-rds" -d @- "$URL"
    done

done




