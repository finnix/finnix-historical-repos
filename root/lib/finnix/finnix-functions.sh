#!/bin/sh

# finnix-functions.sh
# Copyright (C) 2011 Ryan Finnie
# Includes code (C) Klaus Knopper
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

### Utility Function(s)

# Simple shell grep
stringinfile(){
  case "$(cat $2)" in *$1*) return 0;; esac
  return 1
}

# same for strings
stringinstring(){
  case "$2" in *$1*) return 0;; esac
  return 1
}

# Reread boot command line; echo last parameter's argument or return false.
getbootparam(){
  stringinstring " $1=" "randomstring $CMDLINE randomstring" || return 1
  result="${CMDLINE##*$1=} randomstring"
  # Note: the second whitespace is a tab
  result="${result%%[ 	]*}"
  echo "$result"
  return 0
}

# Same as getbootparam, but returns all instances, one per line.
# Big difference is $2 must be $CMDLINE
getbootparammulti(){
  local result
  stringinstring " $1=" "randomstring $2 randomstring" || return 1
  result="${2#*$1=} randomstring"
  # Note: the second whitespace is a tab
  getbootparammulti $1 "${result#*[ 	]}"
  # Note: the second whitespace is a tab
  result="${result%%[ 	]*}"
  echo "$result"
  return 0
}

# Check boot commandline for specified option
checkbootparam(){
  stringinstring " $1 " "randomstring $CMDLINE randomstring"
  return "$?"
}

# Filter stdout/stderr, unless debug mode is on
_f12() {
  if [ "${FINNIX_DEBUG}" = "yes" ]; then
    "$@"
  else
    "$@" >/dev/null 2>/dev/null
  fi
}

# Filter stderr, unless debug mode is on
_f2() {
  if [ "${FINNIX_DEBUG}" = "yes" ]; then
    "$@" 
  else
    "$@" 2>/dev/null
  fi
}


# Conditional complement to invoke-rc.d
can_invoke_rcd() {
  ret=0
  invoke-rc.d --quiet --query "$@" || ret=$?
  case $ret in
    104|105)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

### EOF utility functions
