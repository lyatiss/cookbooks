#
# Cookbook Name:: Cloudweaver
# Recipe:: default
#
# Copyright 2014, Cloudweaver
#
# All rights reserved - Do Not Redistribute
#

kernel = `uname -r`
kernel = kernel.chomp

### Important Notes  ###
# set boolean to true if local extraction is necessary in attributes or as a node override
# Save the LKM (.ko) file as from the source build system `uname -r`.ko

local_extraction = node['local_extraction']

## Set boolean to true to bypass Lyatiss and Local repository and simply build the LKM from source..  Please adjust in attributes or use an override
## Usual Warning about build environments along with production.
## Use at your own risk

create_lkm = node['create_lkm']

case node["platform_family"]

when "debian"
  apt_repository "lyatiss" do
    uri "http://repository.us-west-1.cloudweaverdiscovery.com"
    components ["aws debian"]
    keyserver "keyserver.ubuntu.com"
    key "41736DEB"
  end

  ["lyatiss-collector-common-non-interactive", "lyatiss-collectd-probes-non-interactive", "lyatiss-collector-cw-non-interactive"].each do |p|
     package p do
        action :upgrade
        options "--force-yes -o Dpkg::Options::=\"--force-overwrite\""
     end
   end

  template "/etc/lyatiss/lyatiss_default" do
    source "lyatiss_default.erb"
    owner  "root"
    group  "root"
  end

  template "/etc/lyatiss/lyatiss_stomp" do
    source "lyatiss_stomp.erb"
    owner  "root"
    group  "root"
  end

  if "#{create_lkm}" == "1"
      include_recipe 'cloudweaver::buildlkm'
  else 
      if "#{local_extraction}" == "0"
          execute "LKM install#{kernel}" do
             command "apt-get upgrade lyatiss-lkm-#{kernel}"
          end
      else 
          directory "/usr/local/lyatiss/probes/kernel" do
             mode 00775
             owner "root"
             group "root"
             action :create
             recursive true
          end
          cookbook_file "/usr/local/lyatiss/probes/kernel/tcp_probe.ko" do
             action  :create
             source  "lyatiss-lkm-#{kernel}.ko"
             owner   "root"
             group   "root"
             mode    "0666"
          end
       end
   end
   service "lyatiss-cw-collector" do
     action :start
   end
####

when "rhel"

  include_recipe 'yum-epel::default'

  yum_repository 'lyatiss-cloudweaver' do
    description 'lyatiss-cloudweaver'
    sslverify false
    baseurl "http://repository.us-west-1.cloudweaverdiscovery.com/repository/dists/aws/rpm"
    gpgkey "http://repository.us-west-1.cloudweaverdiscovery.com/repository/keys/aws.pubkey.asc"
    action :create
  end

   ["gcc", "python", "python-pip", "python-devel"].each do |p|
     package p do
       action :upgrade
     end
   end	

   python_pip "restkit" do
      action :install
   end

  ["lyatiss-collector-cw-non-interactive", "lyatiss-collector-common-non-interactive", "lyatiss-collectd-probes-non-interactive"].each do |p|
     package p do
       action :upgrade
     end
  end

  template "/etc/lyatiss/lyatiss_default" do
    source "centos_lyatiss_default.erb"
    owner  "root"
    group  "root"
  end

  template "/etc/lyatiss/lyatiss_stomp" do
    source "lyatiss_stomp.erb"
    owner  "root"
    group  "root"
  end

  if "#{create_lkm}" == "1"
      include_recipe 'cloudweaver::buildlkm'
  else
      if "#{local_extraction}" == "0"
         execute "LKM install#{kernel}" do
            command "yum -y install lyatiss-lkm-#{kernel}"
         end
      else
         directory "/usr/local/lyatiss/probes/kernel" do
           mode 00775
           owner "root"
           group "root"
           action :create
           recursive true
         end
         cookbook_file "/usr/local/lyatiss/probes/kernel/tcp_probe.ko" do
           action  :create
           source  "lyatiss-lkm-#{kernel}.ko"
           owner   "root"
           group   "root"
           mode    "0666"
        end
     end
  end
  service "lyatiss-cw-collector" do
    action :start
  end
end
