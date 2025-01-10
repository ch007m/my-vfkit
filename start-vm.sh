#!/usr/bin/env bash

export IMG=fedora-coreos-41.aarch64.raw

vfkit \
--cpus 2 \
--memory 2048 \
--ignition dev/my-cfg.json \
--bootloader efi,variable-store=dev/efi-variable-store,create \
--device virtio-blk,path=$IMG \
--device virtio-input,keyboard \
--device virtio-input,pointing \
--device virtio-net,nat,mac=5a:94:ef:e4:0c:ee \
--device rosetta,mountTag=rosetta,install \
--restful-uri tcp://localhost:60195 \
--device virtio-rng \
--device virtio-vsock,port=1025,socketURL=dev/default.sock,listen \
--device virtio-gpu,width=800,height=600 \
--gui \
--device virtio-serial,logFilePath=dev/default.log