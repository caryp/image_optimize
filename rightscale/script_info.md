# Overview

To produce faster boot times, this script bundles a running VM into a new image that will be used on next launch.

Useful for drastically reducing boot times in your auto-scaling tier.  The [Nexdoor.com Engineering Blog has a good post](http://engblog.nextdoor.com/post/84152751184/make-it-faster) with details about why you might want to use this script.



When booting with a bundled image, the software will already be preinstalled. This should create greatly reduce your server boot times and make your auto-scaling events even more responsive.  However, it requires that your boot scripts are idempotent.

# Usage

Add to any ServerTemplate as an operational script, or run on a server as an "any script".  This script will then bundle the running server into a new image.  It will also associate the new image to the "next" instance, so that will be used on the next launch or relaunch.  This can be used with a single server, but is especially useful in a server array.

Here is the basic workflow:

* Launch a EC2 instance from a base OS image.
* Converge system into whatever you want it to be (i.e. application server)
* Prepare the system for snapshotting. (see [clean_for_rebundle](https://github.com/caryp/clean_for_rebundle) project)
* Run this script as an ['Any Script'](http://support.rightscale.com/12-Guides%2FDashboard_Users_Guide%2FManage%2FServers%2FActions%2FRun_%27Any_Script%27_on_a_Server%28s%29)
* Setup script inputs (see next section)
* Next launch will be optimized!

NOTE: Because this script cleans up the RightLink agent state, once you run this script on a running server it will no longer be usable and should be terminated or relaunched.

Set Script Inputs
-----------------
In addition to the AWS and RightScale API credentials, you will need to set the required "Image Caching Inputs" (see "Inputs" section below).  The two main inputs are `CACHED_IMAGE_PREFIX` and `CACHED_IMAGE_DESCRIPTION`.  Since this script can generate a lot of throw-away images, using a common prefix can be useful for filtering and cleaning up old images.  The description input also help describe what these throw away images are.

Bundling EBS Images
-------------------
Bundling these type of images are relatively fast.  Simply set the `IMAGE_TYPE` input to "ebs".  You can ignore the inputs documented in the "S3 Image Inputs" section below.

Bundling S3 Images
------------------
Running this script on S3 based (instance store) images is a bit more complicated.  For these images there must be enough space on disk to store the bundled image, which will then be uploaded to S3.  If there is not enough room on your root partition, use the `AWS_S3_BUNDLE_DIRECTORY` input to specify a location on an attached volume or ephemeral device.

You also need to pass in a few extra inputs that specify where to store the image (`AWS_S3_IMAGE_BUCKET`) and how to encrypt it (AWS_X509_KEY and AWS_X509_CERT).  See the "S3 Image Inputs" below for more information.

Do not change `AWS_S3_BUNDLE_NO_FILTER` unless you are absolutely sure you know what you are doing. Changing this can have security implications.

Debugging
---------
Because this script cleans up the cloud metadata/userdata and rightlink state.js files, you will only be able to run this script once on a server.  This is not very conducive to development or debugging issues.  To allow running this script ulitple times be sure to set the `DISABLE_CLEANUP` input.  This will stop the script from deleting the these files.

By default the ec2 commands are not logged because they contain AWS credentials.  However, when something fails it is useful to have the exact command so you can cut-and-paste it to the command-line for experimentation.  To enable this verbose logging set the `IMAGE_OPTIMIZE_DEBUG` input to "true".

***DISCLAIMER: these inputs should not be set when optimizing images for production.  Leaving them set can expose cloud credentials and produce undefined behavior in the resulting images.***

Kernel Override
---------------
By default the same kernel used in the running server will be used for the new image.  It is possible to change this using the `KERNEL_ID_OVERRIDE`. However, for v14 images and later, this should not be needed.


# Requirements


* EC2 Clouds only (any region)


# Known Limitations


* Currently will only map up to 4 ephemeral drives to image. Some instance types support up to 24.
* Only tested on Ubuntu 12.04
* The PVGrub kernels that the S3 RightImages ship with (1.03) do not work for re-bundled partitioned images. There is a newer `kernel pv-grub-hd0_1.04-x86_64` that should be used instead. The kernel ID can be set using the new `KERNEL_ID_OVERRIDE` input. The IDs are region specific, for a current list of IDs see http://goo.gl/dOS0mB


# Inputs


## Image Caching Inputs

    IMAGE_TYPE
      Required: Yes
      Description: What kind of image are you bundling? This should match the image type that you booted with.
      Perhaps this could be auto-detected this in the future.
      Default: `text:S3`

    CACHED_IMAGE_DESCRIPTION
      Required: Yes
      Description: A description to add to resulting cached images.
      Default: text:Optimized cached image

    CACHED_IMAGE_DESCRIPTION
      Required: Yes
      Description: A description to add to resulting cached images.
      Default: text:Optimized cached image

    CACHED_IMAGE_PREFIX
      Required: Yes
      Description: Prefix added to cached image names. Useful to help search for cached images
      Default: text:cached

    DISABLE_CLEANUP
      Description: If set, don't clean up some state files. This will allow the script to be rerun on the
      same instance multiple times which is useful for debugging.
      NOTE: Boot issues may occur if state is not properly cleaned up.

    IMAGE_OPTIMIZE_DEBUG
      Description: if 'true' will enable debug logging.
      WARNING: will write ec2 creds to log if set!!
      Default: text:false

    KERNEL_ID_OVERRIDE
      Description: kernel to use instead of what the VM is running. For a current list of IDs see http://goo.gl/dOS0mB Example: "aki-fc8f11cc"

S3 Image Inputs
---------------

If `IMAGE_TYPE` input is set to `S3`, then the following inputs need to be set:

    AWS_X509_KEY
      Description: An X.509 private key material associated with your EC2 account.
      Please see http://goo.gl/P6vGdU for more info.

    AWS_X509_CERT
      Description: An X.509 certificate material associated with your EC2 account.
      Please see http://goo.gl/P6vGdU for more info.

    AWS_S3_IMAGE_BUCKET
      Description:Set S3 bucket name for cached images (must be url safe) Example: my-optimized-images.
      ONLY REQUIRED FOR S3 IMAGE RE-BUNDLES.
      Default: text:cached-images

    AWS_S3_BUNDLE_NO_FILTER
      Description: If set, will disable the default filtering used by the ec2-bundle-vol command.
      WARNING: setting this option could leave ssh keys or other secrets on your image.

    AWS_S3_BUNDLE_DIRECTORY
      Description: The local directory where the image bundle will be stored before uploading to S3.
      NOTE: this must have enough free space to hold the image bundle.
      Default: "/mnt/ephemeral/bundle"

AWS Credentials
---------------

    AWS_ACCOUNT_NUMBER
    Required: Yes

    AWS_ACCESS_KEY
    Required: Yes
    Default Value:cred:AWS_ACCESS_KEY_ID

    AWS_SECRET_KEY
    Required: Yes
    Default Value:cred:AWS_SECRET_ACCESS_KEY


RightScale Credentials
----------------------

    API_USER_EMAIL
    Required: Yes
    Description:The email address you use to log into the RightScale dashboard.

    API_USER_PASSWORD
    Required: Yes
    Description:The password you use to log into the RightScale dashboard. Using a 'cred' input type is recommended.
