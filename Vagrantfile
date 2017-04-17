# -*- mode: ruby -*-
# vi: set ft=ruby :

$basic_config = <<SCRIPT
yum update -y
yum install -y java-1.8.0-openjdk unzip net-tools vim
useradd -s /bin/bash -d /home/wildfly wildfly
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.base_mac = "5254008815b6"

  # Single machine definition for standalone testing
  #config.vm.box = "centos/7"
  #config.vm.synced_folder ".", "/vagrant"
  #config.vm.network "public_network"
  #config.vm.provision "shell", inline: $basic_config
  #config.vm.hostname = "standalone.vagrant.box"

  # Multi-machine definition for Domain master / slave testing
  config.vm.define "master" do |master|
    master.vm.box = "centos/7"
    master.vm.synced_folder ".", "/vagrant"
    master.vm.hostname = "master.vagrant.box"
    master.vm.network "private_network", type: "dhcp"
    master.vm.provision "shell", inline: $basic_config
  end

  config.vm.define "slave" do |slave|
    slave.vm.box = "centos/7"
    slave.vm.synced_folder ".", "/vagrant"
    slave.vm.hostname = "slave.vagrant.box"
    slave.vm.network "private_network", type: "dhcp"
    slave.vm.provision "shell", inline: $basic_config
  end

end
