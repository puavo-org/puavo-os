// Kernel module ioctl client. Provides the --kernel
// signing mode and the --load-keys key provisioning
// mode, both communicating with the kernel module via
// /dev/puavo-command-line-signer.

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>

#include <ccan/talloc/talloc.h>

#include "fileio.h"
#include "core.h"
#include "ioctl.h"
#include "log.h"
#include "kernel_client.h"

#define DEVICE_PATH "/dev/puavo-command-line-signer"
#define SIGNATURE_BUFFER_SIZE 512

// Returns a human-readable string for a pipeline error
// code.
static const char* sign_error_string(int code) {
  switch (code) {
    case SIGN_OK:
      return "success";
    case SIGN_ERROR_AUTH_FAILED:
      return "server authorization verification failed";
    case SIGN_ERROR_CMDLINE:
      return "command-line does not match authorized value";
    case SIGN_ERROR_PE_PARSE:
      return "PE parsing failed";
    case SIGN_ERROR_IDC_MISMATCH:
      return "IDC digest does not match PE";
    case SIGN_ERROR_SIGN_FAILED:
      return "RSA signing failed";
    case SIGN_ERROR_VERIFY_FAILED:
      return "signature verification failed";
    case SIGN_ERROR_INVALID_INPUT:
      return "invalid input";
    default:
      return "unknown error";
  }
}

int run_kernel_mode(int argument_count, char** arguments) {
  if (argument_count != 8) {
    fprintf(stderr,
            "Usage: %s --kernel <unsigned-efi>"
            " <parameters> <authorization>"
            " <attributes> <idc>"
            " <signature-output>\n"
            "\n"
            "Keys are loaded by the kernel module"
            " via the LOAD_KEYS ioctl.\n",
            arguments[0]);
    return 1;
  }

  const char* pe_path = arguments[2];
  const char* parameters = arguments[3];
  const char* authorization_path = arguments[4];
  const char* attributes_path = arguments[5];
  const char* idc_path = arguments[6];
  const char* signature_output_path = arguments[7];

  // Load all input files
  uint8_t* pe_data = NULL;
  uint8_t* authorization_data = NULL;
  uint8_t* attributes_data = NULL;
  uint8_t* idc_data = NULL;
  size_t pe_size, authorization_size;
  size_t attributes_size, idc_size;

  if (fileio_read_file(NULL, pe_path, &pe_data, &pe_size) ||
      fileio_read_file(NULL, authorization_path, &authorization_data,
                       &authorization_size) ||
      fileio_read_file(NULL, attributes_path, &attributes_data,
                       &attributes_size) ||
      fileio_read_file(NULL, idc_path, &idc_data, &idc_size)) {
    fprintf(stderr, "error: failed to load inputs\n");
    return 1;
  }

  // Prepare the output signature buffer
  uint8_t signature[SIGNATURE_BUFFER_SIZE];
  memset(signature, 0, sizeof(signature));

  // Populate the ioctl request with pointers to
  // userspace buffers
  struct puavo_command_line_sign_ioctl request = {
      .pe_data = (uint64_t)(uintptr_t)pe_data,
      .pe_size = pe_size,
      .parameters = (uint64_t)(uintptr_t)parameters,
      .parameters_size = strlen(parameters),
      .authorization = (uint64_t)(uintptr_t)authorization_data,
      .authorization_size = authorization_size,
      .attributes_der = (uint64_t)(uintptr_t)attributes_data,
      .attributes_der_size = attributes_size,
      .idc_data = (uint64_t)(uintptr_t)idc_data,
      .idc_size = idc_size,
      .signature_out = (uint64_t)(uintptr_t)signature,
      .signature_out_size = SIGNATURE_BUFFER_SIZE,
      .result = 0,
      .padding = {0},
  };

  // Open the kernel module device
  LOG_INFO("opening %s", DEVICE_PATH);
  int device_fd = open(DEVICE_PATH, O_RDWR);
  if (device_fd < 0) {
    LOG_ERROR("cannot open %s: %s", DEVICE_PATH, strerror(errno));
    LOG_ERROR("is the kernel module loaded?");
    return 1;
  }

  // Submit the signing request via ioctl
  LOG_INFO("submitting signing request via ioctl");
  int ioctl_result =
      ioctl(device_fd, PUAVO_COMMANDLINE_SIGN_IOC_SIGN, &request);
  close(device_fd);

  int exit_code = 1;

  if (ioctl_result < 0) {
    LOG_ERROR("ioctl failed: %s", strerror(errno));
  } else if (request.result != SIGN_OK) {
    LOG_ERROR("%s (code %d)", sign_error_string(request.result), request.result);
  } else {
    LOG_INFO("writing signature to %s", signature_output_path);
    fileio_write_file(signature_output_path, signature,
                      request.signature_out_size);
    exit_code = 0;
  }

  return exit_code;
}

// Provisions keys into the kernel module via ioctl.
// Reads raw DER key files and sends them to the module.
// The server public key must be PKCS#1 RSAPublicKey DER
// and the private key must be PKCS#1 RSAPrivateKey DER
// (the formats the Linux kernel crypto API expects).
// Use openssl to convert PEM keys before calling this:
//   openssl rsa -RSAPublicKey_out -outform DER
//   openssl rsa -traditional -outform DER
int run_load_keys_mode(int argument_count,
                       char** arguments) {
  if (argument_count != 4) {
    fprintf(stderr,
            "Usage: %s --load-keys"
            " <server-public-key.der>"
            " <secure-boot-private-key.der>\n"
            "\n"
            "Keys must be in PKCS#1 DER format.\n",
            arguments[0]);
    return 1;
  }

  const char* server_key_path = arguments[2];
  const char* secure_boot_key_path = arguments[3];

  // Read the raw DER key files
  LOG_INFO("loading server public key from %s",
           server_key_path);
  uint8_t* server_key = NULL;
  size_t server_key_size;
  if (fileio_read_file(NULL, server_key_path,
                       &server_key,
                       &server_key_size)) {
    LOG_ERROR("failed to read %s", server_key_path);
    return 1;
  }

  LOG_INFO("loading secure boot private key from %s",
           secure_boot_key_path);
  uint8_t* secure_boot_key = NULL;
  size_t secure_boot_key_size;
  if (fileio_read_file(NULL, secure_boot_key_path,
                       &secure_boot_key,
                       &secure_boot_key_size)) {
    LOG_ERROR("failed to read %s", secure_boot_key_path);
    return 1;
  }

  LOG_INFO("server key: %zu bytes, "
           "secure boot key: %zu bytes",
           server_key_size, secure_boot_key_size);

  // Open the kernel module device
  LOG_INFO("opening %s", DEVICE_PATH);
  int device_fd = open(DEVICE_PATH, O_RDWR);
  if (device_fd < 0) {
    LOG_ERROR("cannot open %s: %s",
            DEVICE_PATH, strerror(errno));
    LOG_ERROR("is the kernel module loaded?");
    return 1;
  }

  // Send the keys to the kernel module
  struct puavo_command_line_load_keys_ioctl request = {
      .server_public_key_data =
          (uint64_t)(uintptr_t)server_key,
      .server_public_key_size = server_key_size,
      .secure_boot_private_key_data =
          (uint64_t)(uintptr_t)secure_boot_key,
      .secure_boot_private_key_size =
          secure_boot_key_size,
      .result = 0,
      .padding = {0},
  };

  LOG_INFO("sending keys via ioctl");
  int ioctl_result = ioctl(
      device_fd, PUAVO_COMMANDLINE_SIGN_IOC_LOAD_KEYS,
      &request);
  close(device_fd);

  if (ioctl_result < 0) {
    LOG_ERROR("ioctl failed: %s", strerror(errno));
    return 1;
  }

  if (request.result != 0) {
    LOG_ERROR("load keys failed (code %d)",
            request.result);
    return 1;
  }

  LOG_INFO("keys loaded successfully");
  return 0;
}
