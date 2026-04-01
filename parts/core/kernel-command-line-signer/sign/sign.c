// Userspace signing program with two backends.
//
// --user:   Signs using OpenSSL directly. Used on
//           non-encrypted devices where the Secure Boot
//           private key is on the filesystem.
//
// --kernel: Signs via ioctl to the kernel module. Used
//           on encrypted devices where the kernel module
//           holds the key in kernel memory.

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <ccan/talloc/talloc.h>

#include "fileio.h"
#include "core.h"
#include "log.h"
#include "user_backend.h"
#include "kernel_client.h"

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

// Signs using OpenSSL directly in userspace. The Secure
// Boot private key is read from the filesystem.
static int run_user_mode(int argument_count, char** arguments) {
  if (argument_count != 10) {
    fprintf(stderr,
            "Usage: %s --user <unsigned-efi>"
            " <parameters> <authorization>"
            " <server-public-key>"
            " <secure-boot-private-key>"
            " <attributes> <idc>"
            " <signature-output>\n",
            arguments[0]);
    return 1;
  }

  const char* pe_path = arguments[2];
  const char* parameters = arguments[3];
  const char* authorization_path = arguments[4];
  const char* server_key_path = arguments[5];
  const char* secure_boot_key_path = arguments[6];
  const char* attributes_path = arguments[7];
  const char* idc_path = arguments[8];
  const char* signature_output_path = arguments[9];

  // Load all input files
  size_t pe_size, authorization_size;
  size_t attributes_size, idc_size;
  uint8_t* pe_data = NULL;
  uint8_t* authorization_data = NULL;
  uint8_t* attributes_data = NULL;
  uint8_t* idc_data = NULL;

  if (fileio_read_file(NULL, pe_path, &pe_data, &pe_size) ||
      fileio_read_file(NULL, authorization_path, &authorization_data,
                       &authorization_size) ||
      fileio_read_file(NULL, attributes_path, &attributes_data,
                       &attributes_size) ||
      fileio_read_file(NULL, idc_path, &idc_data, &idc_size)) {
    fprintf(stderr, "error: failed to load inputs\n");
    return 1;
  }

  // Convert PEM keys to DER for the core pipeline
  size_t server_key_size, secure_boot_key_size;
  uint8_t* server_key =
      pem_public_key_to_der(server_key_path, &server_key_size);
  uint8_t* secure_boot_key =
      pem_private_key_to_der(secure_boot_key_path, &secure_boot_key_size);

  if (!server_key || !secure_boot_key) {
    fprintf(stderr, "error: failed to load keys\n");
    return 1;
  }

  uint8_t signature[SIGNATURE_BUFFER_SIZE];

  // Populate the pipeline request
  struct sign_request request = {
      .pe_data = pe_data,
      .pe_size = pe_size,
      .parameters = parameters,
      .server_authorization = authorization_data,
      .server_authorization_size = authorization_size,
      .attributes_der = attributes_data,
      .attributes_der_size = attributes_size,
      .idc_data = idc_data,
      .idc_size = idc_size,
      .server_public_key_der = server_key,
      .server_public_key_der_size = server_key_size,
      .secure_boot_private_key_der = secure_boot_key,
      .secure_boot_private_key_der_size = secure_boot_key_size,
      .signature_out = signature,
      .signature_out_size = sizeof(signature),
  };

  // Run the verify-and-sign pipeline with the OpenSSL
  // backend
  LOG_INFO("running pipeline (--user mode)");
  int result = sign_verify_and_sign(&request, &user_backend);

  if (result == SIGN_OK) {
    LOG_INFO("writing signature to %s", signature_output_path);
    fileio_write_file(signature_output_path, signature,
                      request.signature_out_size);
  } else {
    LOG_ERROR("error: %s (code %d)", sign_error_string(result), result);
  }

  free(server_key);
  free(secure_boot_key);

  return (result == SIGN_OK) ? 0 : 1;
}

// Entry point. Dispatches based on mode flag.
int main(int argument_count, char** arguments) {
  if (argument_count < 2) {
    fprintf(stderr,
            "Usage: %s <mode> [arguments...]\n"
            "\n"
            "Signs UKI addon PE binaries with server\n"
            "authorization.\n"
            "\n"
            "Modes:\n"
            "  --user       Sign using OpenSSL directly\n"
            "  --kernel     Sign via kernel module ioctl\n"
            "  --load-keys  Provision keys into the"
            " kernel module\n",
            arguments[0]);
    return 1;
  }

  if (strcmp(arguments[1], "--kernel") == 0) {
    return run_kernel_mode(argument_count, arguments);
  } else if (strcmp(arguments[1], "--user") == 0) {
    return run_user_mode(argument_count, arguments);
  } else if (strcmp(arguments[1], "--load-keys") == 0) {
    return run_load_keys_mode(argument_count, arguments);
  } else {
    fprintf(stderr,
            "error: unknown mode '%s'\n"
            "use --user, --kernel, or --load-keys\n",
            arguments[1]);
    return 1;
  }
}
