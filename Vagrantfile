# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
  if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    config.vm.synced_folder ".", "/vagrant", mount_options: ["dmode=700,fmode=600"]
  else
    config.vm.synced_folder ".", "/vagrant"
  end
  config.vm.define "master" do |d|
#    d.vm.box = "bento/centos-7.6"
    d.vm.box = "ubuntu/xenial64"
    d.vm.hostname = "master"
    d.vm.network "private_network", ip: "10.100.192.100"        
    d.vm.provider "virtualbox" do |v|        
      v.memory = 4096
      v.cpus = 1
    end
    d.vm.provision "shell", inline: <<-SHELL
 #          sudo apt-add-repository ppa:ansible/ansible-2.8
 #          sudo apt-get update && sudo apt-get install ansible -y
 #          sudo cp /vagrant/ansible/ansible.cfg /etc/ansible/ansible.cfg
         sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config    
         sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config   
         sudo cp /vagrant/sshd_config  /etc/ssh/sshd_config   
         systemctl restart sshd
      SHELL
#    d.vm.provision :shell, path: "scripts/post-deploy.sh"
    d.vm.provision :shell, path: "scripts/post-deploy-ubuntu.sh"
  end  
  (1..3).each do |i|
    config.vm.define "data-#{i}" do |d|
 #    d.vm.box = "bento/centos-7.6"
 #     d.vm.box = "ubuntu/xenial64"
      d.vm.box = "robert-hadoop-box"
      d.vm.hostname = "data-#{i}"
      d.vm.network "private_network", ip: "10.100.192.10#{i}"
  #    d.vm.provision :shell, inline: "sudo apt-get install -y python"
      d.vm.provider "virtualbox" do |v|
        v.memory = 4096
        v.cpus = 1
      end
      d.vm.provision "shell", inline: <<-SHELL
        sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config    
        sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config    
        sudo cp /vagrant/sshd_config  /etc/ssh/sshd_config   
        systemctl restart sshd
      SHELL
    end
  end
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.synced_folder_opts = {
      owner: "_apt"
    }
  end
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
    config.vbguest.no_install = true
    config.vbguest.no_remote = true
  end
end
