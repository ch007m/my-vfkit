## How to create a Fedora VM on a mac machine using vfkit

- See documentation: https://github.com/crc-org/vfkit
- For butane tool: https://coreos.github.io/butane/

## How to guide

Download the Fedora CoreOS AppleHV image: https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/41.20241215.3.0/aarch64/fedora-coreos-41.20241215.3.0-applehv.aarch64.raw.gz
and extract it locally.

Change the mac address (the one of the eth interface) within the bash script to use yours and point to a local temp folder where log, ignition or butane config files will be stored

Create a butane config file to create a user and import your public key (to ssh). See hereafter what you should do !
```bash
cat <<EOF > dev/my-cfg.bu
variant: fcos
version: 1.1.0
passwd:
  users:
    - name: user1
      ssh_authorized_keys:
      - <<ADD_HERE THE CONTENT OF YOUR PUBLIC KEY STRING>
      #
      # Generate the hash password using this command: podman run -ti --rm quay.io/coreos/mkpasswd --method=yescrypt
      # password is: user1
      #
      password_hash: <<GENERATED_PASSWORD>>
      home_dir: /home/user1
      no_create_home: false
      groups:
        - wheel
      shell: /bin/bash
EOF      
```

and convert it to an ignition json file using `butane` tool

```bash
export CFG_FOLDER=/Users/cmoullia/code/_temp/vfkit/dev

podman run --rm \
  -v $CFG_FOLDER/:/files \
  quay.io/coreos/butane:release \
  --pretty \
  --strict \
  /files/my-cfg.bu > transpiled_config.ign
cp transpiled_config.ign $CFG_FOLDER/my-cfg.ign  
```

Create now the VM
```bash
export IMG=fedora-coreos-41.20241215.3.0-applehv.aarch64.raw

vfkit \
--cpus 2 \
--memory 2048 \
--log-level debug \
--ignition $CFG_FOLDER/my-cfg.ign \
--bootloader efi,variable-store=$CFG_FOLDER/efi-variable-store,create \
--device virtio-blk,path=$IMG \
--device virtio-input,keyboard \
--device virtio-input,pointing \
--device virtio-net,nat,mac=<<YOUr_MAC_ADDRESS>> \
--device rosetta,mountTag=rosetta,install \
--restful-uri tcp://localhost:60195 \
--device virtio-rng \
--device virtio-vsock,port=1025,socketURL=$CFG_FOLDER/default.sock,listen \
--device virtio-serial,logFilePath=$CFG_FOLDER/default.log \
--device virtio-gpu,width=800,height=600 \
--device virtio-fs,sharedDir=/var/folders,mountTag=a0bb3a2c8b0b02ba5958b0576f0d6530e104 \
--gui
```

To ssh, get the IP address of the VM from the GUI screen and pass the path of your private key
```bash

ssh -i ~/.ssh/id_rsa user1@192.168.64.4
Fedora CoreOS 41.20241215.3.0
Tracker: https://github.com/coreos/fedora-coreos-tracker
Discuss: https://discussion.fedoraproject.org/tag/coreos

Last login: Fri Jan 10 13:14:45 2025 from 192.168.64.1
user1@localhost:~$ 
```