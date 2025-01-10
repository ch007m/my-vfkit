# Commands to be used to create a VM on macos

See documentation:

```bash
./[start-vm.sh](start-vm.sh)
```

To ssh:
```bash
DEBU[0000] Executing: ssh [-i /Users/cmoullia/.local/share/containers/podman/machine/machine -p 60188 core@localhost -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o LogLevel=ERROR -o SetEnv=LC_ALL= -t]
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