#!/usr/bin/env bash
##################################################################################
# Downloads and installs the specified version of terraform
# Run using sudo unless your user has permissions to write to /usr/local/bin/
##################################################################################

set -e

#===================================================================================
# Usage function 
#===================================================================================
usage ()
{
        cat <<EOF

	Usage : install-terraform.sh [new version]

	Installs the version of terraform specified. Must be ran with sudo.
        Specify the version numver you wish to install. A list of version can be found at:
        https://www.terraform.io/downloads.html
EOF
    exit
}


#===================================================================================
# Checks if using sudo
#===================================================================================
if [[ $(id -u) -ne 0 ]]; then
    echo "Please run using sudo"
    exit 3
fi

#===================================================================================
# Verifies a version is specified and assigns variables
#===================================================================================
if [ "$#" -ne 1 ]
then
    usage
fi

currentver="$(terraform -v |head -1 |awk '{print $2}')"
newver=$1
# Terraform.URL: https://www.terraform.io/downloads.html
URL=https://releases.hashicorp.com/terraform/$newver/terraform_"${newver}"_linux_amd64.zip


#===================================================================================
# Downloads and installs terraform
#===================================================================================

if [ "${currentver}" == "v${newver}" ]; then
   echo "You chose to install v${newver}, but you are already on that version."
   exit 3
else
    echo "You are currently on version ${currentver}, and are installing ${newver}."
    read -n2 -p "Do you wish to continue? (y/n) " choice
    if [[ "${choice}" == 'y' ]] || [[ "${choice}" = 'Y' ]]
    then
	echo "Continuing with install of v${newver} ..."   
        curl -O ${URL}
        unzip terraform_"${newtver}"_linux_amd64.zip -d /usr/local/bin/
        # Cleanup
        rm terraform_"${newtver}"_linux_amd64.zip
	# verify we're all set to terraform
	terraform -v
    fi
fi


   

