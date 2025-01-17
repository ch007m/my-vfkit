#!/usr/bin/env bash

if [[ -z "$IMG" ]]; then
    IMG="$1"
else
    IMG="Fedora-Cloud-41.raw"
fi

CFG_FOLDER=$(pwd)/dev
IMG_FOLDER=$(pwd)/fedora

rm CFG_FOLDER/*.log

#--device virtio-net,nat,mac=5a:94:ef:e4:0c:ee \
vfkit \
  --cpus 2 \
  --memory 4096 \
  --log-level debug \
  --ignition $CFG_FOLDER/my-cfg.ign \
  --bootloader efi,variable-store=$CFG_FOLDER/efi-variable-store,create \
  --device virtio-blk,path=$IMG_FOLDER/$IMG \
  --device virtio-blk,path=$IMG_FOLDER/cloudinit.iso \
  --device virtio-input,keyboard \
  --device virtio-input,pointing \
  --device rosetta,mountTag=rosetta,install \
  --restful-uri tcp://localhost:60195 \
  --device virtio-rng \
  --device virtio-vsock,port=1025,socketURL=/Users/cmoullia/code/_temp/vfkit/dev/vsock-1025.sock,listen \
  --device virtio-net,unixSocketPath=/Users/cmoullia/code/_temp/vfkit/dev/gvproxy.sock,mac=5a:94:ef:e4:0c:ee \
  --device virtio-serial,logFilePath=$CFG_FOLDER/default.log \
  --device virtio-gpu,width=800,height=600 \
  --device virtio-fs,sharedDir=/Users/cmoullia/code/,mountTag=user1 \
  --gui