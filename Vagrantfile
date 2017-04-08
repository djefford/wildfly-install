# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.base_mac = "5254001fdbb7"
  config.vm.box = "centos/7"
  config.vm.hostname = "vagrant1.mustin.box"
  config.vm.synced_folder ".", "/vagrant"
  config.vm.network "public_network"
  config.vm.provision "shell", inline: <<-SHELL
    yum update -y
    yum install -y java-1.8.0-openjdk unzip net-tools
    useradd -s /bin/bash -d /home/wildfly wildfly
  SHELL
end
