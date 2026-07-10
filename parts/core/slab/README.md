# Slab

Slab is the first bootloader the firmware runs.
It enforces a TPM anti-rollback floor and then chainloads the next stage.
It replaces shim in the boot chain.

## Why

Where disk encryption is used, its key is sealed to TPM PCR 7,
so it unlocks only when PCR 7 holds the expected value.
Slab ties bootloader anti-rollback to that PCR 7 without disturbing it on a
normal update.
A normal update still unlocks the disk,
but a rolled-back or tampered device cannot decrypt it.

## How

The boot chain is firmware to slab to the next stage to the operating system.
On each boot slab does the following.

1. Reads a monotonic counter and a base from the TPM,
   and extends the base into PCR 7.
2. Computes the logical version as counter minus base,
   and refuses a slab below it.
3. Raises the counter to its own revocation list version and write-locks it.
4. Checks the next stage version against a revocation list compiled into slab.
5. Chainloads the next stage, or powers the machine off on any failure.

Slab extends only the base into PCR 7, not the counter and not the list version.
The counter can initialize to an arbitrary value depending on the TPM history,
so slab records its starting value as the base.
Raising the counter to a newer revocation version leaves the base,
and therefore PCR 7, unchanged,
so a normal revocation list update keeps unlocking the disk.

Forcing an older version back means lowering the logical version,
the counter minus the base.
An attacker can go after the counter or the base, and neither works.

The counter cannot be lowered.
Direct write (NV_Write) is rejected on a counter,
and undefining then redefining it returns a value above any it ever held,
so it only comes back higher.
The Trusted Platform Module 2.0 Library Specification (version 185, March 2026),
section 31.2 NV Counters, states:

> When an NV counter is incremented for the first time, the TPM shall
> initialize the 8-octet counter value with a number that is greater than
> any value that a counter Index with the same Name has had over the
> lifetime of the TPM.
>
> Note: The Reference Code implements this by tracking and using the largest
> count of any deleted NV Counter. An alternative implementation could track
> the largest count of any NV Counter, deleted or currently defined.

The base is an ordinary writable index,
so raising or redefining it would lower the logical version.
But slab extends the base into PCR 7,
so a changed base changes PCR 7 and an encrypted disk no longer unlocks.

Slab does not make rollback impossible.
It makes a rolled-back or tampered device unable to decrypt its disk,
which is the property that matters.

## Build

```
make build          builds the release binary
make install        installs the unsigned slab and the tools
```

## Develop and test

```
make test           builds and runs every QEMU test harness
make test-binary    debug build the harnesses boot
```

The harnesses need QEMU, OVMF, swtpm and the tpm2 tools.

## Tools

```
slab-info                   shows the counter, base and version from the TPM
slab-debug on|off|status    toggles slab progress output at boot
```
