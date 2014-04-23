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
require 'mixins/common'
require 'mixins/command'

# Base class for image utils
#
module ImageOptimize

  class ImageBundleBase

    include ImageOptimize::Common
    include ImageOptimize::Command

    def initialize(instance_api_client, full_api_client)

      @dry_run = false

      @log ||= Logger.new(STDOUT)
      @instance_client = instance_api_client
      unless @instance_client
        @log.error"ERROR: you must pass an instance_api_client parameter."
      end

      @api_client = full_api_client
      unless @api_client
        @log.error"ERROR: you must pass a full_api_client parameter."
      end
    end

    # Captures a "snapshot" of the current VM configuration
    def snapshot_instance(name, description)
      not_implemented
    end

    # Turn the VM "snapshot" into an launchable image
    def register_image(name, description)
      not_implemented
    end

    def add_image_to_next_instance
      # get next instance
      @log.info "Lookup next_instance for the server."
      next_instance = get_instance_parent.show.next_instance

      unless @dry_run
        raise "ERROR: image cannot be nil. Be sure to run register_image method first." unless @image
        # set next instance to use our cached image
        @log.info "Update next instance to launch with our new image."
        next_instance.update(:instance => {:image_href => @image.show.href})
      end
    end

    def log(logger)
      @log = logger
    end

    protected

    # Get the resources associated with this instance
    def instance
      @instance ||= @instance_client.get_instance
    end

    def get_id(resource)
      # the id is the last part of thr href path
      resource.href.split('/').last
    end

    def fail(message="unspecified error occured", exception=nil)
      if exception
        @log.debug "Exception: #{exception.message}"
        @log.debug exception.backtrace.inspect
      end
      @log.error "FATAL: #{message}"
      exit 1
    end

    # Get the parent for this instance
    #
    # The parent may be a Server or ServerArray reosurce.
    #
    # XXX: we can't get to the server resource from the instance facing API
    #      the server resource holds the reference to the next instance.
    #      To deal with this we create an instance resource using the user
    #      authenticated @api_client, then grab it's "parent".
    #
    # == Returns:
    # @return [RightApi::Resource] server a server API resource
    def get_instance_parent
      @log.info "Lookup RightScale server for this instance."
      api_cloud = @api_client.clouds(:id => get_id(instance.cloud))
      api_instance = api_cloud.show.instances.index(:id => get_id(instance))
      api_instance.show.parent
    end

    def debug_mode?
      @log.level == Logger::DEBUG
    end

  end

end