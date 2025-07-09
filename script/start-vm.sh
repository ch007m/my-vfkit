#!/usr/bin/env bash

if [[ -n "$IGNITION" ]]; then
    IGNITION="true"
    CLOUD_INIT=""
else
    IGNITION=""
    CLOUD_INIT="true"
fi

if [[ -n "$IMAGE_PATH" ]]; then
    IMG="$IMAGE_PATH"
else
   echo "The path to the IMAGE file is mandatory !"
   exit 1
fi

if [[ -n "$VM_MEMORY" ]]; then
    MEMORY="$VM_MEMORY"
else
    MEMORY="4096" # 6144, 8192
fi

if [[ -n "$VM_CPU" ]]; then
    CPU="$VM_CPU"
else
    CPU="2"
fi

if [[ -n "$MAC_ADDRESS" ]]; then
    MAC_ADDRESS="$MAC_ADDRESS"
else
   echo "The MAC_ADDRESS is mandatory !"
   exit 1
fi

if [[ -n "$SHARED_DIR" ]]; then
    SHARED_DIR="$SHARED_DIR"
fi

VIRT_FOLDER=$(pwd)/_virt
IMG_FOLDER=$(pwd)/fedora

rm $VIRT_FOLDER/*.log

vfkit \
  --cpus $CPU \
  --memory $MEMORY \
  --log-level debug \
  ${IGNITION:+--ignition $VIRT_FOLDER/my-cfg.ign} \
  ${CLOUD_INIT:+--cloud-init $IMG_FOLDER/cloud-init/user-data} \
  --bootloader efi,variable-store=$VIRT_FOLDER/efi-variable-store,create \
  --device virtio-blk,path=$IMG_FOLDER/$IMG \
  --device virtio-input,keyboard \
  --device virtio-input,pointing \
  --device rosetta,mountTag=rosetta,install \
  --restful-uri tcp://localhost:60195 \
  --device virtio-rng \
  --device virtio-net,nat,mac=$MAC_ADDRESS \
  --device virtio-vsock,port=1025,socketURL=$VIRT_FOLDER/default.sock,listen \
  --device virtio-serial,logFilePath=$VIRT_FOLDER/default.log \
  --device virtio-gpu,width=800,height=600 \
  ${SHARED_DIR:+--device virtio-fs,sharedDir=$SHARED_DIR/,mountTag=dev} \
  --gui