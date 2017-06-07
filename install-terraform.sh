#!/usr/bin/env bash
set -e
cd ~

tver=0.9.5
pver=1.0.0
terraform=terraform_"${tver}"
packer=packer_"${pver}"


# Create and move into terraform directory.

if [ ! -d "~/${terraform}" ]; then
    mkdir ~/$terraform
else
    exit 0
fi

cd ~/"${terraform}"

# Download Terraform. URI: https://www.terraform.io/downloads.html
curl -O https://releases.hashicorp.com/terraform/$tver/"${terraform}"_linux_amd64.zip

# Unzip and install terraform 
unzip "${terraform}"_linux_amd64.zip

cd ~
if [ ! -d "~/${packer}" ]; then
    mkdir ~/$packer
else
    exit 0
fi
cd ~/"${packer}"

# Download Packer. URI: https://www.packer.io/downloads.html
curl -O https://releases.hashicorp.com/packer/$pver/"${packer}"_linux_amd64.zip
# Unzip and install
unzip "${packer}"_linux_amd64.zip


# Export terraform and packer paths

if grep -q ${terraform} ~/.profile; then
    echo "Your .profile already contains the path for terraform"
    exit 0
else
    echo export PATH=~/${terraform}/:~/${packer}/:$PATH >>~/.profile
    grep terraform ~/.profile
    source ~/.profile
fi

# verify we're all set to terraform and packer.
terraform
packer
