#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /kernel/ppc64le_selftests/.
#   Description: Downloads, compiles and runs the ppc64le kernel testsuite
#   Author: Desnes Augusto Nunes do Rosario <desnesn@br.ibm.com>

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

rlJournalStart

	rlPhaseStartSetup

		# first we need to install rpms needed to build the kernel	
		rlRun "yum -y install asciidoc audit-libs-devel binutils-devel bison elfutils-devel flex gcc git m4 make ncurses-devel net-tools newt-devel numactl-devel openssl-devel pciutils-devel perl-Ext* perl-devel perl-generators"

		# next we need the rpm needed to build the powerpc tests	
	 	rlRun "python3-docutils xmlto xz-devel zlib-devel python3-devel rsync rpm-build java-devel kabi-dw libcap-devel libcap-ng-devel llvm-toolset"

		# next we need the rpm needed to build the powerpc tests
		rlRun "yum -y install glibc-static wget"

		# other tools
		rlRun "yum -y install vim dnf-utils tmux"

		if [ ! -f /etc/yum.repos.d/beaker-BaseOS-source.repo ]; then
			cp /etc/yum.repos.d/beaker-BaseOS.repo /etc/yum.repos.d/beaker-BaseOS-source.repo
			sed -i 's|ppc64le\/os|source\/tree|g' /etc/yum.repos.d/beaker-BaseOS-source.repo
			sed -i 's/beaker-BaseOS/beaker-BaseOS-source/g' /etc/yum.repos.d/beaker-BaseOS-source.repo
		fi

		rlRun "lscpu" 0 "Log CPU info"
		rlShowRunningKernel

		# now we need the kernel src rpm
		IFS=- read -a UNAME <<<$(uname -r)
		ARCH=$(uname -i)
		VERSION=${UNAME[0]}
		RELEASE=${UNAME[1]%%.$ARCH}

		rlRun "yumdownloader --source kernel" 0 "Downloading kernel source rpm"
		
		rlRun "rpm -ivh kernel-${VERSION}-${RELEASE}.src.rpm" 0 "Installing kernel source rpm"
		cd $HOME/rpmbuild/SOURCES
		tar -xf linux-${VERSION}-${RELEASE}.tar.xz
	rlPhaseEnd
	
	rlPhaseStartTest
		cd linux-${VERSION}-${RELEASE}/
		# SELFTESTSLOG=$(mktemp /mnt/testarea/selftests.XXXXXX)
		SELFTESTSLOG=/mnt/testarea/selftests.output
		SELFTESTSPASS=/mnt/testarea/selftests.pass
		SELFTESTSFAIL=/mnt/testarea/selftests.fail
		# MAKELEVEL=0 is needed to fool the kernel's tools/testing/selftests/lib.mk
		#   ifeq (0,$(MAKELEVEL))
		#   OUTPUT := $(shell pwd)
		#   endif
		# A Beaker task starts with 'make run', thus MAKELEVEL=1 for the selftests,
		# thus OUTPUT is not set, and the whole build fails.
		rlRun "make -C tools/testing/selftests/powerpc run_tests MAKELEVEL=0 >>$SELFTESTSLOG 2>&1" 0 "Running powerpc selftests"
		
		if lscpu | grep -q 'POWER9';then
			CPU=$(echo "POWER9 system" $SELFTESTLOG)
		else
			CPU=$(echo "POWER8 system" $SELFTESTLOG)
		fi
		HOSTNAME=$(echo `hostname` $SELFTESTLOG)
		PASSED=$(grep -c 'PASS' $SELFTESTSLOG)
		FAILED=$(grep -c 'FAIL' $SELFTESTSLOG)
		SKIPPED=$(grep -c 'SKIP' $SELFTESTSLOG)
		
		rlAssert0 "Assert 0 tests failed" $FAILED
		
		rlLog "$CPU"
		rlLog "$HOSTNAME"
		rlLog "Passed tests: $PASSED"
		rlLog "Failed tests: $FAILED"
		rlLog "Skipped tests: $SKIPPED"
		
		rlFileSubmit $SELFTESTSLOG SELFTESTS.LOG

		cat $SELFTESTSLOG | grep PASS > $SELFTESTSPASS
		cat $SELFTESTSLOG | grep FAIL > $SELFTESTSFAIL

		rlFileSubmit $SELFTESTSPASS SELFTESTS.PASS
		rlFileSubmit $SELFTESTSFAIL SELFTESTS.FAIL
	rlPhaseEnd
	
	rlPhaseStartCleanup
		rm -fr $HOME/rpmbuild
	rlPhaseEnd

	rlJournalPrintText
rlJournalEnd
