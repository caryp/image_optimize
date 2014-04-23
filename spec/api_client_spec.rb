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

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'api_client_15'))

describe "API 1.5 Client Creator" do

  before(:each) do
    RightScale::ApiClient15.any_instance.stub(:parse_user_data)
    apiStub = double("RightApi::Client", :log => true)
    RightApi::Client.should_receive(:new).and_return(apiStub)
  end

  it "creates an instance facing api connection" do
    helper = RightScale::ApiClient15.new
    helper.get_client(:instance)
  end

  it "creates an user api connection" do
    ENV['API_USER_EMAIL'] = "somebody"
    ENV['API_USER_PASSWORD'] = "somepassword"
    helper = RightScale::ApiClient15.new
    helper.get_client(:user)
  end

end