#!/bin/bash
# This script will take the latest automated snapshot, and convert it to a manual snapshot. This allows you to keep it indefinetly,
# rather than lose it after Amazon's 31 day max retention for automated backups

# Insert your AWS Access and Secret key into variable
# Insert database identifier. This is the name of the database you are using
# Enter an email address to send results to. 

export AWS_ACCESS_KEY=""
export AWS_SECRET_KEY=""
export identifier = ""
export email = ""
date_current=`date -u +%Y-%m-%d`

# Get the name of the latest DB snapshot and store it in a temp file
aws rds describe-db-snapshots --snapshot-type "automated" --db-instance-identifier $identifier | grep $date_current | grep rds | tr -d '",' | awk '{ print $5 }' > /tmp/snapshot.txt
snapshot_name=`cat /tmp/snapshot.txt`
target_snapshot_name=`cat /tmp/snapshot.txt | sed 's/rds://'`

# Make the conversion.
# Email the results, then cleanup.
aws rds copy-db-snapshot --source-db-snapshot-identifier $snapshot_name --target-db-snapshot-identifier $target_snapshot_name-monthly > /tmp/$date_current-results.txt 2>&1
cat /tmp/$date_current-results.txt | mail -s "[Monthly RDS Snapshot Backup] $date_current" $email
rm /tmp/$date_current-results.txt
rm /tmp/snapshot.txt
