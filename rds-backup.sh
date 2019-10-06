#!/bin/bash
# This script will take the latest automated snapshot, and convert it to a manual snapshot. This allows you to keep it indefinetly,
# rather than lose it after Amazon's 31 day max retention for automated backups

# Requires use of AWS CLI profile. If you do not have one, just remove --profile "$(profile)" from the command in the script 
# Insert database identifier. This is the name of the database you are using
# Enter an email address to send results to. 
set -e 


#read inputs to set variables 
read -r -p "Enter AWS Profile name: " profile 
read -r -p "Enter database identifier: " identifier 
read -r -p "Enter your email address: " email

date_current=$(date -u +%Y-%m-%d)

# Get the name of the latest DB snapshot and store it in a temp file
aws --profile "$(profile)" rds describe-db-snapshots --snapshot-type "automated" --db-instance-identifier "$identifier" | grep "$date_current" | grep rds | tr -d '",' | awk '{ print $5 }' > /tmp/snapshot.txt
snapshot_name=$(cat /tmp/snapshot.txt)
target_snapshot_name=$(echo /tmp/snapshot.txt | sed 's/rds://')

# Make the conversion.
# Email the results, then cleanup.
aws --profile "$(profile)" rds copy-db-snapshot --source-db-snapshot-identifier "$snapshot_name" --target-db-snapshot-identifier "$target_snapshot_name-monthly" > /tmp/"$date_current"-results.txt 2>&1
echo /tmp/"$date_current"-results.txt | mail -s "[Monthly RDS Snapshot Backup] $date_current" "$email"
rm /tmp/"$date_current"-results.txt
rm /tmp/snapshot.txt
