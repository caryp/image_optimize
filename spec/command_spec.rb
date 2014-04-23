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

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'mixins', 'command'))

describe ImageOptimize::Command do

  class TestObj
    include ImageOptimize::Command
    def initialize
      @log = Logger.new(STDOUT)
    end
  end

  before(:each) do
    Logger.any_instance.stub(:debug)
  end

  it "runs a child process" do
    return_val, output = TestObj.new.execute("ls -l", true)
    return_val.exitstatus.should == 0
  end

  it "logs debug message" do
    Logger.any_instance.stub(:debug)
    obj = TestObj.new
    obj.debug("hey now")
  end

end