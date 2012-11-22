#!/bin/sh

# finnix-colors.sh
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

# ANSI colors
CR=""
CRE="[K"
ESC=""
NORMAL="[0;39m"
RED="[1;31m"
GREEN="[1;32m"
YELLOW="[1;33m"
BLUE="[1;34m"
MAGENTA="[1;35m"
CYAN="[1;36m"
WHITE="[1;37m"

# Finnix shortcuts
BLUEITEM="${WHITE}[${BLUE}*${WHITE}]${NORMAL}"
YELLOWITEM="${WHITE}[${YELLOW}*${WHITE}]${NORMAL}"
REDITEM="${WHITE}[${RED}*${WHITE}]${NORMAL}"
