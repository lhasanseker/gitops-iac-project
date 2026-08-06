Vagrant.configure("2") do |config|
  # Windows 11 + VirtualBox ortaminda bento/ubuntu-24.04 kutusu
  # acilis sirasinda kilitlenebildigi icin kararli Ubuntu 22.04 LTS kullan.
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"

  # Ilk indirme ve ilk acilis normalden uzun surerse Vagrant erken pes etmesin.
  config.vm.boot_timeout = 600

  config.vm.hostname = "gitops-server"

  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "gitops-iac-server"
    vb.memory = 2048
    vb.cpus = 2
  end

  # Uptime Kuma yedeklerinin Windows tarafinda kalacagi klasor
  config.vm.synced_folder \
    "./persistent/uptime-kuma-backups",
    "/mnt/uptime-kuma-backups",
    create: true,
    owner: "vagrant",
    group: "vagrant"

  # Ansible SSH acik anahtarini her yeni VM'ye otomatik ekle
  config.vm.provision "file",
    source: "./ansible/keys/gitops_iac_vagrant.pub",
    destination: "/tmp/gitops_iac_vagrant.pub"

  config.vm.provision "shell", inline: <<-SHELL
    set -eu

    install -d -m 700 -o vagrant -g vagrant /home/vagrant/.ssh
    touch /home/vagrant/.ssh/authorized_keys
    chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
    chmod 600 /home/vagrant/.ssh/authorized_keys

    ANSIBLE_PUBLIC_KEY="$(cat /tmp/gitops_iac_vagrant.pub)"

    if ! grep -qxF "${ANSIBLE_PUBLIC_KEY}" /home/vagrant/.ssh/authorized_keys; then
      printf '%s\n' "${ANSIBLE_PUBLIC_KEY}" >> /home/vagrant/.ssh/authorized_keys
    fi

    rm -f /tmp/gitops_iac_vagrant.pub
  SHELL

  # VM silinmeden hemen once son Uptime Kuma yedegini al.
  # Yalnizca acil durumda ve Windows yedegi elle dogrulandiktan sonra
  # PowerShell'de SKIP_UPTIME_BACKUP=1 ayariyla bu tetikleyici atlanabilir.
  unless ENV["SKIP_UPTIME_BACKUP"] == "1"
    config.trigger.before :destroy do |trigger|
      trigger.name = "Uptime Kuma yedegi"
      trigger.warn = "VM silinmeden once Uptime Kuma yedegi aliniyor."
      trigger.on_error = :halt

      trigger.run_remote = {
        inline: <<-SHELL
          if [ -x /usr/local/sbin/backup-uptime-kuma ]; then
            sudo /usr/local/sbin/backup-uptime-kuma
          else
            echo "Yedekleme scripti henuz kurulmadigi icin bu adim atlandi."
          fi
        SHELL
      }
    end
  end
end
