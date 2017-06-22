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
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    ssh-keygen -t rsa -N "" -f .ssh/id_rsa
    cp ~/.ssh/id_rsa node_key

    # Install apache
    sudo apt-get update
    sudo apt-get install -y apache2 libapache2-mod-fastcgi apache2-mpm-worker
    sudo a2enmod proxy_http
    sudo a2enmod headers
    sudo a2enmod rewrite
    sudo a2enmod proxy_wstunnel

    # Copy apache conf
    sudo cp /opt/cord/build/platform-install/roles/apache-proxy/files/cord-http.conf /etc/apache2/conf-enabled/cord-http.conf

    # Reload Apache
    sudo service apache2 reload

    # Add hosts
    echo "127.0.0.1 xos" | sudo tee --append /etc/hosts > /dev/null
    echo "127.0.0.1 xos-gui" | sudo tee --append /etc/hosts > /dev/null
    echo "127.0.0.1 xos-ws" | sudo tee --append /etc/hosts > /dev/null
    echo "127.0.0.1 xos-chameleon" | sudo tee --append /etc/hosts > /dev/null
    echo "127.0.0.1 xos-core" | sudo tee --append /etc/hosts > /dev/null
    echo "127.0.0.1 consul" | sudo tee --append /etc/hosts > /dev/null
  SHELL

 end
