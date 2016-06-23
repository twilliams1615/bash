######################################
# Basic template for script usage    #
# Covers no arguments, -h or --help  #
# Put in start of bash script.
######################################

USAGE="$(basename "$0") [-h] <args> "
DESCRIPTION="Stick a description here"

if [ $# -eq 0 ] || [ $1 == "-h" ] || [ $1 == "--help" ]
then
    echo "Usage: $USAGE"
    echo ""
    echo "$DESCRIPTION\nadd anything else here"
    exit 0
fi


