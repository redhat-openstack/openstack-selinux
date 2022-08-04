Here is a list of common issues and tips on how to debug them.

How to resolve 'SELinux boolean os_enable_vtpm does not exist.'?
----------------------------------------------------------------
How to resolve 'Missing os-ovs! [...] Found XX missing modules' errors?
-----------------------------------------------------------------------

Either of these errors means that the `openstack-selinux` package could
not be installed properly, which can happen for a number of
reasons. Usually, it indicates a missing dependency or that a symbol
required by a policy is not defined on the system.

A few tips that may help to debug:

* Try to reinstall the package and look carefully at the output. There
  should be some kind of warning. If you need to open a bug, make sure
  to include this output in the report as this is the real error.

        # dnf reinstall openstack-selinux

* Confirm that `container-selinux` is present and also installed
  correctly.` openstack-selinux` depends on the symbols defined in it
  and will also fail if the package isn't properly installed on the
  system. You can check that by running the following command (this may
  require installing `setools-console`):

        $ seinfo --type | grep container

  This should return at least a dozen types. If seinfo only returns
  three container symbols or less, `container-selinux` is missing or
  not installed properly. You can try to reinstall the rpm to look for
  a trace with more information.

Switching to Permissive mode resolves my problem but there are no denials in the audit logs
-------------------------------------------------------------------------------------------

You may be hitting an issue with `dontaudit` rules. You can temporarily
allow SELinux to log these with the following command:

    # semodule -DB

This will rebuild the policy. Once you have reproduced the issue and
are able to check the logs, you can revert back with:

    # semodule -B
