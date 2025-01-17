#cloud-config

disable_root: false
package_upgrade: false

packages:
  - wget
  - git
  - gcc
  - go
  - which

users:
  - name: user1
    gecos: User1 User
    # Password: user1
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

      timedatectl set-timezone TIMEZONE

      echo "export KIND_EXPERIMENTAL_FEATURE=podman" >> /home/user1/.bash_profile
      echo 'alias k=kubectl' | sudo tee /etc/profile.d/alias.sh

      mkdir -p /home/user1/.local/bin
      chown -R user1:user1 /home/user1/.local

      echo "Install dev tools needed by brew"
      sudo dnf group install -y development-tools

      echo 'Installing homebrew ...' | sudo tee /run/install_log.txt
      CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ZhongRuoyu/homebrew-aarch64-linux/HEAD/install.sh)"

      echo >> /home/user1/.bashrc
      echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/user1/.bashrc
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

      echo 'Installing brew go from source as we must build it ...' | sudo tee /run/install_log.txt
      brew install --build-from-source go

      echo 'Installing kind and build it from source as non available for linux aarch64...' | sudo tee /run/install_log.txt
      brew install --build-from-source kind

      echo 'Installing k9s ...' | sudo tee /run/install_log.txt
      brew install derailed/k9s/k9s

      echo 'Installing kubectl ...' | sudo tee /run/install_log.txt
      # DON'T WORK AS bash, m4, berkeley-db@5, etc  are needed, cannot be easily build and by consequent
      # this is irrelevant to build them
      # brew install --build-from-source --ignore-dependencies kubernetes-cli
      sudo dnf install -y kubectl

      echo "$(hostname -I | cut -d" " -f 1) $HOSTNAME" | sudo tee /etc/hosts

      echo 'Script executed successfully!' | sudo tee /run/install_log.txt

runcmd:
  - [ sudo, -u, user1, "/run/scripts/install-script.sh" ]

