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

libdir = File.join(File.dirname(__FILE__), '..')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'trollop'
require 'api_client_15'
require 'image_bundle'
require 'mixins/command'

module ImageOptimize

  class Optimizer

    include ImageOptimize::Command

    def run
      parse_args
      setup_logging
      configure

      # "cleaning" should wipe user-data and meta-data which will only allow this script
      # to be run once.  Default to false to so we can run this multiple times to make
      # debugging more efficient.
      # XXX: this probably should be done by the manager class
      prepare_image if @args[:do_cleanup]

      # generate unique image name and description for our image
      name = unique_name(@args[:image_prefix])
      description = @args[:image_description]

      # snapshot and register new image
      @log.info "Snapshot instance..."
      @image_util.snapshot_instance(name, description)
      @log.info "Register image..."
      @image_util.register_image(name, description)
      @log.info "Add image to next instance..."
      @image_util.add_image_to_next_instance
      @log.info "SUCCESS!"
    end

    def configure

      @log.debug("Config Parameters: #{@args}")

      # check for AWS credentials set
      raise 'Environment variable AWS_SECRET_KEY must be set' unless @args[:aws_secret_key]
      raise 'Environment variable AWS_ACCESS_KEY must be set' unless @args[:aws_access_key]

      # XXX: The fact that we're using two API clients should be hidden
      #      inside a RightScale 'manager' class.
      api_helper = RightScale::ApiClient15.new
      api_helper.log(@log)
      @instance_client = api_helper.get_client(:instance)
      @api_client = api_helper.get_client(:user, @args[:api_user], @args[:api_password])

      if @args[:aws_image_type] == "EBS"  # XXX: use an image bundle factory instead of if-else
        @log.debug("Creating ImageBundleEc2EBS object")
        @image_util =
          ImageBundleEc2EBS.new(
            @instance_client,        # XXX: instead of passing two api handles, just pass a manager class
            @api_client,
            @args[:aws_access_key],
            @args[:aws_secret_key],
            @args[:aws_kernel_id]
          )
      else
        @log.debug("Creating ImageBundleEc2S3 object")

        # check for credentials set in environment
        raise 'Environment variable AWS_S3_IMAGE_BUCKET must be set' unless @args[:aws_s3_image_bucket]
        raise 'Environment variable AWS_ACCOUNT_NUMBER must be set' unless @args[:aws_account_number]

        @image_util =
          ImageBundleEc2S3.new(
            @instance_client,
            @api_client,
            @args[:aws_access_key],
            @args[:aws_secret_key],
            @args[:aws_account_number],
            @args[:aws_s3_key_path],
            @args[:aws_s3_cert_path],
            @args[:aws_s3_image_bucket],
            @args[:aws_s3_bundle_directory],
            @args[:aws_s3_bundle_no_filter],
            @args[:aws_kernel_id]
          )
      end

      @image_util.log(@log)

    end

    def parse_args
      version = File.open(File.join(File.dirname(__FILE__), "..", "..","VERSION"), "r") { |f| f.read }

      @args = Trollop::options do
        version "image_optimize #{version} (c) 2014 RightScale, Inc."
        banner <<-EOS

Bundle a running VM into a new image that will be used on next launch

Usage:
       image_optimize [options]
where [options] are:
EOS
        opt :verbose, "If set will enable debug logging.  WARNING: will write ec2 creds to log if set!!",
            :long => "--verbose", :default => false

        opt :image_prefix, "Prefix to add to the optimized image name. Helps when searching for your optimized images.",
             :default => "optimized-image", :long => "--prefix", :type => String
        opt :image_description, "Description to add to optimized images",
           :default => "Cached image", :long => "--description", :type => String

        # Mangement platform API Creds
        opt :api_user, "RightScale Dashboard User email. Not needed if API_USER_EMAIL environment variable is set.",
           :default => ENV['API_USER_EMAIL'], :long => "--api-user", :short => "-u", :type => String
        opt :api_password, "RightScale Dashboard User email. Not needed if API_USER_PASSWORD environment variable is set.",
           :default => ENV['API_USER_PASSWORD'], :long => "--api-password", :short => "-p", :type => String
        opt :do_cleanup, "Don't do any cleanup on VM before snapshotting. Useful for debugging.", :long => "--cleanup", :default => true

        # EC2 Creds
        opt :aws_access_key, "EC2 Account Access Key. Not needed if AWS_ACCESS_KEY environment variable is set.",
           :default => ENV['AWS_ACCESS_KEY'], :long => "--aws-access-key", :short => "-k"
        opt :aws_secret_key, "EC2 Account Secret. Not needed if AWS_SECRET_KEY environment variable is set.",
           :default => ENV['AWS_SECRET_KEY'], :long => "--aws-secret-key", :short => "-s"
        opt :aws_account_number, "EC2 Account ID. Not needed if AWS_ACCOUNT_NUMBER environment variable is set. Required for S3 images only.",
           :default => ENV['AWS_ACCOUNT_NUMBER'], :long => "--aws-account-number"

        # EC2 Image type
        opt :aws_image_type, "The type of image to create from this VM. Must be either 'EBS' or 'S3'. ",
           :default => 'EBS', :long => "--aws-image-type", :type => String
        opt :aws_kernel_id, "Kernel to use instead of what the VM is running. i.e. 'aki-fc8f11cc'. For a current list of IDs see http://goo.gl/dOS0mB.",
           :default => nil, :long => "--aws-kernel-id", :type => String

        # EC2 Instance Store Parameters
        opt :aws_s3_key_path, "location to file containing EC2 account key. S3 images only.",
           :default => '/tmp/certs/x509.key', :long => "--aws-s3-key-path"
        opt :aws_s3_cert_path, "location to file containing EC2 account cert. S3 images only.",
           :default => '/tmp/certs/x509.cert', :long => "--aws-s3-cert-path"
        opt :aws_s3_image_bucket, "The bucket name for optimized S3 images (must be url safe). S3 images only",
           :default => "optimized-images", :long => "--aws-s3-image-bucket"
        opt :aws_s3_bundle_directory, "The local directory where the image bundle will be stored before uploading to S3. NOTE: this must have enough free space to hold the image bundle.",
           :default => "/mnt/ephemeral/bundle", :long => "--aws-s3-bundle-directory"
        opt :aws_s3_bundle_no_filter, "If set, will disable the default filtering used by the ec2-bundle-vol command. WARNING: setting this option could leave ssh keys or other secrets on your",
           :default => false, :long => "--aws-s3-bundle-no-filter"
      end
    end

    private

    # create an image name using prefix and VM name
    #
    # Returns: [String] image name
    def unique_name(prefix)
      image_name = "#{@instance_client.get_instance.name} #{Time.new.to_s}"
      image_name = "#{prefix} #{image_name}" if prefix
      image_name.gsub(/[^0-9A-Za-z.\-]/, '-') # sanitize it!
    end

    # clean image for snapshoting
    # taken from http://cpenniman.blogspot.com/2012/09/cleaning-up-rightimage-before.html
    def prepare_image
      @log.info "Prepare image"
      cmd = "rm -rf /var/spool/cloud /var/lib/rightscale/right_link/*.js ; rm -f /opt/rightscale/var/lib/monit/monit.state ; rm -f /opt/rightscale/var/run/monit.pid ; sync"
      execute(cmd)
    end

    # configure logging
    def setup_logging
      @log = Logger.new(STDOUT)
      @log.level = Logger::INFO
      @log.level = Logger::DEBUG if @args[:verbose]
      @log.formatter = proc do |serverity, time, progname, msg|
        "#{msg}\n"
      end
    end

  end
end