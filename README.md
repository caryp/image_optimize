Image Optimizer
===============

Bundle a running VM into a new image for use on next launch.

Useful for drastically reducing boot times in your auto-scaling tier.

Basic Workflow
--------------
1. Launch a EC2 instance from a base OS image.
2. Converge system into whatever you want it to be (i.e. application server)
3. Prepare the system for snapshotting. (see [clean_for_rebundle](https://github.com/caryp/clean_for_rebundle) project)
3. Install and run image_optimize
4. Next launch will be optimized!!

Requirements
------------
 * EC2 Cloud only
 * VMs must be launched via the [RightScale Platform](www.rightscale.com)

Usage
-----

    image_optimize [options]

    where [options] are:

                      --verbose, -v:   If set will enable debug logging.  WARNING: will write ec2 creds to log if set!!
                   --prefix, -r <s>:   Prefix to add to the optimized image name. Helps when searching for your optimized images. (Default: optimized-image)
              --description, -d <s>:   Description to add to optimized images (default: Cached image)
                 --api-user, -u <s>:   RightScale Dashboard User email. Not needed if API_USER_EMAIL environment variable is set.
             --api-password, -p <s>:   RightScale Dashboard User email. Not needed if API_USER_PASSWORD environment variable is set.
        --cleanup, --no-cleanup, -c:   Don't do any cleanup on VM before snapshotting. Useful for debugging. (Default: true)
               --aws-access-key, -k:   EC2 Account Access Key. Not needed if AWS_ACCESS_KEY environment variable is set.
               --aws-secret-key, -s:   EC2 Account Secret. Not needed if AWS_SECRET_KEY environment variable is set.
           --aws-account-number, -a:   EC2 Account ID. Not needed if AWS_ACCOUNT_NUMBER environment variable is set. Required for S3 images only.
           --aws-image-type, -w <s>:   The type of image to create from this VM. Must be either 'EBS' or 'S3'.  (default: EBS)
            --aws-kernel-id, -e <s>:   Kernel to use instead of what the VM is running. i.e. 'aki-fc8f11cc'. For a current list of IDs see http://goo.gl/dOS0mB.
          --aws-s3-key-path, -y <s>:   location to file containing EC2 account key. S3 images only. (Default: /tmp/certs/x509.key)
         --aws-s3-cert-path, -t <s>:   location to file containing EC2 account cert. S3 images only. (Default: /tmp/certs/x509.cert)
      --aws-s3-image-bucket, -i <s>:   The bucket name for optimized S3 images (must be url safe). S3 images only (default: optimized-images)
    --aws-s3-bundle-directory, -b <s>:   The local directory where the image bundle will be stored before uploading to S3. NOTE: this must have enough free space to hold
                                       the image bundle. (Default: /mnt/ephemeral/bundle)
      --aws-s3-bundle-no-filter, -n:   If set, will disable the default filtering used by the ec2-bundle-vol command. WARNING: setting this option could leave ssh keys or
                                       other secrets on your
                      --version, -o:   Print version and exit
                         --help, -h:   Show this message


Known Limitations
------------------
 * When creating S3 backed (instance store) images on AWS, the `--aws-s3-image-bucket` will not be created -- make sure it exists.
 * Currently will only map up to 4 ephemeral drives to EBS image. Some EC2 instance-types support up to 24.
 * Only tested on Ubuntu 12.04"


Development
-----------
To run this locally, setup the required environment prerequisites:

    > ./setup.sh

Run the spec tests:

    > bundle exec rake spec

Setup a `.secrets/creds` file in the root of the project that defines:

  	export API_USER_EMAIL=you@example.com
  	export API_USER_PASSWORD=your_rightscale_password

  	export AWS_SECRET_KEY=yoursecretkey
  	export AWS_ACCESS_KEY=youraccesskey

  	# needed for S3 (instance store) images only
  	export AWS_ACCOUNT_NUMBER=your_account_number
  	export AWS_S3_IMAGE_BUCKET=my_image_bucket

Then add your credentials to the environment and run the script using the system's ruby interpreter:

    > source .secrets/creds
    > bundle exec ruby bin/image_optimize


Integration Testing
-------------------
Follow the "development" directions (above), then rsync this project to VM:

    > rsync -avz --exclude=.git . root@<ip_addr>:/usr/local/src/image_optimize

Where `<ip_addr>` is the IP address of the VM you plan to test on.
SSH into the VM and run the setup script to install package prerequisites:

    > sudo -i
    > cd /usr/local/src/image_optimize
    > source ./setup

On the VM, run the tests

    > export IMAGE_TYPE=<type> ; bundle exec rake test

Where `<type>` is either `EBS` or `S3` images.


Future
------
 * automate integration testing on EBS and S3 instances
 * break out rightscale specific calls into 'manager' interface to support different management platforms
 * break out system command calls into 'platform' interface to enable multi-distro support


License
-------
Author: cary@rightscale.com
Copyright 2014 RightScale, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

