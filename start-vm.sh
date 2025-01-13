#!/usr/bin/env bash

export IMG=fedora-coreos-41.20241215.3.0-applehv.aarch64.raw
export CFG_FOLDER=/Users/cmoullia/code/_temp/vfkit/dev

vfkit \
--cpus 2 \
--memory 4096 \
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
--device virtio-fs,sharedDir=/Users/cmoullia/code/,mountTag=user1 \
--gui