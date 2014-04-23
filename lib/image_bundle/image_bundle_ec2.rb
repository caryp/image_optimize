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

module ImageOptimize

  # Base class for snapshoting and registration of EC2 images
  #
  class ImageBundleEc2Base < ImageBundleBase

    RETRY_TIMEOUT_SEC = 2 * 60 * 60 # 2 hr

    def initialize(instance_api_client, full_api_client, aws_access_key, aws_secret_key, kernel_id_override = nil)
      load_meta_data
      @aws_access_key = aws_access_key
      @aws_secret_key = aws_secret_key
      @kernel_override = kernel_id_override
      super(instance_api_client, full_api_client)
    end

    def register_image(name=nil, description=nil)
      cmd = register_command(name, description)
      @log.info "Running register image command..."
      unless @dry_run
        status, cmd_output = execute(cmd)
        raise "FATAL: unable to register new image" unless status.exitstatus == 0
        image_uuid = parse_ami(cmd_output)
        @log.info "New image: #{image_uuid}"

        # wait for image to be available
        wait_for_image(image_uuid)
      end
    end

    protected

    def parse_ami(command_output)
      /(ami-[a-z0-9]+)/.match(command_output).captures[0]
    end

    def register_command(name, description)
      raise "Not implemented"
    end

    def wait_for_image(image_uuid)
      # wait for image to be available
      @log.info "Query for the new image"
      start = Time.now
      @image = get_image(image_uuid)
      delay_sec = 10
      Timeout::timeout(RETRY_TIMEOUT_SEC) do
        while @image == nil do
          @log.info "  Image #{image_uuid} not yet available. Checking again in #{delay_sec} seconds..."
          sleep delay_sec
          @image = get_image(image_uuid)
        end
      end
      total = Time.new - start
      @log.info "Total time waited: #{total}"
    end

    def get_image(uuid)
      # use full api client to look for image
      image = get_cloud.show.images.index(:filter => [ "resource_uid==#{uuid}" ]).first
      @log.info "Found image #{uuid} named '#{image.name}'" if image
      image
    end

    # Get the cloud for this instance
    #
    # XXX: we cannot query cloud image via instance API
    #
    # == Returns:
    # @return [RightApi::Resource] server a server API resource
    def get_cloud
      cloud_href = instance.cloud.href
      cloud_id = cloud_href.split('/').last
      cloud = @api_client.clouds(:id => cloud_id)
    end

    # detect EC2 region from EC2 metadata
    #
    def region
      ec2_zone = ENV['EC2_PLACEMENT_AVAILABILITY_ZONE'] # ec2_zone = `curl http://169.254.169.254/latest/meta-data/placement/availability-zone/`
      unless ec2_zone
        fail("The EC2_PLACEMENT_AVAILABILITY_ZONE environment variable is not defined. Did you load EC2 metadata?")
      end
      region =  /(.*\-.*\-[1-9]*)/.match(ec2_zone).captures.first
      @log.info "detected current region is #{region}"
      region
    end

    # detect kernel from EC2 metadata
    #
    def kernel_aki
      kernel = @kernel_override         # allow user to override
      kernel ||= ENV['EC2_KERNEL_ID']   # use same kernel as VM is running
    end

    private

    def load_meta_data
      begin
        require '/var/spool/cloud/meta-data-cache.rb'
      rescue LoadError => e
        puts "FATAL: not a RightScale managed VM, or you already cleaned up your meta-data file."
        exit 1
      end
    end

    def common_options
      options = ""
      options << "--debug " if debug_mode?
    end


  end

end