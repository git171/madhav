#
# Cookbook Name:: manage_aws
# Recipe:: default



default['aws']['aws_sdk_version'] = '~> 2.2'
default['aws']['databag_name'] = nil
default['aws']['databag_entry'] = nil
default['aws']['region'] = nil
default['ec2_instance_tags']=[]