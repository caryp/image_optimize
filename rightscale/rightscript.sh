#!/bin/bash -ex
#
# Author: cary@rightscale.com
# Copyright 2014 RightScale, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# $API_USER_EMAIL - RightScale Dashboard User email
# $API_USER_PASSWORD - Rightscale Dashboard Password
#
# $AWS_ACCESS_KEY - EC2 Account Access Key
# $AWS_SECRET_KEY - EC2 Account Secret
# $AWS_ACCOUNT_NUMBER - EC2 Account ID
#
# $CACHED_IMAGE_PREFIX - Prefix to generated images name to help search for cached images
# $CACHED_IMAGE_DESCRIPTION - Description to add to cached images
#
# $KERNEL_ID_OVERRIDE - Kernel to use instead of what the VM is running. i.e. "aki-fc8f11cc"
#                           For a current list of IDs see http://goo.gl/dOS0mB
#
# $AWS_S3_BUNDLE_DIRECTORY - The local directory where the image bundle will be stored before uploading to S3.
#                            NOTE: this must have enough free space to hold the image bundle.
#                            Default: "/mnt/ephemeral/bundle"
#
# $AWS_S3_BUNDLE_NO_FILTER - If set, will disable the default filtering used by the ec2-bundle-vol command.
#                            WARNING: setting this option could leave ssh keys or other secrets on your image.
#

# source the profile
source /etc/profile

# update CA certs
# fixes intermediate "SSL certificate problem" errors from curl
# See https://forums.aws.amazon.com/thread.jspa?messageID=341463&#341463
#
# update-ca-certificates


# install require packages
apt-get install unzip default-jre


# install right_api_client gem (if not installed) into RightLink Sandbox
#
sandbox_bin=/opt/rightscale/sandbox/bin
gem_bin=$sandbox_bin/gem
if ! $gem_bin list image_optimize --installed ; then
  echo "Installing image_optimize gem..."
  $gem_bin install $ATTACH_DIR/image_optimize-*.gem --no-rdoc --no-ri
fi

# configure Java (needed by ec2 tools)
#
export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64


# install EC2 tools
#
tools_dir=/tmp/ec2tools
if [ ! -d $tools_dir ]; then
  mkdir -p $tools_dir

  # install EC2 API tools
  #
  if [ ! -d $tools_dir/ec2-api-tools-1.6.13.0 ]; then
    unzip $ATTACH_DIR/ec2-api-tools-1.6.13.0.zip -d $tools_dir
  fi

  # install EC2 AMI tools
  #
  if [ ! -d $tools_dir/ec2-ami-tools-1.5.0.0 ]; then
    unzip $ATTACH_DIR/ec2-ami-tools-1.5.0.0.zip -d $tools_dir
  fi

  # install ec2 tools package dependencies
  apt-get -y install grub kpartx gdisk
fi

# setup ec2 tools env
#
export EC2_HOME=$tools_dir/ec2-api-tools-1.6.13.0
export PATH=$tools_dir/ec2-api-tools-1.6.13.0/bin:${PATH}
export EC2_AMITOOL_HOME=$tools_dir/ec2-ami-tools-1.5.0.0
export PATH=$tools_dir/ec2-ami-tools-1.5.0.0/bin:${PATH}


# setup S3 bundle creds (unless EBS)
#
opts="--aws-image-type $IMAGE_TYPE"
if [ "$IMAGE_TYPE" != "EBS" ]; then
  echo "Setting up S3 bundle creds..."
  export certs_dir=/tmp/certs

  # set default bucket name for cached images (must be url safe)
  # (TODO: pass this as command-line options)
  if [ -n "$AWS_S3_IMAGE_BUCKET" ]; then
     opts=$opts" --aws-s3-image-bucket $AWS_S3_IMAGE_BUCKET"
  fi

  # set required S3 environment variables
  key_path=$certs_dir/x509.key
  cert_path=$certs_dir/x509.cert

  opts="$opts --aws-s3-key-path $key_path --aws-s3-cert-path $cert_path"

  # write x.509 creds to disk
  mkdir -p $certs_dir
  set +x # don't echo these commands!
  cat <<EOF>$key_path
$AWS_X509_KEY
EOF
  cat <<EOF>$cert_path
$AWS_X509_CERT
EOF

  # The local directory where the image bundle will be stored before uploading to S3.
  # NOTE: this must have enough free space to hold the image bundle.
  # Default: "/mnt/ephemeral/bundle"
  if [ -n "$AWS_S3_BUNDLE_DIRECTORY" ]; then
    opts=$opts" --aws-s3-bundle-directory $AWS_S3_BUNDLE_DIRECTORY"
  fi

  # If set, will disable the default filtering used by the ec2-bundle-vol command.
  # WARNING: setting this option could leave ssh keys or other secrets on your image.
  if [ -n "$AWS_S3_BUNDLE_NO_FILTER" ]; then
    opts=$opts" --aws-s3-bundle-no-filter"
  fi

fi

# enable debugging (if specified)
# WARNING: will write ec2 creds to log if set!!
if [ -n "$IMAGE_OPTIMIZE_DEBUG" ]; then
  opts=$opts" --verbose"
fi

# If set, don't clean up some state files.  This will allow the script to be
# rerun on the same instance multiple times which is useful for debugging.
# NOTE: Boot issues may occur if state is not properly cleaned up.
if [ -n "$DISABLE_CLEANUP" ]; then
  opts=$opts" --no-cleanup"
fi

# Prefix to generated images name to help search for cached images
if [ -n "$CACHED_IMAGE_PREFIX" ]; then
  opts=$opts" --prefix $CACHED_IMAGE_PREFIX"
fi

# Description to add to cached images
if [ -n "$CACHED_IMAGE_DESCRIPTION" ]; then
  opts=$opts" --description $CACHED_IMAGE_DESCRIPTION"
fi

# Kernel to use instead of what the VM is running. i.e. "aki-fc8f11cc"
# For a current list of IDs see http://goo.gl/dOS0mB
if [ -n "$KERNEL_ID_OVERRIDE" ]; then
  opts=$opts" --aws-kernel-id $KERNEL_ID_OVERRIDE"
fi

# run optimizer
#
echo "Running image_optimize utility..."
#cmd="$sandbox_bin/ruby bin/image_optimize $opts"
cmd="image_optimize $opts"
echo "COMMAND: $cmd"
eval $cmd

# clean up creds after S3 bundling
#
if [ "$IMAGE_TYPE" !=  "EBS" ]; then
  echo "clean up creds for S3 bundling"
  rm -rf $certs_dir
fi

exit 0