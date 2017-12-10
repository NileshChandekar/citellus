#!/bin/bash

# Copyright (C) 2017   Robin Černín (rcernin@redhat.com)

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# description: Checks if running kernel is the one last installed

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

# we can run this against fs snapshot or live system

if [ "x$CITELLUS_LIVE" = "x0" ]; then
    FILE="${CITELLUS_ROOT}/uname"
elif [ "x$CITELLUS_LIVE" = "x1" ];then
    FILE=$(mktemp)
    trap "rm $FILE" EXIT
    uname -a > $FILE
fi

is_required_file "$FILE"
running_kernel=$(cut -d" " -f3 "$FILE" | sed -r 's/(^([0-9]+\.){2}[0-9]+-[0-9]+).*$/\1/')

is_required_file "${CITELLUS_ROOT}/var/log/yum.log"
nkernel=$(grep "\skernel-[0-9]" "${CITELLUS_ROOT}/var/log/yum.log")
if [[ -z "$nkernel" ]]; then
    echo $"no kernel install or update found in yum.log"
    exit $RC_OKAY
fi

installed_kernel=$(grep "\skernel-[0-9]" "${CITELLUS_ROOT}/var/log/yum.log" | tail -1 \
    | awk '{print $NF}' |  sed -r 's/[a-z]*-(([0-9]+\.){2}[0-9]+-[0-9]+).*$/\1/')


if [[ "$running_kernel" == "$installed_kernel" ]]; then
    echo $"running kernel same as latest installed kernel" >&2
    exit $RC_OKAY
else
    echo $"detected running kernel: $running_kernel latest installed $installed_kernel" >&2
    exit $RC_FAILED
fi