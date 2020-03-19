#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/clone_ppc64le_tree/.
#   Description: Clones ppc64le git tree into the /root directory
#   Author: John Doe <john.doe@email.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2019 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

# PACKAGE="git"
FOLDER="/root/linux-powerpc/"

rlJournalStart
    rlPhaseStartSetup

	# rlRpmInstall restraint-client
	# rlRpmInstall redhat-lsb-core

	# rlRpmInstall git
    	# Just to remember the syntax
	# if ! rlCheckRpm $PACKAGE; then
	#	rlRpmInstall $PACKAGE
	#	rlAssertRpm $PACKAGE
	# fi

	if [ "$(cat /etc/redhat-release | grep -oh "Red Hat")" == "Red Hat" ]; then
		major=$(cat /etc/redhat-release | grep -oh "[0-9]*[\.]*[0-9]*" | cut -c -1)
	elif [ "$(cat /etc/redhat-release | grep -oh "Fedora")" == "Fedora" ]; then
		major=$(cat /etc/redhat-release | grep -oh "[0-9]*[0-9]*")
	else
		major="?"
	fi

	if [ $major == "7" ] ; then
		rlRun "yum groupinstall -y \"Development Tools\" && yum install -y gcc make git ctags ncurses-devel openssl-devel net-tools xmlto asciidoc python-devel newt-devel perl\(ExtUtils::Embed\) elfutils-devel audit-libs-devel java-devel numactl-devel pciutils-devel hmaccalc binutils-devel ncurses-devel hmaccalc zlib-devel binutils-devel elfutils-libelf-devel git bc gcc make git ctags openssl ncurses-devel openssl-devel glibc-static wget vim tmux" 0 "Installing all dependencies to build upstream powerpc kernel on RHEL7"
	elif [ $major == "8" ] ; then
		rlRun "yum groupinstall -y \"Development Tools\" && yum install -y gcc make git ctags ncurses-devel openssl-devel net-tools xmlto asciidoc newt-devel perl\(ExtUtils::Embed\) elfutils-devel audit-libs-devel java-devel numactl-devel pciutils-devel hmaccalc binutils-devel ncurses-devel hmaccalc zlib-devel binutils-devel elfutils-libelf-devel git bc gcc make git ctags openssl ncurses-devel openssl-devel glibc-static wget vim tmux kabi-dw python3-devel python3-docutils net-tools xmlto asciidoc python3-devel python3-docutils newt-devel perl\(ExtUtils::Embed\) elfutils-devel audit-libs-devel java-devel numactl-devel pciutils-devel hmaccalc binutils-devel kabi-dw ncurses-devel openssl-devel" 0 "Installing all dependencies to build upstream powerpc kernel on RHEL8"
	else
		rlRun "yum groupinstall -y \"Development Tools\"" 0 "Installing just Development Tools to unknown RHEL-based distro release"
	fi

    rlPhaseEnd

    rlPhaseStartTest
        rlRun "git clone git://git.kernel.org/pub/scm/linux/kernel/git/powerpc/linux.git $FOLDER" 0 "Cloning git powerpc tree"

        rlAssertExists "$FOLDER"

	rlRun "pushd $FOLDER"
	rlRun "git checkout --track -b fixes origin/fixes" 0 "Checking out fixes branch"
	rlRun "git checkout --track -b next origin/next" 0 "Checkin out next branch"
	rlRun "git checkout master" 0 "Checking out master branch again"
	rlRun "popd"

    rlPhaseEnd

    rlPhaseStartCleanup
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
