#!/bin/sh

# Copyright (C) 2012-2020 Ryan Finnie
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

PROGNAME="loopback-iso"

# Sadly, grub-mkconfig does not export all GRUB_* variables, so we
# must re-source the default files.
if test -f /etc/default/grub ; then
  . /etc/default/grub
fi
for x in /etc/default/grub.d/*.cfg ; do
  if [ -e "${x}" ]; then
    . "${x}"
  fi
done

if [ -f /usr/lib/grub/grub-mkconfig_lib ]; then
  . /usr/lib/grub/grub-mkconfig_lib
else
  # no grub file, so we notify and exit gracefully
  echo "${PROGNAME}: Cannot find grub config file" >&2
  exit 0
fi

# Configuration
[ -n "${GRUB_LOOPBACK_ISO}" ] || GRUB_LOOPBACK_ISO="/boot/loopback-iso"

# On the other hand, if set but doesn't exist...
if ! [ -e "${GRUB_LOOPBACK_ISO}" ]; then
  echo "${PROGNAME}: Cannot find ${GRUB_LOOPBACK_ISO}" >&2
  exit 0
fi

process_loopback_iso() {
  iso="$1"

  # Get the device path of the ISO's filesystem
  iso_device="$(${grub_probe} -t device ${iso})"

  # We can't cope with loop-mounted devices here.
  case "${iso_device}" in
    /dev/loop/*|/dev/loop[0-9]) return ;;
  esac

  iso_syspath="$(make_system_path_relative_to_its_root "${iso}")"
  prepare_boot_cache="$(prepare_grub_to_access_device ${iso_device} | sed -e "s/^/\t/")"

  echo "Found loopback ISO: ${iso}" >&2

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
if [ -d "${GRUB_LOOPBACK_ISO}" ]; then
  # If it's a directory, process all ISOs found inside
  for iso in "${GRUB_LOOPBACK_ISO}"/*.iso; do
    # Simple way to guard against glob failure (no *.iso in directory)
    [ -e "${iso}" ] || continue
    process_loopback_iso "${iso}"
  done
elif [ -e "${GRUB_LOOPBACK_ISO}" ]; then
  # If it's a file, just process it
  process_loopback_iso "${GRUB_LOOPBACK_ISO}"
fi
