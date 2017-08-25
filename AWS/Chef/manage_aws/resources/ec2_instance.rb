#
# Cookbook Name:: manage_aws
# Resource:: ec2_instance


actions :get_metadata, :stop, :detach_volume, :terminate
default_action :get_metadata

attribute :instance_id, :kind_of => String 
attribute :volume_id, :kind_of => Array 
attribute :tag_name, :kind_of => String 
attribute :private_ip, :kind_of => String 
attribute :params_ids, :kind_of => Array
attribute :creds, :kind_of => Hash
