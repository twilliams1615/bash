#!/bin/bash

###################################
#Creates a file.managed state file#
#Uses a list of files specified   #
#Set BASEDIR to the root directory#
# -that files should live         #
#                                 #
#--Set user, group, and mode      #
###################################

SOURCE=$1
USAGE="$(basename "$0") [-h] <list> "
DESCRIPTION="Generate a salt file managed state based on a list in a specified file<list>"
BASEDIR=""

## Usage
if [ $# -eq 0 ] || [ $1 == "-h" ] || [ $1 == "--help" ]
then
    echo "Usage: $USAGE"
    echo ""
    echo -e "$DESCRIPTION\nBy default, output displays to screen.\nRedirect output to a file to save"
    exit 0
fi


	cat  << EOF

/$BASEDIR/$i:
  file.managed:
    - source: salt://$BASEDIR/$i
    - makedirs: true
    - user: root
    - group: root
    - mode: 664
   
EOF


