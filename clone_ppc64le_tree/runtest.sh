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

PACKAGE="git"
FOLDER="/root/linux-powerpc/"

rlJournalStart
    rlPhaseStartSetup

    	# Just to remember the syntax
	if ! rlCheckRpm $PACKAGE; then
		rlRpmInstall $PACKAGE
		rlAssertRpm $PACKAGE
	fi

	if $(lsb_release -d | grep 7) -eq 0 ; then
		rlRun "yum groupinstall -y \"Development Tools\" && yum install -y gcc make git ctags ncurses-devel openssl-devel net-tools xmlto asciidoc python-devel newt-devel perl\(ExtUtils::Embed\) elfutils-devel audit-libs-devel java-devel numactl-devel pciutils-devel hmaccalc binutils-devel ncurses-devel hmaccalc zlib-devel binutils-devel elfutils-libelf-devel git bc gcc make git ctags openssl ncurses-devel openssl-devel glibc-static wget vim tmux" 0 "Downloading all dependencies to build upstream powerpc kernel on RHEL7"
	else
		rlRun "yum groupinstall -y \"Development Tools\" && yum install -y gcc make git ctags ncurses-devel openssl-devel net-tools xmlto asciidoc newt-devel perl\(ExtUtils::Embed\) elfutils-devel audit-libs-devel java-devel numactl-devel pciutils-devel hmaccalc binutils-devel ncurses-devel hmaccalc zlib-devel binutils-devel elfutils-libelf-devel git bc gcc make git ctags openssl ncurses-devel openssl-devel glibc-static wget vim tmux kabi-dw python3-devel python3-docutils net-tools xmlto asciidoc python3-devel python3-docutils newt-devel perl\(ExtUtils::Embed\) elfutils-devel audit-libs-devel java-devel numactl-devel pciutils-devel hmaccalc binutils-devel kabi-dw ncurses-devel openssl-devel" 0 "Downloading all dependencies to build kernel on RHEL8"
	fi

    rlPhaseEnd

    rlPhaseStartTest
        rlRun "git clone git://git.kernel.org/pub/scm/linux/kernel/git/powerpc/linux.git $FOLDER" 0 "Cloning git tree"

        rlAssertExists "$FOLDER"
	rlRun "pushd $FOLDER"

	rlRun "git checkout --track -b fixes origin/fixes"
	rlRun "git checkout --track -b next origin/next"

	git checkout master
    rlPhaseEnd

    rlPhaseStartCleanup
    	rlRun "popd"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
