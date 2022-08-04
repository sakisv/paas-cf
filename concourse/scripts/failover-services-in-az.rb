#!/usr/bin/env ruby

require 'ipaddr'
require 'json'
require 'resolv'

def get_vpc_id(deploy_env)
  %x{
    aws ec2 describe-vpcs \
      --filters 'Name=tag:Name,Values=#{deploy_env}' \
      --query 'Vpcs[].VpcId' \
      --output text
  }.strip || raise("VPC for DEPLOY_ENV #{deploy_env} not found")
end

class VpcSubnetsCache < ::Hash
  include Singleton
end

def get_vpc_subnets(vpc_id)
  VpcSubnetsCache.instance[vpc_id] ||= JSON.parse(%x{
    aws ec2 describe-subnets \
      --filters 'Name=vpc-id,Values=#{vpc_id}' \
      --output json
  })["Subnets"]
end

def get_az_from_ip(vpc_id, ip_str)
  ip_ipaddr = IPAddr.new ip_str

  (get_vpc_subnets(vpc_id).find(proc {raise("unknown subnet for ip #{ip_str}")}) do |subnet|
    subnet_ipaddr = IPAddr.new subnet["CidrBlock"]
    subnet_ipaddr.include? ip_ipaddr
  end)["AvailabilityZone"][-1].downcase
end

def get_db_instance(db_instance_identifier)
  db_instances = JSON.parse(%x{
    aws rds describe-db-instances \
      --db-instance-identifier '#{db_instance_identifier}' \
      --output json
  })["DBInstances"]
  raise("DB instance #{db_instance_identifier} not found") if db_instances.length == 0
  raise if db_instances.length != 1
  db_instances[0]
end

def get_db_instance_az(db_instance)
  resolver = Resolv::DNS.new
  ips = resolver.get_addresses(db_instance["Endpoint"]["Address"])
  raise("Expected to find 1 IP address for #{db_instance["Endpoint"]["Address"]}, got #{ips}") if ips.length != 1

  get_az_from_ip(db_instance["DBSubnetGroup"]["VpcId"], ips[0].address)
end

def failover_rds_db_instances_in_az(deploy_env, az)
  az = az.downcase
  raise("Expected az to be a, b or c") unless az =~ /^[abc]$/

  vpc_id = get_vpc_id(deploy_env)

  JSON.parse(%x{
    aws rds describe-db-instances \
      --output json
  })["DBInstances"].each do |db_instance|
    next if db_instance["DBSubnetGroup"]["VpcId"] != vpc_id

    updated_db_instance = get_db_instance(db_instance["DBInstanceIdentifier"])

    next if updated_db_instance["DBInstanceStatus"] != "available"
    next if get_db_instance_az(updated_db_instance) != az

    puts "Doing reboot-with-failover for #{updated_db_instance["DBInstanceIdentifier"]}"
  end
end

if $PROGRAM_NAME == __FILE__
  deploy_env = ENV["DEPLOY_ENV"] || raise("Must set $DEPLOY_ENV env var")
fi
