#!/bin/sh

# Copyright (C) 2012 Ryan Finnie
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

set -e

DEFAULTFILE=/etc/default/grub-finnix

if [ -f /usr/lib/grub/grub-mkconfig_lib ]; then
  . /usr/lib/grub/grub-mkconfig_lib
else
  # no grub file, so we notify and exit gracefully
  echo "Cannot find grub config file" >&2
  exit 0
fi

# Read in the location of the ISO
if [ -f $DEFAULTFILE ]; then
  . $DEFAULTFILE
else
  exit 0
fi

# Check if the user has set FINNIX_ISO
[ -n "${FINNIX_ISO}" ] || exit 0

# On the other hand, if set but doesn't exist...
if ! [ -e "${FINNIX_ISO}" ]; then
  echo "Cannot find ${FINNIX_ISO}" >&2
  exit 0
fi

# Grab some information from the ISO
is_finnix=0
namestring="Finnix"
has_32bit=0
has_64bit=0
initrd=""
tempmount="$(mktemp -d)"
if mount -o ro,loop "${FINNIX_ISO}" "${tempmount}"; then
  [ -d "${tempmount}/finnix" ] && is_finnix=1
  [ -e "${tempmount}/boot/x86/linux" ] && has_32bit=1
  [ -e "${tempmount}/boot/x86/linux64" ] && has_64bit=1

  if [ -e "${tempmount}/boot/x86/initrd.xz" ]; then
    initrd="/boot/x86/initrd.xz"
  elif [ -e "${tempmount}/boot/x86/initrd.gz" ]; then
    initrd="/boot/x86/initrd.gz"
  elif [ -e "${tempmount}/boot/x86/initrd" ]; then
    initrd="/boot/x86/initrd"
  fi

  if [ -e "${tempmount}/finnix/os-release" ]; then
    for i in OS_NAME OS_VERSION; do
      read "$i"
    done <<EOM
$(
  . "${tempmount}/finnix/os-release"
  echo "$NAME"
  echo "$VERSION"
)
EOM
    namestring="${OS_NAME} ${OS_VERSION}"
  fi

  umount "${tempmount}"
  rmdir "${tempmount}"
else
  echo "Cannot mount ${FINNIX_ISO}" >&2
  rmdir "${tempmount}"
  exit 0
fi

# Check for error conditions
if [ "$is_finnix" = 0 ]; then
  echo "${FINNIX_ISO} does not appear to be a valid ${namestring} ISO" >&2
  exit 0
fi
if [ -z "$initrd" ]; then
  echo "${FINNIX_ISO} does not appear to have a known initrd" >&2
  exit 0
fi

# Get the device path of the ISO's filesystem
iso_device="$(${grub_probe} -t device ${FINNIX_ISO})"

# We can't cope with loop-mounted devices here.
case ${iso_device} in
  /dev/loop/*|/dev/loop[0-9]) exit 0 ;;
esac

iso_syspath="$(make_system_path_relative_to_its_root "${FINNIX_ISO}")"
prepare_boot_cache="$(prepare_grub_to_access_device ${iso_device} | sed -e "s/^/\t/")"

echo "Found ${namestring} ISO: ${FINNIX_ISO}" >&2
echo "    Device: ${iso_device}" >&2
echo "    Location on device: ${iso_syspath}" >&2
echo -n "    Kernels:" >&2
[ "$has_32bit" = 1 ] && echo -n " 32-bit" >&2
[ "$has_64bit" = 1 ] && echo -n " 64-bit" >&2
echo >&2
echo "    Initrd: ${initrd}" >&2

if [ "$has_64bit" = 1 ]; then
  cat << EOF
menuentry "${namestring} (64-bit)" {
EOF
  printf '%s\n' "${prepare_boot_cache}"
  cat << EOF
	insmod iso9660
	loopback loop ${iso_syspath}
	linux (loop)/boot/x86/linux64 findiso=${iso_syspath} quiet
	initrd (loop)/boot/x86/initrd.xz
}
EOF
fi

if [ "$has_32bit" = 1 ]; then
  cat << EOF
menuentry "${namestring} (32-bit)" {
EOF
  printf '%s\n' "${prepare_boot_cache}"
  cat << EOF
	insmod iso9660
	loopback loop ${iso_syspath}
	linux (loop)/boot/x86/linux findiso=${iso_syspath} quiet
	initrd (loop)/boot/x86/initrd.xz
}
EOF
fi
