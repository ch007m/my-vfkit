#!/usr/bin/env bash

if [[ -n "$RAW_FEDORA_FILE" ]]; then
    IMG="$RAW_FEDORA_FILE"
else
    IMG="Fedora-Cloud-41.raw"
fi

if [[ -n "$VM_MEMORY" ]]; then
    MEMORY="$VM_MEMORY"
else
    MEMORY="4096" # 6144
fi

if [[ -n "$VM_CPU" ]]; then
    CPU="$VM_CPU"
else
    CPU="2" # 6144
fi

CFG_FOLDER=$(pwd)/dev
IMG_FOLDER=$(pwd)/fedora

rm CFG_FOLDER/*.log

# gVisor and sock config
#  --device virtio-vsock,port=1025,socketURL=/Users/cmoullia/code/_temp/vfkit/dev/vsock-1025.sock,listen \
#  --device virtio-net,unixSocketPath=/Users/cmoullia/code/_temp/vfkit/dev/gvproxy.sock,mac=5a:94:ef:e4:0c:ee \

# NAT & Mac address
#--device virtio-net,nat,mac=5a:94:ef:e4:0c:ee \
#--device virtio-vsock,port=1025,socketURL=$CFG_FOLDER/default.sock,listen \

vfkit \
  --cpus $CPU \
  --memory $MEMORY \
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
  --device virtio-net,nat,mac=5a:94:ef:e4:0c:ee \
  --device virtio-vsock,port=1025,socketURL=$CFG_FOLDER/default.sock,listen \
  --device virtio-serial,logFilePath=$CFG_FOLDER/default.log \
  --device virtio-gpu,width=800,height=600 \
  --device virtio-fs,sharedDir=/Users/cmoullia/code/,mountTag=user1 \
  --gui