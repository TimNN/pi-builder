#!/usr/bin/env bash

########################################################################
#
# Copyright (C) 2015 Martin Wimpress <code@ubuntu-mate.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
########################################################################

set -ex

if [ -f build-settings.sh ]; then
    source build-settings.sh
else
    echo "ERROR! Could not source build-settings.sh."
    exit 1
fi

if [ $(id -u) -ne 0 ]; then
    echo "ERROR! Must be root."
    exit 1
fi

function make_hash() {
    local FILE="${1}"
    local HASH="${2}"
    if [ -f ${FILE} ]; then
        ${HASH}sum ${FILE} > ${FILE}.${HASH}
        sed -i -r "s/ .*\/(.+)/  \1/g" ${FILE}.${HASH}
    else
        echo "WARNING! Didn't find ${FILE} to hash."
    fi
}

function publish_image() {
    source ${HOME}/Roaming/Scripts/dest
    local HASH=md5
    if [ -n "${DEST}" ]; then
        echo "Sending to: ${DEST}"
        if [ ! -e "${BASEDIR}/${IMAGE}.bz2" ]; then
            bzip2 ${BASEDIR}/${IMAGE}
        fi
        make_hash "${BASEDIR}/${IMAGE}.bz2" ${HASH}
        rsync -rvl -e 'ssh -c arcfour128' --progress "${BASEDIR}/${IMAGE}.bz2" ${DEST}:ISO-Mirror/${RELEASE}/armhf/
        rsync -rvl -e 'ssh -c arcfour128' --progress "${BASEDIR}/${IMAGE}.bz2.${HASH}" ${DEST}:ISO-Mirror/${RELEASE}/armhf/
    fi
}

function publish_tarball() {
    if [ ${MAKE_TARBALL} -eq 1 ]; then
        source ${HOME}/Roaming/Scripts/dest
        local HASH=md5
        if [ -n "${DEST}" ]; then
            if [ ! -e "${BASEDIR}/${TARBALL}" ]; then
                echo "ERROR! Could not find ${TARBALL}. Exitting."
                exit 1
            fi
            make_hash "${BASEDIR}/${TARBALL}" ${HASH}
            echo "Sending to: ${DEST}"
            rsync -rvl -e 'ssh -c arcfour128' --progress "${BASEDIR}/${TARBALL}" ${DEST}:ISO-Mirror/${RELEASE}/armhf/
            rsync -rvl -e 'ssh -c arcfour128' --progress "${BASEDIR}/${TARBALL}.${HASH}" ${DEST}:ISO-Mirror/${RELEASE}/armhf/
        fi
    fi
}

publish_image
publish_tarball
