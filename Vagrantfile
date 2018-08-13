# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/debian9"
  config.vm.box_check_update = false

  # config.vm.network "forwarded_port", guest: 4000, host: 4001

  # config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.synced_folder ".", "/app"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = 1024
  end

  config.vm.provision "shell" do |s|
    s.inline = <<-SHELL
      apt-get update -yqq
      apt-get upgrade -y
      apt-get install -y htop vim lsof net-tools rsync ruby ruby-dev

      gem update --system && \
      gem install bundler -v '1.15.4' && \
      gem install pry -v '~>0.11'

      echo 'done'
    SHELL
  end
end
