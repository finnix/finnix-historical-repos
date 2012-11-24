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
PROGNAME="grub-finnix"

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

process_finnix_iso() {
  iso="$1"

  # Grab some information from the ISO
  is_finnix=0
  namestring="Finnix"
  kernel_x86_linux=""
  kernel_x86_linux64=""
  kernel_amd64_linux=""
  initrd_x86=""
  initrd_amd64=""
  tempmount="$(mktemp -d)"

  if ! mount -o ro,loop "${iso}" "${tempmount}"; then
    echo "${PROGNAME}: Cannot mount ${iso}" >&2
    rmdir "${tempmount}"
    return
  fi
  [ -d "${tempmount}/finnix" ] && is_finnix=1
  [ -e "${tempmount}/boot/x86/linux" ] && kernel_x86_linux="/boot/x86/linux"
  [ -e "${tempmount}/boot/x86/linux64" ] && kernel_x86_linux64="/boot/x86/linux64"
  [ -e "${tempmount}/boot/amd64/linux" ] && kernel_amd64_linux="/boot/amd64/linux"

  if [ -e "${tempmount}/boot/x86/initrd.xz" ]; then
    initrd_x86="/boot/x86/initrd.xz"
  elif [ -e "${tempmount}/boot/x86/initrd.gz" ]; then
    initrd_x86="/boot/x86/initrd.gz"
  elif [ -e "${tempmount}/boot/x86/initrd" ]; then
    initrd_x86="/boot/x86/initrd"
  fi

  if [ -e "${tempmount}/boot/amd64/initrd.xz" ]; then
    initrd_amd64="/boot/amd64/initrd.xz"
  elif [ -e "${tempmount}/boot/amd64/initrd.gz" ]; then
    initrd_amd64="/boot/amd64/initrd.gz"
  elif [ -e "${tempmount}/boot/amd64/initrd" ]; then
    initrd_amd64="/boot/amd64/initrd"
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

  # Check for error conditions
  if [ "$is_finnix" = 0 ]; then
    echo "${PROGNAME}: ${iso} not a valid ${namestring} ISO" >&2
    return
  fi

  if [ -n "$kernel_x86_linux" ] && [ -z "$initrd_x86" ]; then
    kernel_x86_linux=""
  fi
  if [ -n "$kernel_x86_linux64" ] && [ -z "$initrd_x86" ]; then
    kernel_x86_linux64=""
  fi
  if [ -n "$kernel_amd64_linux" ] && [ -z "$initrd_amd64" ]; then
    kernel_amd64_linux=""
  fi
  if [ -z "${initrd_x86}${initrd_amd64}" ]; then
    echo "${PROGNAME}: ${iso} contains no valid initrds" >&2
    return
  fi

  # Get the device path of the ISO's filesystem
  iso_device="$(${grub_probe} -t device ${iso})"

  # We can't cope with loop-mounted devices here.
  case ${iso_device} in
    /dev/loop/*|/dev/loop[0-9]) return ;;
  esac

  iso_syspath="$(make_system_path_relative_to_its_root "${iso}")"
  prepare_boot_cache="$(prepare_grub_to_access_device ${iso_device} | sed -e "s/^/\t/")"

  echo "${PROGNAME}: Found ${namestring} ISO" >&2
  echo "    File: ${iso}" >&2
  echo "    Device: ${iso_device}" >&2
  if ! [ "${iso}" = "${iso_syspath}" ]; then
    echo "    Location on device: ${iso_syspath}" >&2
  fi
  echo -n "    Kernels:" >&2
  [ -n "$kernel_x86_linux" ] && echo -n " 32-bit" >&2
  [ -n "$kernel_x86_linux64" ] && echo -n " 64-bit" >&2
  [ -n "$kernel_amd64_linux" ] && echo -n " 64-bit (AMD64)" >&2
  echo >&2

  if [ -n "$kernel_x86_linux64" ]; then
    cat << EOF
menuentry "${namestring} (64-bit)" {
EOF
    printf '%s\n' "${prepare_boot_cache}"
    cat << EOF
	insmod iso9660
	loopback loop ${iso_syspath}
	linux (loop)${kernel_x86_linux64} findiso=${iso_syspath} ${EXTRA_OPTS}
	initrd (loop)${initrd_x86}
}
EOF
  fi

  if [ -n "$kernel_x86_linux" ]; then
    cat << EOF
menuentry "${namestring} (32-bit)" {
EOF
    printf '%s\n' "${prepare_boot_cache}"
    cat << EOF
	insmod iso9660
	loopback loop ${iso_syspath}
	linux (loop)${kernel_x86_linux} findiso=${iso_syspath} ${EXTRA_OPTS}
	initrd (loop)${initrd_x86}
}
EOF
  fi

  if [ -n "$kernel_amd64_linux" ]; then
    cat << EOF
menuentry "${namestring} (64-bit AMD64)" {
EOF
    printf '%s\n' "${prepare_boot_cache}"
    cat << EOF
	insmod iso9660
	loopback loop ${iso_syspath}
	linux (loop)${kernel_amd64_linux} findiso=${iso_syspath} ${EXTRA_OPTS}
	initrd (loop)${initrd_amd64}
}
EOF
  fi

} # END process_finnix_iso()

# Look for Finnix ISOs
if [ -d "${FINNIX_ISO}" ]; then
  # If it's a directory, process all ISOs found inside
  for iso in "${FINNIX_ISO}"/*.iso; do
    # Simple way to guard against glob failure (no *.iso in directory)
    [ -e "${iso}" ] || continue
    process_finnix_iso "${iso}"
  done
else
  # If it's a file, just process it
  process_finnix_iso "${FINNIX_ISO}"
fi
