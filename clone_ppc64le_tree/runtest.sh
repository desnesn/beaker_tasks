#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/clone_ppc64le_tree/.
#   Description: Clones ppc64le git tree into the /root directory
#   Author: Desnes A. Nunes do Rosario <desnesn@linux.vnet.ibm.com>
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

rlJournalStart
    rlPhaseStartSetup
	rlRun "yum -y install git gcc libffi-devel python3-devel openssl-devel" 0 "Install dependencies"
	rlCheckRpm git
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "git clone git://git.kernel.org/pub/scm/linux/kernel/git/powerpc/linux.git /root/linux-powerpc" 0 "Cloning powerpc git tree"
        rlAssertExists "/root/linux-powerpc"
	pushd /root/linux-powerpc
	rlRun "git checkout --track -b next origin/next" 0 "Cloning powerpc next branch"
	rlRun "git checkout --track -b fixes origin/fixes" 0 "Cloning powerc fixes branch"
	rlRun "git checkout master" 0 "Returning code to master branch"
	popd
    rlPhaseEnd

    rlPhaseStartCleanup
    rlPhaseEnd

rlJournalPrintText
rlJournalEnd
