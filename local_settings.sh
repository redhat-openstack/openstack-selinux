#!/bin/bash

QUIET=1
MODE=0
BINDIR=${BINDIR:-/usr/bin}
SBINDIR=${SBINDIR:-/sbin}
LOCALSTATEDIR=${LOCALSTATEDIR:-/var}
DATADIR=${DATADIR:-/usr/share}
SHAREDSTATEDIR=${SHAREDSTATEDIR:-/var/lib}
MODULES=""


do_echo() {
	if [ $QUIET -eq 0 ]; then
		return
	fi
	echo $*
}


relabel_files()
{
	do_echo "Relabeling files..."
	$SBINDIR/restorecon -Rv $BINDIR/swift* \
				$LOCALSTATEDIR/run/swift \
				$SHAREDSTATEDIR/nova/.ssh \
				$SHAREDSTATEDIR/designate/bind9 \
                $SHAREDSTATEDIR/vhost_sockets \
				/srv \
				$BINDIR/neutron* \
				$LOCALSTATEDIR/run/redis \
				$LOCALSTATEDIR/log \
	&> /dev/null || :
}


install_policies() {
	do_echo "Setting up ports..."
	#
	# Port rules
	#
	# bz#1107873
	$SBINDIR/semanage port -N -a -t amqp_port_t -p tcp 15672 &> /dev/null

	# bz#1118859
	$SBINDIR/semanage port -N -m -t mysqld_port_t -p tcp 4444 &> /dev/null

	# bz#1260202
	$SBINDIR/semanage port -N -m -t openvswitch_port_t -p tcp 6653 &> /dev/null

	# bz#1360434
	$SBINDIR/semanage port -N -m -t http_port_t -p tcp 8088 &> /dev/null

	# bz#1396553
	$SBINDIR/semanage port -N -m -t http_port_t -p tcp 8000 &> /dev/null

	#
	# Booleans & file contexts
	#
	CR=$'\n'
	INPUT="boolean -N -m --on virt_use_fusefs
	boolean -N -m --on glance_use_fusefs
	boolean -N -m --on haproxy_connect_any
	boolean -N -m --on nis_enabled
	boolean -N -m --on rsync_full_access
	boolean -N -m --on rsync_client
	boolean -N -m --on virt_use_execmem
	boolean -N -m --on virt_use_nfs
	boolean -N -m --on daemons_enable_cluster_mode
	boolean -N -m --on glance_use_execmem
	boolean -N -m --on httpd_execmem
	boolean -N -m --on domain_kernel_load_modules
	boolean -N -m --on httpd_can_network_connect
	boolean -N -m --on swift_can_network
	boolean -N -m --on httpd_use_openstack
	fcontext -N -a -t named_zone_t \"$SHAREDSTATEDIR/designate/bind9(/.*)?\"
	fcontext -N -a -t virt_cache_t \"$SHAREDSTATEDIR/vhost_sockets(/.*)?\"
	fcontext -N -a -t httpd_var_lib_t $SHAREDSTATEDIR/openstack-dashboard
	fcontext -N -a -t httpd_log_t $LOCALSTATEDIR/log/gnocchi/app.log
	fcontext -N -a -t httpd_log_t $LOCALSTATEDIR/log/aodh/app.log
	fcontext -N -a -t httpd_log_t $LOCALSTATEDIR/log/ceilometer/app.log
	fcontext -N -a -t httpd_log_t $LOCALSTATEDIR/log/panko/app.log
	fcontext -N -a -t neutron_exec_t $BINDIR/neutron-rootwrap-daemon
	fcontext -N -a -t neutron_exec_t $BINDIR/neutron-metadata-agent
	fcontext -N -a -t neutron_exec_t $BINDIR/neutron-netns-cleanup
	fcontext -N -a -t neutron_exec_t $BINDIR/neutron-ns-metadata-proxy
	fcontext -N -a -t neutron_exec_t $BINDIR/neutron-vpn-agent"

	#
	# Append modules
	#
	for x in $MODULES; do
		INPUT="${INPUT}${CR}module -N -a $DATADIR/selinux/packages/$x.pp.bz2"
	done

	#
	# Do everything in one transaction, but don't reload policy
	# in case we're in a chroot environment.
	#
	do_echo "Installing OpenStack extra policies and setting booleans..."
	echo "$INPUT" | $SBINDIR/semanage import -N

	if $SBINDIR/selinuxenabled ; then
		do_echo "Reloading SELinux policies..."
		#
		# Chroot environments (e.g. when building images)
		# won't get here, but the image will apply all of
		# the policy on a reboot.
		#
		$SBINDIR/load_policy

		do_echo "Setting OpenStack booleans..."
		# Unfortunately, we can't load modules and set
		# booleans in those modules in a single transaction
		setsebool -P os_nova_use_execmem on
		setsebool -P os_neutron_use_execmem on
		setsebool -P os_swift_use_execmem on
		setsebool -P os_keystone_use_execmem on

		relabel_files
	fi
}


uninstall_policies() {
	do_echo "Removing OpenStack modules..."
	$SBINDIR/semodule -n -r $MODULES &> /dev/null || :
	if $SBINDIR/selinuxenabled ; then
		$SBINDIR/load_policy
		relabel_files
	fi
}


while getopts m:xq opt; do
	case $opt in
	m)	# modules
		MODULES="$OPTARG"
		;;
	x)	# uninstall
		MODE=1
		;;
	q)
		QUIET=0
		;;
	esac
done


case $MODE in
	0)
		install_policies
		;;
	1)
		uninstall_policies
		;;
esac
exit $?
