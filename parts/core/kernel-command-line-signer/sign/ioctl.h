// Shared ioctl definitions for the
// puavo_command_line_signer kernel module. Used by both
// kernel_module.c (kernel side) and the userspace
// client code in sign.c.

#ifndef SIGN_IOCTL_H
#define SIGN_IOCTL_H

#ifdef __KERNEL__
#include <linux/types.h>
#include <linux/ioctl.h>
#else
#include <stdint.h>
#include <sys/ioctl.h>
#endif

#define PUAVO_COMMANDLINE_SIGN_IOC_MAGIC 'P'

struct puavo_command_line_sign_ioctl {
  // Input pointers (userspace addresses)
  uint64_t pe_data;
  uint64_t pe_size;
  uint64_t parameters;
  uint64_t parameters_size;
  uint64_t authorization;
  uint64_t authorization_size;
  uint64_t attributes_der;
  uint64_t attributes_der_size;
  uint64_t idc_data;
  uint64_t idc_size;

  // Output
  uint64_t signature_out;
  uint64_t signature_out_size;
  int32_t result;
  uint8_t padding[4];
};

#define PUAVO_COMMANDLINE_SIGN_IOC_SIGN      \
  _IOWR(PUAVO_COMMANDLINE_SIGN_IOC_MAGIC, 1, \
        struct puavo_command_line_sign_ioctl)

struct puavo_command_line_load_keys_ioctl {
  uint64_t server_public_key_data;
  uint64_t server_public_key_size;
  uint64_t secure_boot_private_key_data;
  uint64_t secure_boot_private_key_size;
  int32_t result;
  uint8_t padding[4];
};

#define PUAVO_COMMANDLINE_SIGN_IOC_LOAD_KEYS \
  _IOWR(PUAVO_COMMANDLINE_SIGN_IOC_MAGIC, 2, \
        struct puavo_command_line_load_keys_ioctl)

#endif
