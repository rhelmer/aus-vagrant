Vagrant::Config.run do |config|
  config.vm.box = "lucid64"
  config.vm.network "33.33.34.10"
  config.vm.provision :puppet do |puppet|
    puppet.manifest_file = "init.pp"
    #puppet.options = "--verbose --debug"
  end
end
