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

require 'image_bundle/image_bundle_ec2'

module ImageOptimize

  # Handles the snapshoting and registration of EBS based images
  #
  class ImageBundleEc2S3 < ImageBundleEc2Base

    BUNDLE_DIR = "/mnt/ephemeral/bundle"

    # x509_key_file : [String] Absolute path to file holding AWS x.509 private key file
    # x509_cert_file : [String] Absolute path to file holding AWS x.509 certificate file
    # s3_bucket : [String] place to store image in S3
    #
    def initialize(instance_api_client, full_api_client, aws_access_key, aws_secret_key, aws_account_number, x509_key_file, x509_cert_file,  s3_bucket, bundle_dir=nil, no_filter=nil, kernel_id = nil)
      super(instance_api_client, full_api_client, aws_access_key, aws_secret_key, kernel_id)
      @aws_account_number = aws_account_number
      raise "no aws account number specified." unless @aws_account_number
      @key_file = x509_key_file
      raise "no path to x.509 private key file specified." unless @key_file
      @cert_file = x509_cert_file
      raise "no path to x.509 certificate file specified." unless @cert_file

      @bucket = s3_bucket

      # Where to place temporary image bundle before upload
      @bundle_dir = bundle_dir
      @bundle_dir ||= BUNDLE_DIR

      # --no-filter
      @no_filter = true if no_filter
    end

    # Captures a "snapshot" of the current VM configuration
    def snapshot_instance(name, description)
      bundle_image(name)
      upload_bundle(name)
      cleanup_bundle
    end

    # Turn the VM "snapshot" into an launchable image
    def register_command(name, description)
      #ec2-register my-s3-bucket/image_bundles/name/image.manifest.xml -n name -O your_access_key_id -W your_secret_access_key
      cmd = "ec2-register #{@bucket}/image_bundles/#{name}/image.manifest.xml -n #{name} -O #{@aws_access_key} -W #{@aws_secret_key} --region #{region} --architecture x86_64 --description '#{description}' #{common_options}"
      cmd
    end

    private

    def upload_bundle(name)
       @log.info "Running bundle upload command..."
       cmd = "ec2-upload-bundle -b #{@bucket}/image_bundles/#{name} -m '#{@bundle_dir}/image.manifest.xml' -a #{@aws_access_key} -s #{@aws_secret_key} --retry --batch --region #{region} #{common_options}"
       unless @dry_run
         status, cmd_output = execute(cmd)
         fail "FATAL: unable to upload S3 image bundle" unless status.exitstatus == 0
       end
    end

    def bundle_image(name)
      @log.info "Using #{@bundle_dir} locally to store image bundle."
      @log.info "Running EC2 Bundle command..."
      FileUtils.rm_rf(@bundle_dir)
      FileUtils.mkdir_p(@bundle_dir)
      cmd="ec2-bundle-vol --privatekey #{@key_file} --cert #{@cert_file} --user #{@aws_account_number} --destination #{@bundle_dir} --arch x86_64 --kernel #{kernel_aki} -B 'ami=sda,root=/dev/sda,ephemeral0=sdb,swap=sda3' #{excludes} --no-inherit #{common_options}"
      cmd << " --no-filter" if @no_filter
      unless @dry_run
        status, cmd_output = execute(cmd)
        fail "FATAL: unable to bundle new image" unless status.exitstatus == 0
      end
    end

    # What directories should be excluded from bundle
    # NOTE: be sure to exclude the directory containing the key_file and cert_file x.509 creds
    #
    def excludes
      excludes = ""
      [ File.dirname(@key_file), File.dirname(@cert_file), "/mnt", @bundle_dir ].uniq.each do |dir|
        excludes += "--exclude #{dir} "
      end
      excludes
    end

    # remove bundle directory
    #
    def cleanup_bundle
      FileUtils.rm_rf(@bundle_dir)
    end

    def s3_url(region)
      if region == "us-east-1"
        "https://s3.amazonaws.com"
      else
        "https://s3-#{region}.amazonaws.com"
      end
    end

  end
end