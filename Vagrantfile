Vagrant.configure("2") do |config|
  # base image
  config.vm.box = "ubuntu/trusty64"

  # share the folder
  config.vm.synced_folder "../../", "/home/vagrant/cord/", create: true
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # set the frontend vm
  config.vm.define "head-node" do |d|
    d.vm.network "forwarded_port", guest: 9999, host: 9999
    d.vm.network "forwarded_port", guest: 6379, host: 6379
    d.vm.network "private_network", ip: "192.168.46.100"
    d.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end
  end

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    curl -o ~/cord-bootstrap.sh https://raw.githubusercontent.com/opencord/platform-install/master/scripts/cord-bootstrap.sh
    bash cord-bootstrap.sh
    ssh-keygen -t rsa -N "" -f .ssh/id_rsa
    cp ~/.ssh/id_rsa node_key
  SHELL

 end
