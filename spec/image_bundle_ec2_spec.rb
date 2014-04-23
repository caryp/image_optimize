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

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'image_bundle'))

describe ImageOptimize::ImageBundleEc2Base do

  before(:each) do
    # dont log stuff
    Logger.any_instance.stub(:info)
    Logger.any_instance.stub(:debug)

    ImageOptimize::ImageBundleEc2Base.any_instance.stub(:load_meta_data)
    @image_bundler = ImageOptimize::ImageBundleEc2Base.new(
      "instance_client",
      "api_client",
      "aws_access_key",
      "aws_secret_key"
    )
  end

  # skip this test on a cloud instance -- since there is a metadata file
  it "fails if metadata not found" do
    unless File.exists?('/var/spool/cloud/meta-data-cache.rb')
      lambda{ImageOptimize::ImageBundleEc2Base.new("instance_client", "api_client")}.should raise_error
    end
  end

  it "registers image" do
    @image_bundler.should_receive(:register_command)
    status = double("ProcessStatus", :exitstatus => 0)
    @image_bundler.should_receive(:execute).and_return([status, "Using AWS acces key \n IMAGE ami-64b5c054 "])
    @image_bundler.should_receive(:wait_for_image)
    @image_bundler.register_image("name", "description")
  end

  it "parsed ami" do
    ami = "ami-64b5c054"
    fake_output = "Using AWS acces key \n IMAGE #{ami} "
    @image_bundler.send(:parse_ami, fake_output).should == ami
  end

  it "raise excaption on failure" do
    @image_bundler.should_receive(:register_command)
    status = double("ProcessStatus", :exitstatus => 1)
    lambda{@image_bundler.register_image("name", "description")}.should raise_error
  end

  it "returns true if using a debug log level" do
    @image_bundler.send(:debug_mode?).should == true
  end

  it "returns false if not using a debug log level" do
    log = Logger.new(STDOUT)
    log.level = Logger::INFO
    @image_bundler.log(log)
    @image_bundler.send(:debug_mode?).should == false
  end

   # def register_image(name=nil, description=nil)
   #    cmd = register_command(name, description)
   #    @log.info "Running register image command..."
   #    unless @dry_run
   #      status, cmd_output = execute(cmd)
   #      raise "FATAL: unable to register new image" unless status.exitstatus == 0
   #      image_uuid = cmd_output.sub("IMAGE","").strip
   #      @log.info "New image: #{image_uuid}"
   #
   #      # wait for image to be available
   #      wait_for_image(image_uuid)
   #    end
   #  end

end
