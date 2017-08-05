# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.base_mac = "525400ada096"

  # Server 1 definition
  config.vm.define "server1" do |s1|
    s1.vm.box = "centos/7"
    s1.vm.synced_folder ".", "/vagrant", type: "rsync"
    s1.vm.hostname = "server1.vagrant.box"
    s1.vm.network "private_network", type: "dhcp"
    s1.vm.provision :shell, path: "bootstrap.sh"
  end

  # Server 2 definition
  config.vm.define "server2" do |s2|
    s2.vm.box = "centos/7"
    s2.vm.synced_folder ".", "/vagrant"
    s2.vm.hostname = "server2.vagrant.box"
    s2.vm.network "private_network", type: "dhcp"
    s2.vm.provision :shell, path: "bootstrap.sh"
  end

end
