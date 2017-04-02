# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.hostname = "vagrant1.mustin.box"
  config.vm.provision "shell", inline: <<-SHELL
    yum update -y
  SHELL
end
