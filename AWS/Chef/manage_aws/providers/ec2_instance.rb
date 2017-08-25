#
# Cookbook Name:: manage_aws
# Provider:: ec2_instance


include OpsChef::Aws::Ec2
# require 'aws-sdk'

# get details of aws ec2 instances
action :get_metadata do
  inst= ec2.describe_instances(filters:[{ name: 'tag:Name', values: ["#{new_resource.tag_name}"]}])

  inst.reservations.each do |resrv|
    if(resrv.instances.first.state.name != "terminated")
      reservation = {}
      reservation["instance_id"] = resrv.instances.first.instance_id
      reservation["volume_id"] = resrv.instances.first.block_device_mappings.map{|vol| vol.ebs.volume_id}
      reservation["private_ip_address"] = resrv.instances.first.private_ip_address
      reservation["tag_name"] = new_resource.tag_name
      new_resource.params_ids << reservation
    end
  end
end

# stop aws ec2 instances
action :stop do

  inst_ids = new_resource.params_ids.map{|inst|inst['instance_id']}

  if(!inst_ids.empty?) 
    resp = ec2.stop_instances({
      instance_ids: inst_ids,
      force: true,
    })

    Chef::Log.info("Stoping instances..")

    while !inst_ids.empty?

      inst_ids.each do |instance|

        # get instance state
        state = get_instance_state(instance)

        # wait for instance stop
        while state != "stopped"
          state = get_instance_state(instance)
          Chef::Log.info("Stoping Instance ID: #{instance} State: #{state}..")
          sleep 5
        end
        Chef::Log.info("Instance ID: #{instance} State: #{state}..")
        inst_ids.delete(instance)
      end
    end
  end
end

# terminates aws ec2 instances
action :terminate do

  inst_ids = new_resource.params_ids.map{|inst|inst['instance_id']}
  if(!inst_ids.empty?) 
    resp = ec2.terminate_instances({
      instance_ids: inst_ids, # required
    })
    Chef::Log.info("Terminating instances #{inst_ids}")
  end
end

# detach aws ec2 instance
action :detach_volume do

  new_resource.params_ids.each do |inst|
    
    inst['volume_id'].each do |vol|
      
      # pre state check for volume 
      state_resp = ec2.describe_volumes({
        volume_ids: ["#{vol}"]
      })

      state = state_resp.volumes[0].attachments[0].state
      
      Chef::Log.info("Instance ID:#{inst['instance_id']}, Volume ID: #{vol}, Volume State: #{state}")

      if(state != "detached")
        
        resp = ec2.detach_volume({
          volume_id: "#{vol}", # required
          instance_id: "#{inst['instance_id']}",
          force: true,
        })
      end
      
      Chef::Log.info("Detaching Volume ID: #{vol} from Instance ID: #{inst['instance_id']}")
    end
  end
end

# get instance state
def get_instance_state(instance_id)
  inst_state = ec2.describe_instance_status({
    instance_ids: ["#{instance_id}"],
    include_all_instances: true,
  })
  inst_state.instance_statuses[0].instance_state.name
end
