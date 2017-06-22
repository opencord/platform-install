Vagrant.configure("2") do |config|
  # base image
  config.vm.box = "ubuntu/trusty64"

  # share the folder
  config.vm.synced_folder "../../", "/opt/cord/", create: true
  config.vm.synced_folder "./cord_profile", "/opt/cord_profile/", create: true
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # set the frontend vm
  config.vm.define "head-node" do |d|
    d.vm.network "private_network", ip: "192.168.46.100"
    d.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end
  end

  config.vm.provision :shell, privileged: false, path: "./scripts/cord-bootstrap.sh"
  config.vm.provision "ansible_local" do |ansible|
    ansible.provisioning_path = "/opt/cord/build/platform-install"
    ansible.playbook = "bootstrap-dev-env.yml"
  end
end
