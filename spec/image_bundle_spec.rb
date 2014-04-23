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

describe ImageOptimize::ImageBundleBase, "Image Bundle Utilities" do

  describe "Base Class" do
    it "can be created" do
      ImageOptimize::ImageBundleBase.new("instance_client", "api_client")
    end
  end

  describe "EC2 EBS Implementation" do
    let(:instance_client) { double("instance_client") }
    let(:api_client) { double("api_client") }

    it "initializes" do
      ImageOptimize::ImageBundleEc2EBS.any_instance.stub(:load_meta_data)
      ib = ImageOptimize::ImageBundleEc2EBS.new(
        "instance_client",
        "api_client",
        "aws_access_key",
        "aws_secret_key"
      )
      ib.should_not == nil
    end
  end

  describe "EC2 S3 Implementation" do
    let(:instance_client) { double("instance_client") }
    let(:api_client) { double("api_client") }

    it "initializes" do
      ImageOptimize::ImageBundleEc2S3.any_instance.stub(:load_meta_data)
      ib = ImageOptimize::ImageBundleEc2S3.new(
        "instance_client",
        "api_client",
        "aws_access_key",
        "aws_secret_key",
        "aws_account_number",
        "x509_key_file",
        "x509_cert_file",
        "s3_bucket"
      )
      ib.instance_variable_get(:@bundle_dir).should == "/mnt/ephemeral/bundle" # default value
      ib.instance_variable_get(:@no_filter).should == nil
    end

    it "initializes with bundle dir" do
      ImageOptimize::ImageBundleEc2S3.any_instance.stub(:load_meta_data)
      ib = ImageOptimize::ImageBundleEc2S3.new(
        "instance_client",
        "api_client",
        "aws_access_key",
        "aws_secret_key",
        "aws_account_number",
        "x509_key_file",
        "x509_cert_file",
        "s3_bucket",
        "/mnt/ephemeral"
      )
      ib.instance_variable_get(:@bundle_dir).should == "/mnt/ephemeral"
    end

    it "initializes with no-filter option" do
      ImageOptimize::ImageBundleEc2S3.any_instance.stub(:load_meta_data)
      ib = ImageOptimize::ImageBundleEc2S3.new(
        "instance_client",
        "api_client",
        "aws_access_key",
        "aws_secret_key",
        "aws_account_number",
        "x509_key_file",
        "x509_cert_file",
        "s3_bucket",
        "/mnt/ephemeral",
        "true"
      )
      ib.instance_variable_get(:@no_filter).should == true
    end
  end

end
