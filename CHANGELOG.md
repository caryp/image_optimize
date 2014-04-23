CHANGELOG
=========

Rev1
----
 * preview release

Rev2
----
 * fixed issue with partitioned root volume. cleaned up logging.

Rev3
----
 * modified ec2-register parameter support partitioned images.fixed gem install typo.

Rev 4
----
 * Fixed swapped input metadata

Rev 5
----
 * Fixed scoping issue with root volume location. Added inputs to enable image clean script

Rev 7
----
 * Added support for optimizing S3 (instance-store) image types.
 * Updated to latest version of AWS tools.
 * New inputs for S3 image support: `IMAGE_TYPE`, `AWS_S3_IMAGE_BUCKET`, `AWS_X509_KEY`, `AWS_X509_CERT`, and `AWS_ACCOUNT_NUMBER`.
 * New advanced input: `KERNEL_ID_OVERRIDE` - Specifies the kernel to use instead of what the VM is running. Example: "aki-fc8f11cc". (See known limitation below).
 * Removed support for running a clean script.
 * Logging for ec2 tool error messages added.
 * Known Limitation: The PVGrub kernels that the S3 RightImages ship with (1.03) do not work for re-bundled partitioned images. There is a newer kernel `pv-grub-hd0_1.04-x86_64` that should be used instead. The kernel ID can be set using the new KERNEL_ID_OVERRIDE input. The IDs are region specific, for a current list of IDs see http://goo.gl/dOS0mB

Rev 8
----
 * Added support for S3 images

Rev 10
----
 * EC2 commands are no longer logged by default. See `IMAGE_OPTIMIZE_DEBUG` for more info.
 * Added workaround for running bundle multiple times

0.1.4.pre
-----
 * Changed default bundle directory from /tmp/bundled to /mnt/ephemeral/bundle.
 * Added `AWS_S3_BUNDLE_DIRECTORY` advanced input to allow the default to be overwritten.

0.1.5.pre
---------
 * Added clean command that will removed RightLink state dirs
 * Added `AWS_S3_BUNDLE_NO_FILTER` advanced input to disable default filtering used by ec2-bundle-vol command. WARNING: setting this option could leave ssh keys or other secrets on your image.

0.1.6.pre
---------
 * fixed rightlink clean command

0.1.7.pre
---------
 * don't clean rightscript attach dir

0.1.8.pre
---------
 * Warn user if they try to run script twice.
 * Added `CLEAN_RIGHTLINK_STATE` input to disable cleaning up rightlink state. If "false" the rightlink state file will not be cleaned up.  This will allow the script to be rerun on the same instance multiple times which is useful for debugging. Boot issues may occur if RightLink state is not properly cleaned up.

0.1.9.pre
---------
  * Fixed intermittent issue where RightLink will not start due to monit PID file existing in new image.
