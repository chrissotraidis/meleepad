# G5 fixed-plus-QoS contract rejection (PERF-210)

Date: 2026-08-30

Status: **POLICY COMBINATION UNSUPPORTED; NO PRODUCT BUILD; G5 OPEN**

## Question

PERF-191 rejected public fixed scheduling in a required order reversal, but
fixed policy clears the thread's requested QoS. Could fixed scheduling plus
the runner's previously tested user-interactive QoS form a distinct supported
combination that merits another host or product performance run?

## Primary-source contract

Apple's public libpthread header states that scheduling operations which are
incompatible with the QoS system unset the requested QoS. Such a thread is
permanently opted out of QoS, and later
`pthread_set_qos_class_self_np` calls fail with `EPERM`:

<https://github.com/apple-oss-distributions/libpthread/blob/main/include/pthread/qos.h>

Apple's XNU `thread_policy_set` implementation removes requested pthread QoS
before applying `THREAD_EXTENDED_POLICY`, while `timeshare=false` selects
`TH_MODE_FIXED`:

<https://github.com/apple-oss-distributions/xnu/blob/main/osfmk/kern/thread_policy.c>

The combination is therefore contractually suspect rather than an ordinary
two-flag configuration.

## Disposable readback preflight

A self-contained process performed exactly:

1. request `QOS_CLASS_USER_INTERACTIVE` at relative priority zero;
2. read pthread QoS plus `THREAD_EXTENDED_POLICY`;
3. set `timeshare=false` through public `thread_policy_set`;
4. read both policies again;
5. attempt to reapply user-interactive QoS; and
6. restore timeshare before exit.

Result:

```text
initial_qos_set=0
after_qos pthread_get=0 qos=33 relative=0 extended_get=0 timeshare=1 default=0
fixed_set=0
after_fixed pthread_get=0 qos=0 relative=0 extended_get=0 timeshare=0 default=0
qos_reapply=1 errno=1
after_qos_reapply pthread_get=0 qos=0 relative=0 extended_get=0 timeshare=0 default=0
timeshare_restore=0
```

QoS class 33 is user-interactive; zero is unspecified. Fixed mode succeeds and
immediately clears requested QoS. Reapplication fails with `EPERM` exactly as
documented, and readback remains fixed plus unspecified QoS. Timeshare
restoration succeeds.

The private binary SHA-256 was
`cbceebbce18734204c9636605a0c6b8c4efa50baa7851a4f773f65129fe6e828`
and was deleted after the readback.

## Decision

Do not rerun fixed scheduling, add a fixed-plus-QoS mode, use private policy
interfaces, or reinterpret the PERF-191 fixed arms as missing a supported
combination. Public macOS APIs make fixed scheduling and requested pthread QoS
mutually incompatible for this thread, and fixed alone already failed the
required reversal.

No Dolphin, product, module, configuration, ROM data, save, audio, graphics,
or netplay state changed. No game or Simulator ran. G5 remains open and G6
remains blocked.
