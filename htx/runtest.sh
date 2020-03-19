#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /performance/htx/.
#   Description: Downloads, build, install and run the HTX testsuite
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

HTX_DIR="/root/HTX"

rlJournalStart
    rlPhaseStartSetup
	rlRun "yum groupinstall -y \"Development Tools\" && yum -y install git vim wget ncurses-devel libcxl libcxl-devel libocxl libocxl-devel dapl-devel net-tools" 0 "Downloading HTX build and install dependencies"
	rlRun "git clone https://www.github.com/open-power/HTX" 0 "Cloning HTX git repo"
	pushd $HTX_DIR
	make all && make tar
	tar xvf htx_package.tar.gz
	cd htx_package
	./installer.sh -f
	popd
    rlPhaseEnd

    rlPhaseStartTest
	rlRun "su - htx" 0 "Executing HTX testsuite"
    rlPhaseEnd

    # rlPhaseStartCleanup
    # rlPhaseEnd
rlJournalPrintText
rlJournalEnd
