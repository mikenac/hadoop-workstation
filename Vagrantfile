# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "mikenac/rhel7.3"
  config.vm.network "ambari", guest: 8080, host: 8080
  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone=true
    vb.memory = 8192
    vb.cpus = 2
  end

  #unregister from RHEL
  config.trigger.before :destroy do
    info "Un-registering from RHEL before destroy."
    run_remote '/vagrant/cleanup.sh'
  end
   config.vm.provision "shell", path: "provision.sh"
end
