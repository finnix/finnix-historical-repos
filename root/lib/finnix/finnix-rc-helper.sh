#!/bin/sh

# finnix-rc-helper.sh
# Copyright (C) 2011 Ryan Finnie
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

PATH="/bin:/sbin:/usr/bin:/usr/sbin"
export PATH

umask 022

. /lib/finnix/finnix-colors.sh
. /lib/finnix/finnix-functions.sh

# Read in boot parameters
CMDLINE="$(cat /proc/cmdline)"

# Get arch
ARCH="$(uname -m)"

FINNIX_FORENSIC="no"
FINNIX_DEBUG="no"
FINNIX_XEN="no"
FINNIX_XENU="no"
FINNIX_XENU_OLD="no"
FINNIX_XENU_NEW="no"
FINNIX_UML="no"
FINNIX_NOEJECT="no"
if [ -f /etc/finnix/initrd.env ]; then
  . /etc/finnix/initrd.env
fi

# Line clearing screws up readability in debug mode
[ "${FINNIX_DEBUG}" = "yes" ] && CRE="
"

