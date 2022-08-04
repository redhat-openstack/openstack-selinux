How to report a bug
-------------------

1. Set the system to Permissive and reproduce the issue (*)
2. When reporting the issue, include the permissive audit logs as well
3. The `audit2allow` output can be helpful to include in the report
   when it's limited to the denials relevant to the issue, but it is
   not enough on its own. It's essential to also include the actual AVC
   denials (and ideally, the full permissive audit logs around the time
   the issue is triggered.)

If a bug doesn't already exist on Launchpad or Bugzilla, create a [RDO
bug](https://bugzilla.redhat.com/enter_bug.cgi?product=RDO) with the
`openstack-selinux` component. Having a bug number is necessary to add
unit tests.

(*) In Enforcing mode, SELinux stops at the first denial which can hide
    more of them. Permissive mode enables us to see the full list of
    AVC denials, so that they can be resolved all at once rather than
    one at a time.

How to run the tests
--------------------

1. Install the `selinux-policy-devel` package
2. Ensure the path `/usr/share/openstack-selinux/master` exists
3. From your local openstack-selinux repository, run the following
   command as root:

        $ make clean all install check

It is recommended to use a VM for this.

Fixing an issue
----------------

If you are certain a new SELinux rule is necessary, consider a patch
with the minimum amount of new rules. If some of the rules are too
wide, the original code may need to change to allow more restricted
policy changes. If that's really not possible, the new rules may need
to be hidden behind a new boolean that stays turned off by default,
except in specific deployment scenarios.

When preparing the patch, include the denials fixed by the new rule in
a test file under tests/ to confirm the fix and avoid future
regressions.

Note: a test file won't help in the case of booleans turned off by
default. In that case, include the denials in the commit message
instead to help reviewers with understanding the issue being resolved
and keeping a record.
