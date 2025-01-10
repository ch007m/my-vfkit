# Commands to be used to create a VM on macos

See documentation: https://github.com/crc-org/vfkit
For butane tool: https://coreos.github.io/butane/

Download the Fedora CoreOS raw image: https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/41.20241215.3.0/aarch64/fedora-coreos-41.20241215.3.0-metal.aarch64.raw.xz
and extract it locally.

Change the mac address within the bash script to use yours and point to local temp folder where log, ignition or butane config files will be stored

Create a butane config file and convert it to an ignition json file

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

Create the VM
```bash
export IMG=fedora-coreos-41.aarch64.raw

vfkit \
--cpus 2 \
--memory 2048 \
--log-level debug \
--ignition $CFG_FOLDER/my-cfg.ign \
--bootloader efi,variable-store=$CFG_FOLDER/efi-variable-store,create \
--device virtio-blk,path=$IMG \
--device virtio-input,keyboard \
--device virtio-input,pointing \
--device virtio-net,nat,mac=5a:94:ef:e4:0c:ee \
--device rosetta,mountTag=rosetta,install \
--restful-uri tcp://localhost:60195 \
--device virtio-rng \
--device virtio-vsock,port=1025,socketURL=$CFG_FOLDER/default.sock,listen \
--device virtio-serial,logFilePath=$CFG_FOLDER/default.log \
--device virtio-gpu,width=800,height=600 \
--device virtio-fs,sharedDir=/var/folders,mountTag=a0bb3a2c8b0b02ba5958b0576f0d6530e104 \
--gui
```

## Information 

Here is an example the command executed by podman using `podman machine strat` to start a VM on macos
```txt
vfkit \
--cpus 8 \
--memory 9536 \
--bootloader efi,variable-store=/Users/cmoullia/.local/share/containers/podman/machine/applehv/efi-bl-podman-machine-default,create \
--device virtio-blk,path=/Users/cmoullia/.local/share/containers/podman/machine/applehv/podman-machine-default-arm64.raw \
--device virtio-rng \
--device virtio-vsock,port=1025,socketURL=/var/folders/28/g86pgjxj0wl1nkd_85c2krjw0000gn/T/podman/podman-machine-default.sock,listen \
--device virtio-serial,logFilePath=/var/folders/28/g86pgjxj0wl1nkd_85c2krjw0000gn/T/podman/podman-machine-default.log \
--device rosetta,mountTag=rosetta,install \
--device virtio-net,unixSocketPath=/var/folders/28/g86pgjxj0wl1nkd_85c2krjw0000gn/T/podman/podman-machine-default-gvproxy.sock,mac=5a:94:ef:e4:0c:ee \
--device virtio-fs,sharedDir=/Users,mountTag=a2a0ee2c717462feb1de2f5afd59de5fd2d8 \
--device virtio-fs,sharedDir=/private,mountTag=71708eb255bc230cd7c91dd26f7667a7b938 \
--device virtio-fs,sharedDir=/var/folders,mountTag=a0bb3a2c8b0b02ba5958b0576f0d6530e104 \
--restful-uri tcp://localhost:60194
```