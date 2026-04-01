// Kernel module ioctl client. Provides the --kernel
// signing mode and the --load-keys key provisioning
// mode, both communicating with the kernel module via
// /dev/puavo-command-line-signer.

#ifndef KERNEL_CLIENT_H
#define KERNEL_CLIENT_H

// Runs the signing pipeline via the kernel module
// ioctl interface. Returns 0 on success, 1 on error.
int run_kernel_mode(int argument_count, char** arguments);

// Provisions keys into the kernel module via the
// LOAD_KEYS ioctl. Returns 0 on success, 1 on error.
int run_load_keys_mode(int argument_count, char** arguments);

#endif
