#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/ltp/.
#   Description: Compiles, installs and runs the latest LTP upstream testsuite
#   Author: Desnes Augusto Nunes do Rosario <desnesn@br.ibm.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2020 Red Hat, Inc.
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

LTP_DIR="/mnt/tests/github.com/desnesn/beaker_tasks/archive/master.zip/ltp/ltp"

rlJournalStart
    rlPhaseStartSetup
    	rlRun "yum groupinstall -y \"Development Tools\" && yum install -y ncurses-devel hmaccalc zlib-devel binutils-devel elfutils-libelf-devel git bc gcc make git ctags ncurses-devel openssl-devel glibc-static wget vim tmux" 0 "Installation of dependent packages for compiling and running LTP testsuite"

	rlRun "git clone https://github.com/linux-test-project/ltp.git" 0 "Clonning upstream LTP testsuite"
        rlRun "pushd $LTP_DIR"
	# rlRun "make autotools && ./configure && make && make install" 0 "Compiling and Installing LTP testsuite"
    rlPhaseEnd

    rlPhaseStartTest
        # rlRun "/opt/ltp/runltp" 0 "Running LTP"
	rlRun "$LTP_DIR/runltp" 0 "Running LTP"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
