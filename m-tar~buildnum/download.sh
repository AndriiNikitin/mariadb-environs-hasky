#!/bin/bash

[ -f common.sh ] && source common.sh

# example url http://hasky.askmonty.org/archive/bb-10.1-xtrabackup/build-13568/kvm-bintar-trusty-amd64/mariadb-10.1.23-linux-x86_64.tar.gz

# pref1=$(detect_distcode)-$(detect_amd64)
# pref2=$(detect_distcodeN)-$(detect_amd64)
pref3=centos5-amd64

urldir=http://hasky.askmonty.org/archive/__branch/build-__buildnum/kvm-bintar

mkdir -p __workdir/../_depot/m-tar/__branch-__buildnum

(
cd __workdir/../_depot/m-tar/__branch-__buildnum
if [ ! -f mariadb-*-linux-x86_64.tar.gz  ] ; then 
  echo downloading "$urldir-$pref3/mariadb-*-linux-x86_64.tar.gz"
  wget -q -r -np -nd -A "mariadb-*-linux-x86_64.tar.gz" -nc "$urldir-$pref3/" &
  wgetpid=$!
  while kill -0 $wgetpid 2>/dev/null ; do
    sleep 10
    echo -n .
  done
  wait $wgetpid
fi

if [ -f mariadb-*-linux-x86_64.tar.gz ] ; then 
  if [ ! -x bin/mysqld ] ; then
    tar -zxf mariadb-*-linux-x86_64.tar.gz ${ERN_M_TAR_EXTRA_FLAGS} --strip 1
  fi
fi)
