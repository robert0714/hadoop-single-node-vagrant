# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "hadoop-single-node"
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"
  
  # Let make-single-node.sh provision the environment during 'vagrant up' or 'vragrant 
  # provision'
  config.vm.provision :shell, :path => "make-single-node.sh"
  
  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.33.10"

  # You can fiddle with these settings, however, insufficient resources might result in 
  # timeouts during MapReduce jobs.
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, 
      "--cpus", "2",
      "--memory", "4096",
      "--cpuexecutioncap", "50"
    ]
  end

  #https://coderwall.com/p/uaohzg
  config.vm.synced_folder ".", "/vagrant", :nfs => true


end
