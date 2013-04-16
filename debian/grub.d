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

DEFAULTFILE=/etc/default/grub-loopback-iso
PROGNAME="grub-loopback-iso"

if [ -f /usr/lib/grub/grub-mkconfig_lib ]; then
  . /usr/lib/grub/grub-mkconfig_lib
else
  # no grub file, so we notify and exit gracefully
  echo "${PROGNAME}: Cannot find grub config file" >&2
  exit 0
fi

# Read in the location of the ISO
if [ -f "$DEFAULTFILE" ]; then
  . "$DEFAULTFILE"
else
  exit 0
fi

# Check if the user has set LOOPBACK_ISO
[ -n "${LOOPBACK_ISO}" ] || exit 0

# On the other hand, if set but doesn't exist...
if ! [ -e "${LOOPBACK_ISO}" ]; then
  echo "${PROGNAME}: Cannot find ${LOOPBACK_ISO}" >&2
  exit 0
fi

process_loopback_iso() {
  iso="$1"

  # Grab some information from the ISO
  is_valid_loopback=0
  tempmount="$(mktemp -d)"

  if ! mount -o ro,loop "${iso}" "${tempmount}"; then
    echo "${PROGNAME}: Cannot mount ${iso}" >&2
    rmdir "${tempmount}"
    return
  fi
  [ -e "${tempmount}/boot/grub/loopback.cfg" ] && is_valid_loopback=1
  umount "${tempmount}"
  rmdir "${tempmount}"

  # Check for error conditions
  if [ "$is_valid_loopback" = 0 ]; then
    echo "${PROGNAME}: ${iso} not a valid loopback ISO" >&2
    return
  fi

  # Get the device path of the ISO's filesystem
  iso_device="$(${grub_probe} -t device ${iso})"

  # We can't cope with loop-mounted devices here.
  case "${iso_device}" in
    /dev/loop/*|/dev/loop[0-9]) return ;;
  esac

  iso_syspath="$(make_system_path_relative_to_its_root "${iso}")"
  prepare_boot_cache="$(prepare_grub_to_access_device ${iso_device} | sed -e "s/^/\t/")"

  echo "${PROGNAME}: Found loopback ISO" >&2
  echo "    File: ${iso}" >&2
  echo "    Device: ${iso_device}" >&2
  if ! [ "${iso}" = "${iso_syspath}" ]; then
    echo "    Location on device: ${iso_syspath}" >&2
  fi

  cat << EOF
menuentry "GRUB Loopback Config (${iso})" {
EOF
  printf '%s\n' "${prepare_boot_cache}"
  cat << EOF
        set iso_path="${iso_syspath}"
        export iso_path
        insmod iso9660
        loopback loop "${iso_syspath}"
        set root=(loop)
        configfile /boot/grub/loopback.cfg
        loopback -d loop
}
EOF
} # END process_loopback_iso()

# Look for loopback ISOs
if [ -d "${LOOPBACK_ISO}" ]; then
  # If it's a directory, process all ISOs found inside
  for iso in "${LOOPBACK_ISO}"/*.iso; do
    # Simple way to guard against glob failure (no *.iso in directory)
    [ -e "${iso}" ] || continue
    process_loopback_iso "${iso}"
  done
else
  # If it's a file, just process it
  process_loopback_iso "${LOOPBACK_ISO}"
fi
