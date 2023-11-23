# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bullseye64"

  #Ordenes generales para todas las MVs
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "256" #RAM
    vb.linked_clone = true
  end # provider

  #Solo para una máquina virtual
  config.vm.define "debian" do |debian|
    debian.vm.hostname = "debian.deaw.es"
    debian.vm.network :public_network
    debian.vm.provision "shell", path: "provision.sh"

  end
end
