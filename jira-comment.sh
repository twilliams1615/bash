#!/bin/bash

JIRA_HOST="somehost.example.com"
JIRA_USER="someuser"
JIRA_PASS="somepass"
# Set the user and password in a settings file
# instead of in the script
. /etc/default/jira

OUTFILE="/tmp/create_jira_comment-$(date +%Y%m%d-%H%M%S)"

# Show usage information
usage() {
  cat >&2 <<EOF
Usage:
  $0 [-h | -t TICKET <-f FILENAME> <-H "Header text"> <-F "Footer text"> <-C>]

Examples:
  This will add a comment using -H and the contents of the file specified, wrapped in a code block.
      command -t cops-101 -H "text before a code block" -f /path/to/file.txt -C
  
  This will use the output of a command as the comment
      grep 'some error' /var/log/error | command -t cops-101 

This script adds a comment to a Jira ticket based on
command-line arguments.

OPTIONS:
  -h              Show usage information (this message).
  -t TICKET       The Jira ticket name (ie COPS-101)
  -f FILENAME     A file containing content to add as Jira comment (or leave off to read from pipe)
  -H HEADER_TEXT  Text to put at the beginning of the comment
  -F FOOTER_TEXT  Text to put at the end of the comment
  -C              Wrap comment in a {code} tags (does not wrap text from -H or -F, only text parsed from another command or from the file specified with -f)
EOF
}

# Parse Options
while getopts ":t:f:H:F:Ch" flag; do
  case "$flag" in
    h)
      usage
      exit 3
      ;;
    t)
      TICKET="${OPTARG}"
      ;;
    f)
      FILENAME="${OPTARG}"
      ;;
    H)
      HEADER="${OPTARG}"
      ;;
    F)
      FOOTER="${OPTARG}"
      ;;
    C)
      CODETAG='{code}'
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument"
      exit 1
      ;;
  esac
done

# Shift past all parsed arguments
shift $((OPTIND-1))

test -z "$TICKET" && usage && echo "No ticket specified!" && exit 1
test -z "$FILENAME" && FILENAME='-'

echo -n -e '{\n  "body": "' > "${OUTFILE}".json
test -z "$HEADER" || echo -n -e "${HEADER}\n" >> "${OUTFILE}".json
test -z "$CODETAG" || echo -n -e "${CODETAG}\n" >> "${OUTFILE}".json
cat ${FILENAME} | perl -pe 's/\r//g; s/\n/\\r\\n/g;s/\"/\\"/g' >> "${OUTFILE}".json
test -z "$CODETAG" || echo -n -e "\n${CODETAG}" >> "${OUTFILE}".json
test -z "$FOOTER" || echo -n -e "\n${FOOTER}" >> "${OUTFILE}".json
echo -e '"\n}' >> "${OUTFILE}".json

# Post the comment
curl -s -S -u $JIRA_USER:$JIRA_PASS -X POST --data @"${OUTFILE}".json -H "Content-Type: application/json" https://$JIRA_HOST/rest/api/latest/issue/"${TICKET}"/comment 2>&1 >> "$OUTFILE"

if [ $? -ne 0 ]; then
  echo "Creating Jira Comment failed"
  exit 1
fi

# Cleanup
rm -f $OUTFILE
