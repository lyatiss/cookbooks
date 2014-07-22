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

remote_file "/usr/src/master.zip" do
   source "https://github.com/lyatiss/tcp_probe_plus/archive/master.zip"
end

### Important Notes  ###
# set boolean to true if local extraction is necessary.    
# Save the LKM (.ko) file as from the source build system `uname -r`.ko

case node["platform_family"]

when "debian"
  ["unzip", "build-essential", "dkms", "linux-headers-#{kernel}"].each do |p|
     package p do
        action :upgrade
        options "--force-yes -o Dpkg::Options::=\"--force-overwrite\""
     end
  end

####

when "rhel"

  include_recipe 'yum-epel::default'

  ["dkms", "unzip", "wget", "perl", "make", "gcc","kernel-devel" ].each do |p|
     yum_package p do
	action :install
     end
  end

  ruby_block "Prep Build Area" do
     block do
        kernel_source = `ls /usr/src/kernels`
        kernel_source = kernel_source.chomp
	system("rm -f /lib/modules/#{kernel}/build")
	system("ln -s /usr/src/kernels/#{kernel_source} /lib/modules/#{kernel}/build")
     end
   end
end

bash 'extract_module' do
     cwd '/usr/src'
     code <<-EOH
        unzip -o master.zip
     EOH
  end

ruby_block "BUILD LKM" do
   block do
      version = `cat /usr/src/tcp_probe_plus-master/dkms.conf | grep 'PACKAGE_VERSION=' | sed 's/PACKAGE_VERSION="//g' | sed 's/"//g'`
      version = version.chomp
      system( "mv -f /usr/src/tcp_probe_plus-master /usr/src/tcp_probe_plus-#{version}" )
      system( "dkms add -m tcp_probe_plus -v #{version}" )
      system( "dkms build -m tcp_probe_plus --verbose -v #{version}" )
      system( "mkdir", "-p", "/usr/local/lyatiss/probes/kernel" )
      system( "cp", "/var/lib/dkms/tcp_probe_plus/#{version}/#{kernel}/x86_64/module/tcp_probe_plus.ko", "/usr/local/lyatiss/probes/kernel/tcp_probe.ko" )
    end
end
