## How to create a Fedora VM on a mac machine using vfkit

- See documentation: https://github.com/crc-org/vfkit
- For butane tool: https://coreos.github.io/butane/

## How to guide

Download a Fedora CoreOS AppleHV image (example: https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/41.20241215.3.0/aarch64/fedora-coreos-41.20241215.3.0-applehv.aarch64.raw.gz)
and extract it locally.

Change the mac address (the one of your eth or bridge interface) to configure the [network interface](https://github.com/crc-org/vfkit/blob/main/doc/usage.md#networking) to access it from your machine
and update the bash script to use yours and point to a local temp folder where log, ignition or butane config files will be stored

Create a butane yaml config file to define a user, its password and import your public key (to ssh). See hereafter what you should do !
```bash
cat <<EOF > dev/my-cfg.bu
variant: fcos
version: 1.1.0
passwd:
  users:
    - name: user1
      # 
      # Get your Public key and append it to the following field
      #
      ssh_authorized_keys:
      - <<ADD_HERE THE CONTENT OF YOUR PUBLIC KEY STRING>>
      #
      # Generate the hash password using this command: podman run -ti --rm quay.io/coreos/mkpasswd --method=yescrypt
      #
      password_hash: <<GENERATED_PASSWORD>>
      home_dir: /home/user1
      no_create_home: false
      groups:
        - wheel
        - sudo
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

You can mount different folders as documented here: https://github.com/crc-org/vfkit/blob/main/doc/usage.md#file-sharing
Add a new line to your config
```aiignore
--device virtio-fs,sharedDir=<<YOUR_PATH>>,mountTag=<<MOUNT_NAME>> \
```
and ssh to mount the dir
```bash
ssh -i ~/.ssh/id_rsa user1@192.168.64.4
user1@localhost:~$ pwd
/home/user1

mkdir /home/user1/dir
sudo mount -t virtiofs <<MOUNT_NAME>> /home/user1/<<TARGET_DIR>>
ls -la /home/user1/<<TARGET_DIR>>
```

## gVisor

Alternatively, we could also like the podman project do use gVisor but, then it will be needed to launch 2 processes: vfkit and gvisor !

See project: https://github.com/containers/gvisor-tap-vsock

```bash
// Processes lanched using: podman machine start
vfkit --cpus 8 --memory 9536 \
  --bootloader efi,variable-store=/Users/cmoullia/.local/share/containers/podman/machine/applehv/efi-bl-podman-machine-default,create \
  --device virtio-blk,path=/Users/cmoullia/.local/share/containers/podman/machine/applehv/podman-machine-default-arm64.raw \
  --device virtio-rng \
  --device virtio-serial,logFilePath=/var/folders/28/g86pgjxj0wl1nkd_85c2krjw0000gn/T/podman/podman-machine-default.log \
  --device rosetta,mountTag=rosetta,install \
  --device virtio-vsock,port=1025,socketURL=/var/folders/28/g86pgjxj0wl1nkd_85c2krjw0000gn/T/podman/podman-machine-default.sock,listen \
  --device virtio-net,unixSocketPath=/var/folders/28/g86pgjxj0wl1nkd_85c2krjw0000gn/T/podman/podman-machine-default-gvproxy.sock,mac=5a:94:ef:e4:0c:ee \
  --device virtio-fs,sharedDir=/Users,mountTag=a2a0ee2c717462feb1de2f5afd59de5fd2d8 \
  --device virtio-fs,sharedDir=/private,mountTag=71708eb255bc230cd7c91dd26f7667a7b938 \
  --device virtio-fs,sharedDir=/var/folders,mountTag=a0bb3a2c8b0b02ba5958b0576f0d6530e104 \
  --restful-uri tcp://localhost:60194 \
  --device virtio-gpu,width=800,height=600 \
  --device virtio-input,pointing \
  --device virtio-input,keyboard \
  --gui

/opt/podman/bin/gvproxy -debug -mtu 1500 -ssh-port 60188 \
  -listen-vfkit unixgram:///var/folders/28/g86pgjxj0wl1nkd_85c2krjw0000gn/T/podman/podman-machine-default-gvproxy.sock \
  -forward-sock /var/folders/28/g86pgjxj0wl1nkd_85c2krjw0000gn/T/podman/podman-machine-default-api.sock \
  -forward-dest /run/user/501/podman/podman.sock \
  -forward-user core \
  -forward-identity /Users/cmoullia/.local/share/containers/podman/machine/machine \
  -pid-file /var/folders/28/g86pgjxj0wl1nkd_85c2krjw0000gn/T/podman/gvproxy.pid \
  -log-file /var/folders/28/g86pgjxj0wl1nkd_85c2krjw0000gn/T/podman/gvproxy.log
```

Do we need such parameters ?

-forward-user user1 \
-forward-identity /Users/cmoullia/.ssh/id_rsa \

Command tested for vfkit
```bash
vfkit parameters
  --device virtio-vsock,port=1025,socketURL=/Users/cmoullia/code/_temp/vfkit/dev/vsock-1025.sock,listen \
  --device virtio-net,unixSocketPath=/Users/cmoullia/code/_temp/vfkit/dev/gvproxy.sock,mac=5a:94:ef:e4:0c:ee \
  
  #-listen vsock://:1025 \
  #-listen unix:///Users/cmoullia/code/_temp/vfkit/dev/vfkit-vsock-1025.sock \
set CONFIG_FOLDER /Users/cmoullia/code/_temp/vfkit/dev
rm $CONFIG_FOLDER/gvproxy.sock
gvproxy -debug -mtu 1500 -ssh-port 60188 \
  -listen-vfkit unixgram://$CONFIG_FOLDER/gvproxy.sock \
  -pid-file $CONFIG_FOLDER/gvproxy.pid \
  -log-file $CONFIG_FOLDER/gvproxy.log
```

To ssh
```bash
ssh -i /Users/cmoullia/.ssh/id_rsa -p 60188 \
  -o IdentitiesOnly=yes \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o CheckHostIP=no \
  user1@localhost
```

## Remarks

We can try to create a VM using another raw images like `fedora cloud` but then it is needed to check what they accept: cloud-init vs ignition

| Type          | Config mode | Testing                                                |
|---------------|-------------|--------------------------------------------------------|
| Fedora Cloud  | cloud-init  |                                                        |
| Fedora CoreOS | ignition    | fedora-coreos-41.20241215.3.0-applehv.aarch64.raw      |
| Fedora Server | ?           | Must be configured when we create the VM the first time |
