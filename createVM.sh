#!/bin/bash

#Make dist folder

#Global variables
raspIso="rasp.iso"

case $1 in

makeIso)
  mkdir -p "dist"
  cd dist

  if test -f "${raspIso}2"; then
    rm $raspIso
    cp "${raspIso}2" $raspIso
  else
    if test ! -f $raspIso; then
      curl https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2023-05-03/2023-05-03-raspios-bullseye-armhf.img.xz >"$raspIso.xz"
      xz -d "$raspIso.xz"
      cp $raspIso "${raspIso}2"
    fi
  fi

  mkdir -p mounter
  rootStart=$(fdisk -l rasp.iso | tail -2 | tail -1 | awk '{print $2}')
  echo $(($rootStart * 512))
  mount -o offset=$(($rootStart * 512)) $raspIso mounter
  cp ../configRaspian.sh mounter/
  cd mounter
  chmod 777 configRaspian.sh
  sh ./configRaspian.sh
  cd ..
  #touch mounter/ssh
  #Remove welcome screen thankyou Darth Vader https://raspberrypi.stackexchange.com/questions/22047/disabling-rainbow-splash-screen-does-not-work
  #cat "mounter/cmdline.txt" | sed "s/console=tty1/console=tty3/"
  # echo "disable_splash=1" >> mounter/config.txt

  # echo "mounter/cmdline.txt"
  ls -lha mounter

  #sleep 1
  #umount mounter
  echo umounted

  ;;

runVM)
  sh ./createVM.sh makeIso
  cd dist

  kernel="qemu-rpi-kernel"
  if test ! -d $kernel; then
    git clone https://github.com/dhruvvyas90/$kernel.git
  fi

  # raspq="rasp.qcow2"

  # if test ! -f $raspq; then
  #   qemu-img convert -f raw $raspIso -O qcow2 $raspq
  # fi

  # rpios="rpios"

  # swap="swap.qcow2"

  # if test -f $swap; then
  #   qemu-img create -f qcow2 $swap 1G
  # fi

  # -hdb $swap \
  qemu-system-arm \
    -M versatilepb \
    -cpu arm1176 \
    -m 256 \
    -hda $raspIso \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::10022-:22 \
    -dtb $kernel/versatile-pb-buster.dtb \
    -kernel $kernel/kernel-qemu-4.19.50-buster \
    -append 'root=/dev/sda2 panic=1' \
    -no-reboot

  #-net user,hostfwd=tcp::5022-:22 \
  ;;

*)
  echo wrong option
  ;;
esac
