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
	rlRun "yum groupinstall -y \"Development Tools\" && yum -y install git vim wget libcxl-devel libocxl-devel ncurses-devel net-tools" 0 "Downloading HTX build and install dependencies"
	rlRun "git clone https://www.github.com/open-power/HTX.git $HTX_DIR" 0 "Cloning HTX git repo"
	pushd $HTX_DIR

        if [ "$(cat /etc/redhat-release | grep -oh "Red Hat")" == "Red Hat" ]; then
		version=$(cat /etc/redhat-release | grep -oh "[0-9]*[\.]*[0-9]*" | sed -e 's/\.//')
		if [ "$(uname -r | grep -oh "le")" == "le" ]; then
			htx_str="htxrhel${version}le"
		else
			htx_str="htxrhel${version}"
		fi
	elif [ "$(cat /etc/redhat-release | grep -oh "Fedora")" == "Fedora" ]; then
		version=$(cat /etc/redhat-release | grep -oh "[0-9]*[0-9]*")
		if [ "$(uname -r | grep -oh "le")" == "le" ]; then
			htx_str="htxfedora${version}le"
		else
			htx_str="htxfedora${version}"
		fi
	else
		htx_str="htxsles12"
	fi
	# else
	# 	htx_str="htxubuntu"
	# fi

	sed -i "s/HTX_RELEASE=\"htxubuntu\"/HTX_RELEASE=\"${htx_str}\"/" htx.mk
	sed -i 's/TOPDIR=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))/TOPDIR=\/root\/HTX/' htx.mk

	rlRun "make clean && make all && make tar" 0 "Compiling HTX"
	tar --touch -xvzf htx_package.tar.gz
	cd htx_package
	rlRun "./installer.sh -f" 0 "Installing HTX"
	popd
    rlPhaseEnd

    rlPhaseStartTest
	rlRun "su - htx" 0 "Executing HTX testsuite"
    rlPhaseEnd

    rlPhaseStartCleanup
    	rlFileSubmit /tmp/htxstats
	rlFileSubmit /tmp/htxerr
	rlFileSubmit /tmp/htxmsg
	rlFileSubmit /tmp/HTXScreenOutput
	rlFileSubmit /tmp/htx.start.stop.time
	# rm -rf $HTX_DIR
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
