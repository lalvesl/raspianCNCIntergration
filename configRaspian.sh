#!/bin/bash

newUser="ifsc"
ipAdrress="192.168.0.45"

configuring() {
    echo "Configuring" $1
}

#remove unnecessary files
rm -rf etc/init.d/resize2fs_once
rm -rf etc/rc3.d/S01resize2fs_once
rm -rf etc/ssh/sshd_config.d/rename_user.conf
rm -rf etc/systemd/system/multi-user.target.wants/userconfig.service
rm -rf etc/xdg/autostart/piwiz.desktop
rm -rf var/lib/userconf-pi/autologin

#keyboard layout
configuring "keyboard layout"
mkdir -p "etc/default/"
keyboard="etc/default/keyboard"
cat $keyboard | sed "s/XKBLAYOUT=.*/XKBLAYOUT=br/" >$keyboard

#autologin
configuring "autologin"
mkdir -p "etc/lightdm/"
lightdm="etc/lightdm/lightdm.conf"
cat $lightdm | sed "s/autologin-user=.*/autologin-user=$newUser/" >$lightdm
autologin="etc/systemd/system/getty@tty1.service.d/autologin.conf"
cat $autologin | sed "s/rpi-first-boot-wizard/ifsc/" >$autologin

#language
configuring "language"
echo "en_US.UTF-8 UTF-8" >>etc/locale.gen
echo "LANG=en_US.UTF-8\nLANGUAGE=en_US.UTF-8\nLC_ALL=en_US.UTF-8" >etc/default/locale

#time zone
configuring "time zone"
localtime="etc/localtime"
rm $localtime
ln -s /usr/share/zoneinfo/America/Sao_Paulo $localtime
echo "America/Sao_Paulo" >etc/timezone

#ip address
configuring "ip address"
echo "nameserver $ipAdrress" >"etc/resolv.conf"
mkdir -p etc/unbound
mkdir -p etc/unbound/unbound.conf.d
resolvconf="resolvconf_resolvers.conf"
echo "forward-zone:" >>$resolvconf
echo '\tname: "."' >>$resolvconf
echo "\tforward-addr: $ipAdrress" >>$resolvconf

#newUser
configuring "newUser"
mv "home/pi" "home/$newUser"
group="etc/group"
cat $group | sed "s/:pi/:$newUser/" >$group
gshadow="etc/gshadow"
cat $gshadow | sed "s/:pi/:$newUser/" >$gshadow
shadow="etc/shadow"
cat $shadow | grep -v "^pi" >$shadow
echo 'systemd-coredump:!*:19622::::::' >>$shadow
echo 'ifsc:$y$j9T$k6o/FIPoyqp0SiKMpJozf0$96M/4I8Y9qT9MtnUiedNTTJwlNRVUzpBDInVwr.I.j1:19622:0:99999:7:::' >$shadow
passwd="etc/passwd"
cat $passwd | sed "s/^pi/$newUser/" >$passwd
echo "systemd-coredump:x:996:996:systemd Core Dumper:/:/usr/sbin/nologin\nifsc:x:1000:1000:,,,:/home/ifsc:/bin/bash" >$passwd

subgid="etc/subgid"
subuid="etc/subuid"
nopasswd="etc/sudoers.d/010_pi-nopasswd"
for i in $(echo $subgid $subuid $nopasswd); do
    cat $i | sed "s/^pi/$newUser/" >$i
done

#others configurations
configuring "others configurations"
mkdir -p "etc/systemd/system/getty.target.wants"
ln -s "/lib/systemd/system/getty@.service" "etc/systemd/system/getty.target.wants/getty@tty1.service"
tr -dc 'A-F0-9' </dev/urandom | head -c32 >etc/machine-id
ln -s "etc/machine-id" "var/lib/dbus/machine-id"
cp "usr/share/X11/xorg.conf.d/99-fbturbo.~" "usr/share/X11/xorg.conf.d/99-fbturbo.conf"
randomSeed="var/lib/systemd/random-seed"
dd if=/dev/random bs=512 count=1 >$randomSeed
chmod 300 $randomSeed

timers="var/lib/systemd/timers"
timesync="var/lib/systemd/timesync"
mkdir -p $timers
mkdir -p $timesync

echo -n "" >>"$timers/stamp-apt-daily.timer"
echo -n "" >>"$timers/stamp-apt-daily-upgrade.timer"
echo -n "" >>"$timers/stamp-e2scrub_all.timer"
echo -n "" >>"$timers/stamp-fstrim.timer"
echo -n "" >>"$timers/stamp-logrotate.timer"
echo -n "" >>"$timers/stamp-man-db.timer"
echo -n "" >>"$timesync/clock"

################## unnecessary ################
#cups configuration
#cp ../unnecessary/subscriptions.conf* etc/cups/

#don't know :3
#echo "2023-09-22 04:59:59" > etc/fake-hwclock.data
#echo "etty1" > "var/log/lastlog"
#var/log/wtmp
#home/rpi-first-boot-wizard/
#var/lib/plymouth/ ### screens on boot
