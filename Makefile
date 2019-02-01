TARGETS?=os-ovs os-swift os-nova os-neutron os-mysql os-glance os-rsync os-rabbitmq os-keepalived os-keystone os-haproxy os-mongodb os-ipxe os-redis os-cinder os-httpd os-gnocchi os-collectd os-virt os-dnsmasq os-octavia os-podman os-rsyslog
MODULES?=${TARGETS:=.pp.bz2}
DATADIR?=/usr/share
LOCALDIR?=/usr/share/openstack-selinux/master
INSTALL?=install
MODULE_TYPE?=services

all: ${TARGETS:=.pp.bz2} local_settings.sh

%.pp.bz2: %.pp
	@echo Compressing $^ -\> $@
	bzip2 -9 $^

%.pp: %.te
	make -f ${DATADIR}/selinux/devel/Makefile $@

local_settings.sh: local_settings.sh.in
	sed -e 's/@MODULES@/${TARGETS}/' $^ > $@
	chmod 0755 $@

clean:
	rm -f *~ *.if *.tc *.pp *.pp.bz2 local_settings.sh
	rm -rf tmp *.tar.gz

tarball: .git/config
	#
	# Downloading tarball.  Note: this only works if the
	# current HEAD matches a previously-pushed tag.
	#
	@RELEASE=$$(git tag --points-at=$$(git log -1 | awk '/^commit/ { print $$2 }')) ;\
	if [ -z "$$RELEASE" ]; then				\
		echo "Failed.  Try 'git tag' first."		;\
	else							\
		rm -f openstack-selinux-$$RELEASE.tar.gz	;\
		wget -O openstack-selinux-$$RELEASE.tar.gz \
			https://github.com/redhat-openstack/openstack-selinux/archive/$$RELEASE.tar.gz ;\
	fi

local-tarball: .git/config
	#
	# Creating local tarball.  Note: this only works if the
	# current HEAD matches a tag.
	#
	@RELEASE=$$(git tag --points-at=$$(git log -1 | awk '/^commit/ { print $$2 }')) ;\
	if [ -z "$$RELEASE" ]; then				\
		echo "Failed.  Try 'git tag' first."		;\
	else							\
		TMPDIR=$$(mktemp /tmp/os-XXXXXX)		;\
		rm -f openstack-selinux-$$RELEASE.tar.gz	;\
		make clean					;\
		rm -f $$TMPDIR					;\
		mkdir -p $$TMPDIR/openstack-selinux-$$RELEASE	;\
		cp -a . $$TMPDIR/openstack-selinux-$$RELEASE	;\
		if pushd $$TMPDIR/openstack-selinux-$$RELEASE; then \
			rm -rf .git .git*				;\
			cd ..						;\
			tar -czvf openstack-selinux-$$RELEASE.tar.gz openstack-selinux-$$RELEASE ;\
			popd						;\
			cp $$TMPDIR/*.tar.gz .				;\
			rm -rf $$TMPDIR					;\
		else						\
			false					;\
		fi						;\
	fi

install:
	# Install the setup script
	${INSTALL} -d ${LOCALDIR}
	${INSTALL} -m 0755 local_settings.sh ${LOCALDIR}

	# Install tests
	${INSTALL} -d ${LOCALDIR}/tests
	${INSTALL} -m 0644 tests/bz* ${LOCALDIR}/tests
	${INSTALL} -m 0755 tests/check_all ${LOCALDIR}/tests

	# Install interfaces
	${INSTALL} -d ${DATADIR}/selinux/devel/include/${MODULE_TYPE}
	${INSTALL} -m 0644 ${TARGETS:=.if} ${DATADIR}/selinux/devel/include/${MODULE_TYPE}

	# Install policy modules
	${INSTALL} -d ${DATADIR}/selinux/packages
	${INSTALL} -m 0644 ${TARGETS:=.pp.bz2} ${DATADIR}/selinux/packages

# Note: You can't run this in a build system unless the build 
#       system has access to change the kernel SELinux policies
check:
	cd ${LOCALDIR} && ./local_settings.sh			;\
	cd ${LOCALDIR}/tests && ./check_all			;\
	RET=$$?							;\
	cd ${LOCALDIR} && ./local_settings.sh -x		;\
	if [[ "$$RET" -ne 0 ]]; then				\
		/bin/false					;\
	else							\
		/bin/true					;\
	fi
