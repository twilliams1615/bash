#!/bin/bash
set -e
#===================================================================================
#        FILE: terraform-setup.sh
#
#       USAGE: terraform-setup.sh [-e environment] [-r region] [-a action]
#
# DESCRIPTION: Pulls the latest terraform repo and configures the backend of
#              Terraform to use the proper remote state.
#              You must specify the environment, the region, and the terraform action.
#              If plan or apply is specified, the latest configuration will be pushed
#              to the environment or region specified.
#===================================================================================


#===================================================================================
# Usage function and checks
#===================================================================================
usage ()
{
    cat <<EOF

Usage : terraform-setup.sh [-e environment] [-r region] [-a action]

Terraform uses \$AWS_ACCESS_KEY_ID and \$AWS_SECRET_ACCESS_KEY to authenticate.
These should be set according to the account you are running against.

Actions:
    apply              Builds or changes infrastructure
    plan               Generate and show an execution plan
    show               Inspect Terraform state or plan

Region:
    east               US-EAST-1 (N Virginia)
    west               US-WEST-2 (Oregon)

Environment:
    qa12               12.qa.iz 
    qa13               13.qa.iz 
    prod1              1.prod.iz
    prod2              2.prod.iz
    sbx1               1.sbx.iz 

EOF
    exit
}

#===================================================================================
# Sets variables from arguments
#===================================================================================
if [ "$#" -ne 6 ]
then
    usage
fi

while [ "$1" != "" ]; do
    case $1 in
	-e )           shift
		       env=$1
		       ;;
	-r )           shift
		       region=$1
		       ;;
	-a )           shift
		       action=$1
		       ;;

    esac
    shift
done

#===================================================================================
# Empties the .terraform directory.
# This ensures we pull the current state down to prevent users from running against
# out of date state files.
#===================================================================================
if [ ! -d ".terraform" ]
then
    echo "Double check that you are in the terraform main directory and try again"
    exit 3
else
    echo "Emptying the .terraform directory"
    rm -rf ./.terraform/*
fi



#===================================================================================
# Make sure the proper version of terraform is installed
#===================================================================================
versioncheck() {
    tver="$(terraform -v |head -1 |awk '{print $2}')"
    expectedver="v0.9.5"
    if [[ "$tver" != "$expectedver" ]]
    then
	  echo "Your terraform version is $tver. Please install $expectedver."
        exit 3
    fi
}

#===================================================================================
# Asks user to verify the access key is right.
#===================================================================================
awscheck() {
  echo ""
  if [ -n "$AWS_ACCESS_KEY_ID" ]; then
    echo "The AWS Access key is set to: $AWS_ACCESS_KEY_ID."
  elif [ -n "$AWS_PROFILE" ]; then
    echo "The AWS Profile is set to: $AWS_PROFILE"
  else
    echo "You must set AWS_PROFILE or AWS_ACCESS_KEY_ID/AWS_ACCESS_SECRET_KEY"
    exit
  fi
  echo ""
  read -n2 -p "Continue (y/n)? " choice
  if [[ "$choice" = 'y' ]] || [[ "$choice" = 'Y' ]]
  then
    echo "Continuing"
    sleep 3
  else
    echo "Exiting"
    exit 3
  fi
}

#===================================================================================
# Checks if production or nonprod and sets variables needed
#===================================================================================
envcheck() {
    if [[ $env == "qa12" ]]
    then
        envtype="nonprod"
        key="12-qa-iz"

    elif [[ $env == "qa13" ]]
    then
	 envtype="nonprod"
	 key="13-qa-iz"

    elif [[ $env == "prod1" ]]
    then
        envtype="prod"
        key="1-prod-iz"

    elif [[ $env == "prod2" ]]
    then
        envtype="prod"
        key="2-prod-iz"

    elif [[ $env == "sbx1" ]]
    then
        envtype="sandbox"
        key="1-sbx-iz"

    else
        echo "You have entered an invalid environment."
	      usage
        exit 3
    fi
    echo "The environment is set to ${env}"
    sleep 2
}

prod_protection() {
  branch=$(git rev-parse --abbrev-ref HEAD)
  if [ $envtype = "prod" ] && [ $branch != "master" ]; then
    echo ""
    echo "You are required to run prod updates from the master branch"
    exit
  fi
}

#===================================================================================
# Sets the region to run in
#===================================================================================
regioncheck() {
    if [[ $region == "east" ]]
    then
        region="us-east-1"
    elif [[ $region == "west" ]]
    then
        region="us-west-2"
    else
        echo "You have entered an invalid region."
	      usage
	      exit 3
    fi
    echo "You have set the region to $region"
    sleep 2
}

#===================================================================================
# Sets the terraform backend
#===================================================================================
remoteconfig() {
    terraform init -backend-config="bucket=tf-states-$envtype" -backend-config="key=$key-$region.tfstate"
    terraform get
}

#===================================================================================
# Runs terraform according to the env and region specified
#===================================================================================
runtf() {
    terraform "$action" -var-file env/"$key"-"$region".tfvars
}


#===================================================================================
# Run the functions.
#===================================================================================
versioncheck
awscheck
envcheck
# prod_protection on apply only
if [ "$action" == "apply" ]
then
  prod_protection
fi
regioncheck
remoteconfig
echo -e "Pulling latest commit from repo\n"
git pull

if [ -z "$action" ]
then
    echo "Terraform action has not been specified"
    usage
    exit 3
elif [[ $action == "plan" ]] || [[ $action == "apply" ]] || [[ $action == "show" ]]
then
    runtf
else
    echo "$action is not a valid option."
    usage
    exit 3
fi
