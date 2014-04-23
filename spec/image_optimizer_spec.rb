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

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'app', 'image_optimizer'))

describe ImageOptimize::Optimizer, "Image Bundle Controller" do

  before(:each) do
    # dont log stuff
    Logger.any_instance.stub(:info)
    Logger.any_instance.stub(:error)
    Logger.any_instance.stub(:debug)
  end

  it "requires aws_secret_key specified" do
    ARGV.replace [
      '--aws-access-key',"awsaccesskey",
      '--aws-secret-key',"awssecretkey",
      '--api-user',"someone@rightscale.com",
      '--api-password',"supersecret",
      '--aws-account-number',"8675309",

      '--aws-image-type','S3',
      '--aws-s3-bundle-directory', "/mnt/ephemeral/foo",
      '--aws-s3-key-path', "/tmp/key/path",
      '--aws-s3-cert-path', "/tmp/cert/path",
      '--aws-s3-image-bucket', "myimagebucket.example.com",
      '--aws-s3-bundle-no-filter'
    ]
    api_stub = double("ApiClient15", :log => nil, :get_client => nil)
    bundler_stub = double("Bundler", :log => nil)
    RightScale::ApiClient15.should_receive(:new).and_return(api_stub)
    ImageOptimize::ImageBundleEc2S3.any_instance.stub(:load_meta_data)
    optimizer = ImageOptimize::Optimizer.new
    optimizer.parse_args
    optimizer.send(:setup_logging)
    lambda{ optimizer.configure }.should_not raise_error
  end

  it "fails if no aws_secret_key is specified" do
    optimizer = ImageOptimize::Optimizer.new
    optimizer.parse_args
    optimizer.send(:setup_logging)
    lambda{ optimizer.configure }.should raise_error
  end

  it "can be created for EC2 EBS" do
    ENV['API_USER_EMAIL']="someone@rightscale.com"
    ENV['API_USER_PASSWORD']="supersecret"
    ENV['AWS_SECRET_KEY']="awssecretkey"
    ENV['AWS_ACCESS_KEY']="awsaccesskey"
    @aws_s3_bundle_no_filter = true

    api_stub = double("ApiClient15", :log => nil, :get_client => nil)
    bundler_stub = double("Bundler", :log => nil)
    RightScale::ApiClient15.should_receive(:new).and_return(api_stub)
    ImageOptimize::ImageBundleEc2EBS.should_receive(:new).and_return(bundler_stub)
    optimizer = ImageOptimize::Optimizer.new
    optimizer.parse_args
    optimizer.send(:setup_logging)
    optimizer.configure
  end

  it "can be created for EC2 S3" do
    ENV['API_USER_EMAIL']="someone@rightscale.com"
    ENV['API_USER_PASSWORD']="supersecret"
    ENV['AWS_SECRET_KEY']="awssecretkey"
    ENV['AWS_ACCESS_KEY']="awsaccesskey"
    ENV['AWS_ACCOUNT_NUMBER']="1234567890"

    @aws_s3_bundle_no_filter = true

    ARGV.replace [
      '--aws-image-type','S3'
    ]

    api_stub = double("ApiClient15", :log => nil, :get_client => nil)
    RightScale::ApiClient15.should_receive(:new).and_return(api_stub)
    ImageOptimize::ImageBundleEc2S3.any_instance.stub(:load_meta_data)
    io = ImageOptimize::Optimizer.new
    io.parse_args
    io.send(:setup_logging)
    io.configure

    ib = io.instance_variable_get(:@image_util)
  end

  it "parses command-line parameters" do
    ENV['API_USER_EMAIL']="someone@rightscale.com"
    ENV['API_USER_PASSWORD']="supersecret"
    ENV['AWS_SECRET_KEY']="awssecretkey"
    ENV['AWS_ACCESS_KEY']="awsaccesskey"
    ENV['AWS_ACCOUNT_NUMBER']="1234567890"
    @aws_s3_image_bucket="deleteme"
    key_path="foo"
    cert_path="bar"
    image_type = "EBS"
    aws_s3_bundle_directory = "/mnt/ephemeral/foo"
    @aws_s3_bundle_no_filter = true

    image_type = "S3"

    ARGV.replace [
      '--aws-image-type', image_type,
      '--aws-s3-bundle-directory',aws_s3_bundle_directory,
      '--aws-s3-key-path', key_path,
      '--aws-s3-cert-path', cert_path,
      '--aws-s3-image-bucket', @aws_s3_image_bucket,
      '--aws-s3-bundle-no-filter'
    ]
    optimizer = ImageOptimize::Optimizer.new
    args = optimizer.parse_args
    args[:api_user].should == ENV['API_USER_EMAIL']
    args[:api_password].should == ENV['API_USER_PASSWORD']
    args[:aws_secret_key].should == ENV['AWS_SECRET_KEY']
    args[:aws_access_key].should == ENV['AWS_ACCESS_KEY']
    args[:aws_account_number].should == ENV['AWS_ACCOUNT_NUMBER']
    args[:aws_s3_image_bucket].should == @aws_s3_image_bucket
    args[:aws_image_type].should == image_type
    args[:aws_s3_bundle_directory].should == aws_s3_bundle_directory
    args[:aws_s3_bundle_no_filter].should == @aws_s3_bundle_no_filter
    args[:aws_s3_key_path].should == key_path
    args[:aws_s3_cert_path].should == cert_path
  end

  it "processes the run command without errors" do
    ENV['API_USER_EMAIL']="someone@rightscale.com"
    ENV['API_USER_PASSWORD']="supersecret"
    ENV['AWS_SECRET_KEY']="awssecretkey"
    ENV['AWS_ACCESS_KEY']="awsaccesskey"
    ENV['AWS_ACCOUNT_NUMBER']="1234567890"

    aws_s3_image_bucket = "deleteme"
    key_path="foo"
    cert_path="bar"
    image_type = "S3"
    aws_s3_bundle_directory = "/mnt/ephemeral/foo"
    @aws_s3_bundle_no_filter = true

    ARGV.replace [
      '--aws-image-type', image_type,
      '--aws-s3-bundle-directory', aws_s3_bundle_directory,
      '--aws-s3-key-path', key_path,
      '--aws-s3-cert-path', cert_path,
      '--aws-s3-image-bucket', aws_s3_image_bucket,
      '--aws-s3-bundle-no-filter',
      '--no-cleanup'
    ]

    # mock some stuff
    api_stub = double("ApiClient15", :log => nil, :get_client => nil)#right_api_client_stub)
    RightScale::ApiClient15.should_receive(:new).and_return(api_stub)
    ImageOptimize::ImageBundleEc2S3.any_instance.stub(:load_meta_data)
    ImageOptimize::ImageBundleEc2S3.any_instance.stub(:snapshot_instance)
    ImageOptimize::ImageBundleEc2S3.any_instance.stub(:register_image)
    ImageOptimize::ImageBundleEc2S3.any_instance.stub(:add_image_to_next_instance)

    # run some stuff
    optimizer = ImageOptimize::Optimizer.new
    optimizer.should_receive(:prepare_image).at_most(0).times
    optimizer.should_receive(:unique_name)
    optimizer.run

    # check argument parsing
    args =  optimizer.instance_variable_get(:@args)
    args[:api_user].should == ENV['API_USER_EMAIL']
    args[:api_password].should == ENV['API_USER_PASSWORD']
    args[:aws_secret_key].should == ENV['AWS_SECRET_KEY']
    args[:aws_access_key].should == ENV['AWS_ACCESS_KEY']
    args[:aws_account_number].should == ENV['AWS_ACCOUNT_NUMBER']
    args[:aws_s3_image_bucket].should == aws_s3_image_bucket
    args[:aws_image_type].should == image_type
    args[:aws_s3_bundle_directory].should == aws_s3_bundle_directory
    args[:aws_s3_bundle_no_filter].should == @aws_s3_bundle_no_filter
    args[:aws_s3_key_path].should == key_path
    args[:aws_s3_cert_path].should == cert_path

  end


end