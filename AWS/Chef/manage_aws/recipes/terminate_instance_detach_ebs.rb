#
# Cookbook Name:: manage_aws
# Recipe:: terminate_instance_detach_ebs
#


require 'json'

inst_resources = []
instances = []

tags = node.ec2_instance_tags

# TODO use encrypted databags or chef vault

# % knife data bag show aws main
# {
#   "id": "main",
#   "aws_access_key_id": "YOUR_ACCESS_KEY",
#   "aws_secret_access_key": "YOUR_SECRET_ACCESS_KEY",
#   "aws_session_token": "YOUR_SESSION_TOKEN"
# }

# load databag
# aws = data_bag_item('aws', 'main')

aws_creds = {} # aws

# TODO replace this with databags
aws_creds['aws_access_key'] = ENV['aws_access_key'] || ''
aws_creds['aws_secret_access_key'] = ENV['aws_secret_access_key'] || ''
aws_creds['aws_session_token'] = ENV['aws_session_token'] || nil

# get instance details
tags.each do |tag|
  resource_name = "#{tag}-ec2-instance"
  manage_aws_ec2_instance "#{resource_name}" do
    tag_name tag
    creds aws_creds
    params_ids []
    action :get_metadata
  end
  inst_resources << resource_name
end

# get instances attrs
ruby_block 'get_instances' do
  block do
    inst_resources.each do |instance|
      inst = []
      inst_details =  resources(manage_aws_ec2_instance: "#{instance}")
      inst = inst_details.params_ids
      instances.concat(inst)
    end
  end
end

# stop aws ec2 instances
manage_aws_ec2_instance "stop_aws_ec2_instances" do
  params_ids instances
  creds aws_creds
  action :stop
end

# detach aws ebs volumes
manage_aws_ec2_instance "ebs_detach_volume" do
  params_ids instances
  creds aws_creds
  action :detach_volume
end

# keep volume ids and instance tags details in json file
ruby_block 'save_instance_volume_details' do
  block do
    ::File.open("#{ENV['HOME']}/instance_details.json", "a+") do |f|
      instances.each do |instance|
        f.puts("#{instance.to_json}")
      end
    end
  end
end

# terminate aws ec2 instances
manage_aws_ec2_instance "terminate_aws_ec2_instances" do
  params_ids instances
  creds aws_creds
  action :terminate
end
