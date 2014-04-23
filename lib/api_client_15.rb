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

require 'right_api_client'
require 'logger'

module RightScale

  # Create an instance facing or user base API client
  class ApiClient15

    def initialize
      @log ||= Logger.new(STDOUT)
      parse_user_data
    end

    def log(logger)
      @log = logger
    end

    def get_client(type, user=nil, password=nil)
      case type
      when :instance
        configure_instance_api_client()
      when :user
        configure_full_api_client(user, password)
      else
        raise "FATAL: ApiClient of #{type} not supported. You must specify either :user or :instance."
      end
    end

    # make connection to API v1.5 with 'instance' role
    def configure_instance_api_client
      options = {
        :account_id => @account_id,
        :instance_token => @instance_token,
        :api_url => @api_url
      }
      instance_client = create_client(options)
      instance_client.log(@log)
      instance_client
    end

    # make connection to RightScale API v1.5 with a specific user's roles
    def configure_full_api_client(user, password)
      options = {:email => user, :password => password, :account_id => @account_id }
      api_client = create_client(options)
      api_client.log(@log)
      api_client
    end

    protected

    def parse_user_data
      begin
        require '/var/spool/cloud/user-data.rb'
      rescue LoadError => e
        puts "FATAL: not a RightScale managed VM, or you already cleaned up your user-data file."
        exit 1
      end

      @api_token = ENV['RS_API_TOKEN']
      raise 'RightScale API token environment variable RS_API_TOKEN is unset' unless @api_token
      @account_id, @instance_token = @api_token.split /:/
      @api_url = "https://#{ENV['RS_SERVER']}"
    end

    def create_client(options)
      RightApi::Client.new options
    end

  end
end