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

		# Install dependencies and other toools
		rlRun "yum -y groupinstall -y \"Development Tools\""

		rlRun "yum -y install asciidoc audit-libs-devel bc binutils-devel bison clang ctags dnf-utils elfutils-devel elfutils-libelf-devel flex gcc git glibc-static hmaccalc java-devel kabi-dw kernel-debug kernel-debug-debuginfo libcap-devel libcap-ng-devel libmnl-devel llvm llvm-toolset m4 make ncurses-devel net-tools newt-devel numactl-devel openssl openssl-devel pciutils-devel perl-devel perl-Ext* perl\(ExtUtils::Embed\) perl-generators python3-devel python3-docutils rpm-build rsync tmux vim wget xmlto xz-devel zlib-devel"

		# Setup the src repo
		if [ ! -f /etc/yum.repos.d/beaker-BaseOS-source.repo ]; then
			cp /etc/yum.repos.d/beaker-BaseOS.repo /etc/yum.repos.d/beaker-BaseOS-source.repo
			sed -i 's|ppc64le\/os|source\/tree|g' /etc/yum.repos.d/beaker-BaseOS-source.repo
			sed -i 's/beaker-BaseOS/beaker-BaseOS-source/g' /etc/yum.repos.d/beaker-BaseOS-source.repo
		fi

		rlRun "lscpu" 0 "Log CPU info"
		rlShowRunningKernel
		rlRun "if [ -x /usr/bin/timeout ]; then mv /usr/bin/{,.}timeout ; fi" 0 "Conceal timeout"

		# Fetch the kernel src rpm
		IFS=- read -a UNAME <<<$(uname -r)
		ARCH=$(uname -i)
		VERSION=${UNAME[0]}
		RELEASE=${UNAME[1]%%.$ARCH}

		rlRun "yumdownloader --source kernel" 0 "Downloading kernel source rpm"
		
		rlRun "rpm -ivh kernel-${VERSION}-${RELEASE}.src.rpm" 0 "Installing kernel source rpm"
		pushd $HOME/rpmbuild/SOURCES
		tar -xf linux-${VERSION}-${RELEASE}.tar.xz

	rlPhaseEnd
	
	rlPhaseStartTest

		pushd linux-${VERSION}-${RELEASE}/

		# SELFTESTSLOG=$(mktemp /mnt/testarea/selftests.XXXXXX)
		SELFTESTSLOG=/mnt/testarea/selftests.log

		SELFTESTSPASS=/mnt/testarea/selftests.pass
		SELFTESTSFAIL=/mnt/testarea/selftests.fail
		SELFTESTSSKIP=/mnt/testarea/selftests.skip

		# MAKELEVEL=0 is needed to fool the kernel's tools/testing/selftests/lib.mk
		#   ifeq (0,$(MAKELEVEL))
		#   OUTPUT := $(shell pwd)
		#   endif
		# A Beaker task starts with 'make run', thus MAKELEVEL=1 for the selftests,
		# thus OUTPUT is not set, and the whole build fails.

		echo >> $SELFTESTSLOG
		echo "# PPC64LE KERNEL SELFTESTS #" >> $SELFTESTSLOG
		echo >> $SELFTESTSLOG

		CPU=$(lscpu | grep "Model")
		echo >> $SELFTESTSLOG
		echo $CPU >> $SELFTESTSLOG
		echo >> $SELFTESTSLOG

		HOSTNAME=$(hostname)
		echo >> $SELFTESTSLOG
		echo $HOSTNAME >> $SELFTESTSLOG
		echo >> $SELFTESTSLOG

		# Run selftests
		rlRun "make -C tools/testing/selftests/powerpc run_tests MAKELEVEL=0 >>$SELFTESTSLOG 2>&1" 0 "Running powerpc selftests"
		N_PASSED=$(grep -c '^ok' $SELFTESTSLOG)
		N_FAILED=$(grep -c '^not ok' $SELFTESTSLOG)
		N_SKIPPED=$(grep -c '# skip:' $SELFTESTSLOG)
		
		# rlAssert0 "Assert 0 tests failed" $N_FAILED

		PROC=$(lscpu | grep "Model" | awk '{ print $3 }' | sed 's/,//')
		rlLog "$PROC"
		rlLog "$HOSTNAME"
		rlLog "Passed tests: $N_PASSED"
		rlLog "Failed tests: $N_FAILED"
		rlLog "Skipped tests: $N_SKIPPED"
		
		rlRun "grep \"^ok\" $SELFTESTSLOG | awk '{print \$1\" \"\$3\$4\" \"\$5}' >> $SELFTESTSPASS"
		rlRun "sed -i 's/ok/pass:/g' $SELFTESTSPASS"
		rlRun "grep \"^not ok\" $SELFTESTSLOG | awk '{print \$1\" \"\$2\" \"\$4\$5\" \"\$6\" \"\$7\$8\" \"\$9}' >> $SELFTESTSFAIL"
		rlRun "sed -i 's/not ok/fail:/g' $SELFTESTSFAIL"
		rlRun "grep \"skip:\" $SELFTESTSLOG | awk '{print \$3}' >> $SELFTESTSSKIP"

		rlFileSubmit $SELFTESTSLOG SELFTESTS.LOG
		rlFileSubmit $SELFTESTSPASS SELFTESTS.PASS
		rlFileSubmit $SELFTESTSFAIL SELFTESTS.FAIL
		rlFileSubmit $SELFTESTSSKIP SELFTESTS.SKIP

		popd

	rlPhaseEnd
	
	rlPhaseStartCleanup

		popd

		rlRun "if [ -x /usr/bin/.timeout ]; then mv /usr/bin/{.,}timeout ; fi" 0 "Unconceal timeout"

	rlPhaseEnd

	rlJournalPrintText
rlJournalEnd
