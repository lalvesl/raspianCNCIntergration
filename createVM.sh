#!/bin/bash

#Make dist folder
if test ! -d "dist"; then
  mkdir "dist"
fi
cd dist

#Global variables
raspIso="rasp.iso"

case $1 in

makeIso)

  if test ! -f $raspIso; then
    curl https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2023-05-03/2023-05-03-raspios-bullseye-armhf.img.xz >"$raspIso.xz"
    xz -d "$raspIso.xz"
  fi

  if test ! -d "mounter"; then
    mkdir mounter
  fi
  rootStart=$(fdisk -l rasp.iso | awk '{print $2}' | awk '{print $NF}' | tail -1)

  echo $(($rootStart * 512))
  mount -o offset=$(($rootStart * 512)) $raspIso mounter
  mkdir mounter/media/swap
  print "$(cat mounter/etc/fstab)\\n mounter/media/swap"
  sleep 1
  umount mounter

  ;;

runVM)
  kernel="qemu-rpi-kernel"
  if test ! -d $kernel; then
    git clone https://github.com/dhruvvyas90/qemu-rpi-kernel.git
  fi

  raspq="rasp.qcow2"

  if test ! -f $raspq; then
    qemu-img convert -f raw $raspIso -O qcow2 $raspq
  fi

  rpios="rpios"

  swap="swap.qcow2"

  if test ! -f $raspq; then
    qemu-img create -f qcow2 $swap 1G
  fi

  qemu-system-arm \
    -M versatilepb \
    -cpu arm1176 \
    -m 256 \
    -hda $raspq \
    -hdb $swap \
    -net user,hostfwd=tcp::5022-:22 \
    -dtb $kernel/versatile-pb-buster.dtb \
    -kernel $kernel/kernel-qemu-4.19.50-buster \
    -append 'root=/dev/sda2 panic=1'
  #-no-reboot

  ;;

*)
  echo wrong option
  ;;
esac
