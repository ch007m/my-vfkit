# Commands to be used to create a VM on macos

See documentation: https://github.com/crc-org/vfkit
For butane tool: https://coreos.github.io/butane/

Download under `dev` folder a Fedora CoreOS raw image and execute the script

**Note**: change the mac address

```bash
./start-vm.sh
```

## Converting the YAML config file to ignition json

```bash
podman run --rm \
  -v /Users/cmoullia/code/_temp/vfkit/dev/:/files \
  quay.io/coreos/butane:release \
  --pretty \
  --strict \
  /files/my-cfg.bu > transpiled_config.ign
```

podman command executed to start the VM on macos
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