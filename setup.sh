#!/bin/bash -e x

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 40976EAF437D05B5

# This only works for Ubuntu rightnow
# Anyone want to write a Chef recipe?
apt-get update

# install ec2 tools package dependencies
apt-get -y install grub kpartx gdisk

# update CA certs
# fixes intermediate "SSL certificate problem" errors from curl
# See https://forums.aws.amazon.com/thread.jspa?messageID=341463&#341463
#
update-ca-certificates

# setup ruby env
apt-get -y install ruby1.9.1
apt-get -y install ruby1.9.1-dev
update-alternatives --set ruby /usr/bin/ruby1.9.1
update-alternatives --set gem /usr/bin/gem1.9.1
gem install bundler --no-rdoc --no-ri
bundle

export TOOLS_DIR=/tmp/ec2tools
mkdir -p $TOOLS_DIR

# install EC2 tools v1.5 or greater
wget http://s3.amazonaws.com/ec2-downloads/ec2-api-tools-1.6.13.0.zip
unzip ec2-api-tools-1.6.13.0.zip -d $TOOLS_DIR
wget http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools-1.5.0.0.zip
unzip ec2-ami-tools-1.5.0.0.zip -d $TOOLS_DIR

# setup ec2 tools env
#
export EC2_HOME=$TOOLS_DIR/ec2-api-tools-1.6.13.0
export PATH=$TOOLS_DIR/ec2-api-tools-1.6.13.0/bin:${PATH}
export EC2_AMITOOL_HOME=$TOOLS_DIR/ec2-ami-tools-1.5.0.0
export PATH=$TOOLS_DIR/ec2-ami-tools-1.5.0.0/bin:${PATH}