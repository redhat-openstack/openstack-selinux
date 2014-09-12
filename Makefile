TARGETS?=os-ovs os-swift os-nova os-neutron os-mysql os-glance os-rsync os-rabbitmq
MODULES?=${TARGETS:=.pp.bz2}
SHAREDIR?=/usr/share
#INSTALL=?=install

all: ${TARGETS:=.pp.bz2}

%.pp.bz2: %.pp
	@echo Compressing $^ -\> $@
	bzip2 -9 $^

%.pp: %.te
	make -f ${SHAREDIR}/selinux/devel/Makefile $@

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


#install:
#	${INSTALL} -m 0644 ${TARGETS} \
#		${DESTDIR}${SHAREDIR}/targeted/modules

