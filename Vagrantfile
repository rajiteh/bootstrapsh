# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.


#vagrant plugin install vagrant-hostmanager

BOX_NAME="devbox"
ALIAS="#{BOX_NAME}.local"
HOSTNAME="#{BOX_NAME}-dev"
MOUNT_POINT="/vagrant"

Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "ubuntu/trusty64"
  config.vm.box_check_update = true

  # Enabling DHCP here, Vagrant-hostmanager and below script will help us
  # keep track of VM IP address.
  config.vm.network "private_network", type: "dhcp"

  config.vm.hostname = HOSTNAME
  config.vm.synced_folder '.', MOUNT_POINT

  # Running script to install necessary packages. Modify the arguments as 
  # needed. Read repo's manual to see what options are available.
  config.vm.provision "shell" do |s|
    s.path = "./bootstrap.sh"
    s.args = [ "rbenv=2.0.0-p247", "nvm=0.10", "php", "apache", "mysql", "app" ]
    s.keep_color = true
    s.privileged = false
    s.env = { APP_DEPLOY_KEY: "$(cat ssh_keys/deploy_rsa)", APP_REPO_GIT: "git@github.com:HP41/bootstrapsh.git" }
  end

  # Host manager
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true
  config.hostmanager.aliases = [ALIAS]
  config.hostmanager.ip_resolver = proc do |vm, _|
    if (vm.ssh_info && vm.ssh_info[:host])
      command = [
        "ssh",
        "#{vm.ssh_info[:username]}@#{vm.ssh_info[:host]}",
        "-p", vm.ssh_info[:port],
        "-o", "Compression=yes",
        "-o", "DSAAuthentication=yes",
        "-o", "LogLevel=FATAL",
        "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "-o", "IdentitiesOnly=yes",
        "-i", vm.ssh_info[:private_key_path],
        "\"ifconfig eth1 | grep inet | cut -d: -f2 | cut -d' ' -f1\""
      ].join(' ')
      '#{command}'.strip
    end
  end

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   sudo apt-get update
  #   sudo apt-get install -y apache2
  # SHELL
end