#cloud-config

disable_root: false
package_upgrade: false

packages:
  - wget
  - git
  - gcc
  - go
  - which
  - java
  - maven
  - jq

users:
  - name: dev
    gecos: Dev user
    # Password: dev
    passwd: GENPASSWORD
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

      sudo timedatectl set-timezone TIME_ZONE

      mkdir -p /home/dev/.local/bin
      chown -R dev:dev /home/dev/.local

      echo "Install dev tools needed by brew"
      sudo dnf group install -y development-tools

      echo 'Installing homebrew ...' | sudo tee /run/install_log.txt
      CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ZhongRuoyu/homebrew-aarch64-linux/HEAD/install.sh)"

      echo >> /home/dev/.bashrc
      echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/dev/.bashrc
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

      echo 'Installing brew go from source as we must build it ...' | sudo tee /run/install_log.txt
      brew install --build-from-source go

      echo 'Installing kind and build it from source as non available for linux aarch64...' | sudo tee /run/install_log.txt
      brew install --build-from-source kind
      echo "export KIND_EXPERIMENTAL_FEATURE=podman" >> /home/dev/.bash_profile

      echo 'Installing k9s ...' | sudo tee /run/install_log.txt
      brew install derailed/k9s/k9s

      echo 'Installing kubectl ...' | sudo tee /run/install_log.txt
      # DON'T WORK AS bash, m4, berkeley-db@5, etc  are needed, cannot be easily build and by consequent
      # this is irrelevant to build them
      # brew install --build-from-source --ignore-dependencies kubernetes-cli
      sudo dnf install -y kubectl
      echo 'alias k=kubectl' | sudo tee /etc/profile.d/alias.sh

      echo "$(hostname -I | cut -d" " -f 1) $HOSTNAME" | sudo tee /etc/hosts

      echo 'Script executed successfully!' | sudo tee /run/install_log.txt

runcmd:
  - [ sudo, -u, dev, "/run/scripts/install-script.sh" ]

