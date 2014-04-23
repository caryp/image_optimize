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

describe "Image Optimize Functional Test" do

  # you must own this bucket
  # do to a known issue in the EC2 tools, the bucket must already exist
  S3_BUCKET_NAME = "cp2-pub-cached-images"

  before(:all) do
    #XXX: this should to be detected from VM, but simply set in env before running the test
    # ENV['IMAGE_TYPE'] = 'S3'
    ec2_zone = `curl http://169.254.169.254/latest/meta-data/placement/availability-zone/`
    @region =  /(.*\-.*\-[1-9]*)/.match(ec2_zone).captures.first
    puts "Detected EC2 region #{@region}"
  end

  it "creates an instance facing api connection" do
    cwd = File.dirname(__FILE__)
    secrets_dir = "#{cwd}/../.secrets"

    command = ". #{secrets_dir}/creds; bin/image_optimize --aws-image-type #{ENV['IMAGE_TYPE']} --aws-s3-image-bucket #{S3_BUCKET_NAME} --aws-s3-key-path #{secrets_dir}/x509.key --aws-s3-cert-path #{secrets_dir}/x509.cert --aws-s3-bundle-directory /mnt/ephemeral/bundle --verbose --no-cleanup"

    puts "COMMAND: #{command}"
    output = ""
    IO.popen("#{command} 2>&1") do |data|
      while line = data.gets
        puts "\e[33m#{line}\e[0m" # 33 = yellow text
        output << line
      end
    end
    process_status = $?
    puts "OUTPUT: #{output}"
    process_status.exitstatus.should == 0
  end

end