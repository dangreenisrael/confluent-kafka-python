#!/bin/bash
#

#
# Install the Confluent Control Center Monitoring Interceptors
# Primarily for CI use.
# Requires sudo.
#
# Usage: $0 tools/install-interceptors.sh
#

set -e

# pkgtype (rpm, deb, osx), will be empty on outer invocation.
pkgtype=$1

# Confluent Platform release version
CPVER=5.0

if [[ -z $pkgtype ]]; then
    # Automatic platform detection

    if [[ $(uname -s) == Darwin ]]; then
        exec $0 osx
    elif apt-get -v >/dev/null 2>&1; then
        # Debian, et.al.
        exec $0 deb
    elif yum version >/dev/null 2>&1; then
        # RHEL, et.al.
        exec $0 rpm
    else
        echo "$0: Unsupported platform: $(uname -s)"
        exit 1
    fi

elif [[ $pkgtype == rpm ]]; then
    rpm --import https://packages.confluent.io/rpm/${CPVER}/archive.key

    echo "
[Confluent.dist]
name=Confluent repository (dist)
baseurl=https://packages.confluent.io/rpm/${CPVER}/7
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/${CPVER}/archive.key
enabled=1

[Confluent]
name=Confluent repository
baseurl=https://packages.confluent.io/rpm/${CPVER}
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/${CPVER}/archive.key
enabled=1
" > /etc/yum.repos.d/confluent.repo

    yum install -y confluent-librdkafka-plugins

elif [[ $pkgtype == deb ]]; then
    need_pkgs=""
    if [[ ! -x /usr/bin/wget ]]; then
        need_pkgs="${need_pkgs} wget"
    fi
    if [[ ! -x /usr/bin/add-apt-repository ]]; then
        need_pkgs="${need_pkgs} software-properties-common"
    fi
    if [[ ! -x /usr/bin/gpg ]]; then
        need_pkgs="${need_pkgs} gnupg"
    fi
    if [[ ! -f /usr/lib/apt/methods/https ]]; then
        need_pkgs="${need_pkgs} apt-transport-https"
    fi

    if [[ -n $need_pkgs ]]; then
        echo "Installing $need_pkgs"
        apt-get update
        apt-get install -y $need_pkgs
    fi


    wget -qO - https://packages.confluent.io/deb/${CPVER}/archive.key | apt-key add -
    add-apt-repository "deb [arch=amd64] https://packages.confluent.io/deb/${CPVER} stable main"
    apt-get update
    apt-get install -y confluent-librdkafka-plugins

elif [[ $pkgtype == osx ]]; then

    wget -O monitoring.zip http://packages.confluent.io/archive/${CPVER}/confluent-librdkafka-plugins-0.11.0.zip
    unzip monitoring.zip monitoring-interceptor.dylib
    cp monitoring-interceptor.dylib /usr/local/lib

fi
