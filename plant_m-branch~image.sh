#!/bin/bash
set -e
set -x
. common.sh

wwid=${1:0:2}
wid=${wwid:1:2}
branch=$2
buildnum=$3

workdir=$(find . -maxdepth 1 -type d -name "$wwid*" | head -1)

if [[ ! -z $workdir ]]; then
  [[ "$(ls -A $workdir)" ]] && ((>&2 echo "Directory $workdir is not empty") ; exit 1)

  [[ $workdir =~ ($wwid-)([^~@]*)(~)([1-9][0-9]{4}|latest|.*\@.*)$ ]] || ((>&2 echo "Couldn't parse format of  $workdir, expected $wwid-branch~15555") ; exit 1)

  [[ -z $branch ]] || ${BASH_REMATCH[2]} == $branch || ((>&2 echo "Branch mismatch - second parameter ($branch) doesn't branch in folder $workdir") ; exit 1)
  branch=${BASH_REMATCH[2]}
  buildnum=${BASH_REMATCH[4]}

  workdir=$(pwd)/$wwid-$branch~$buildnum
else
  workdir=$(pwd)/$wwid-$branch~$buildnum
  mkdir $workdir
fi

# if it has @ - that is husky environ inside docker image
if [[ $buildnum =~ @ ]] ; then
  
  _plugin/docker/plant_m-version@image.sh $wwid
  exit 0
fi

# at this point detect latest build in $branch with tar centos5 build and use its number
if [ "$buildnum" == latest ] ; then
  url=http://hasky.askmonty.org/archive/$branch
  for build in $(wget -qq -O - $url | grep -oh 'build-.....' | sort -r | uniq) ; do
    # avoid trusty until MDEV-12370 is fixed
    if wget -qq -O - $url/$build | grep -qE "kvm-bintar-centos5-amd64" ; then
      buildnum=${build##*-}
      break
    fi
  done
fi


# copy templates for mariadb environs
version=$branch-$buildnum

for filename in _template/m-{version,all}/* ; do
  m4 -D__wid=$wid -D__workdir=$workdir -D__port=$port -D__dll=$dll -D__version=$version -D__wwid=$wwid -D__datadir=$workdir/dt $filename \
    > $workdir/$(basename $filename)
done

for filename in _template/m-{version,all}/*.sh ; do
  chmod +x $workdir/$(basename $filename)
done


# do the same for enabled plugins
for plugin in $ERN_PLUGINS ; do
  [ -d ./_plugin/$plugin/m-version/ ] && for filename in ./_plugin/$plugin/m-version/* ; do
    MSYS2_ARG_CONV_EXCL="*" m4 -D__wid=$wid -D__workdir=$workdir -D__srcdir=$src -D__blddir=$bld -D__port=$port -D__bldtype=$bldtype -D__dll=$dll -D__version=$version -D__wwid=$wwid -D__datadir=$workdir/dt $filename > $workdir/$(basename $filename)
    chmod +x $workdir/$(basename $filename)
  done

  [ -d ./_plugin/$plugin/m-all/ ] && for filename in ./_plugin/$plugin/m-all/* ; do
    MSYS2_ARG_CONV_EXCL="*" m4 -D__wid=$wid -D__workdir=$workdir -D__srcdir=$src -D__blddir=$bld -D__port=$port -D__bldtype=$bldtype -D__dll=$dll -D__version=$version -D__wwid=$wwid -D__datadir=$workdir/dt $filename > $workdir/$(basename $filename)
    chmod +x $workdir/$(basename $filename)
  done
  
done



# now overwrite with husky templates
for filename in _plugin/hasky/m-tar~buildnum/* ; do

  # had to put MSYS2_ARG_CONV_EXCL to avoid messy path expansion in MINGW, hope it will work properly on any OS
  MSYS2_ARG_CONV_EXCL="*" m4 -D__workdir=$workdir -D__wwid=$wwid -D__buildnum=$buildnum -D__branch=$branch \
       $filename > $workdir/$(basename $filename)
done

detect_windows || for filename in _plugin/hasky/m-tar~buildnum/*.sh ; do
  chmod +x $workdir/$(basename $filename)
done

