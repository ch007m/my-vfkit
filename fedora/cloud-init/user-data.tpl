#cloud-config
chpasswd:
  list: |
    root:user1
  expire: False

disable_root: false
package_upgrade: false

packages:
  - wget
  - git

users:
  - name: user1
    gecos: User1 User
    # Password: user1
    passwd: $y$j9T$oDXijWyyIphUF/uI8/QdU0$ITomDBxgnCxOUb0eYK3qfO1MSZUPFSmHmkL6PHvZ1I6
    lock-passwd: false
    chpasswd: { expire: False }
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_pwauth: True
    ssh_authorized_keys:
      - SSH_PUBLIC_KEY

  - name: root
    ssh_authorized_keys:
      - SSH_PUBLIC_KEY

write_files:
  - path: /run/scripts/install-script.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -x

      timedatectl set-timezone TIMEZONE

      echo 'alias k=kubectl' | sudo tee /etc/profile.d/alias.sh
      mkdir -p /home/user1/.local/bin

      echo 'Installing kind ...' >> /run/install_log.txt
      curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.26.0/kind-linux-arm64
      chmod +x ./kind
      mv ./kind /home/user1/.local/bin/kind

      K9S_VERSION=0.32.7
      wget https://github.com/derailed/k9s/releases/download/v$K9S_VERSION/k9s_linux_arm64.rpm
      sudo dnf install -y k9s_linux_arm64.rpm

      echo "$(hostname -I | cut -d" " -f 1) $HOSTNAME" >> /etc/hosts

      sudo dnf install -y jq podman kubectl
      echo 'Script executed successfully!' >> /run/install_log.txt

runcmd:
  - [ sh, "/run/scripts/install-script.sh" ]

