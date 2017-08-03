TARGETS?=os-ovs os-swift os-nova os-neutron os-mysql os-glance os-rsync os-rabbitmq os-keepalived os-keystone os-haproxy os-mongodb os-ipxe os-redis os-cinder os-httpd
MODULES?=${TARGETS:=.pp.bz2}
DATADIR?=/usr/share
#INSTALL=?=install

all: ${TARGETS:=.pp.bz2}

%.pp.bz2: %.pp
	@echo Compressing $^ -\> $@
	bzip2 -9 $^

%.pp: %.te
	make -f ${DATADIR}/selinux/devel/Makefile $@

clean:
	rm -f *~ *.if *.tc *.pp *.pp.bz2
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



#install:
#	${INSTALL} -m 0644 ${TARGETS} \
#		${DESTDIR}${DATADIR}/targeted/modules

