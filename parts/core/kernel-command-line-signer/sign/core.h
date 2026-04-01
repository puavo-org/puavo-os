// Platform-independent signing logic interface.
//
// Defines the crypto abstraction layer and the core
// verify-and-sign pipeline. This header is shared
// between the userspace binary (sign.c) and
// the kernel module (kernel_module.c). The core
// logic in core.c calls only the functions defined
// here and never touches OS-specific APIs directly.
//
// To port the signing logic to a new platform, implement
// the three functions in sign_crypto_backend and call
// sign_verify_and_sign with the platform's backend.

#ifndef SIGN_CORE_H
#define SIGN_CORE_H

#ifdef __KERNEL__
#include <linux/types.h>
#else
#include <stdint.h>
#include <stddef.h>
#endif

#define SHA256_DIGEST_SIZE 32

// Error codes returned by sign_verify_and_sign
#define SIGN_OK 0
#define SIGN_ERROR_AUTH_FAILED -1
#define SIGN_ERROR_CMDLINE -2
#define SIGN_ERROR_PE_PARSE -3
#define SIGN_ERROR_IDC_MISMATCH -4
#define SIGN_ERROR_SIGN_FAILED -5
#define SIGN_ERROR_VERIFY_FAILED -6
#define SIGN_ERROR_INVALID_INPUT -7

// --------------------------------------------------------
// Crypto backend interface
//
// Each function returns 0 on success, negative on error.
// The userspace backend (sign.c) implements these
// with OpenSSL. The kernel backend
// (kernel_module.c) implements them with
// linux/crypto.h.
// --------------------------------------------------------

struct sign_crypto_backend {
  // Compute SHA-256 of data. Writes 32 bytes to output.
  int (*sha256)(const uint8_t* data, size_t length,
                uint8_t output[SHA256_DIGEST_SIZE]);

  // Verify an RSA-PKCS1v15-SHA256 signature.
  // Computes SHA-256 of data internally, then verifies
  // the signature against that hash using the public
  // key. key_data is a DER-encoded SubjectPublicKeyInfo.
  // Returns 0 if the signature is valid.
  int (*rsa_verify)(const uint8_t* key_data, size_t key_size,
                    const uint8_t* data, size_t data_size,
                    const uint8_t* signature, size_t signature_size);

  // RSA-sign a pre-computed SHA-256 digest using
  // PKCS1v15 padding. The digest is 32 bytes.
  // signature_out must be pre-allocated (at least 256
  // bytes for RSA-2048). signature_size_out receives the
  // actual signature length.
  int (*rsa_sign_digest)(const uint8_t* key_data, size_t key_size,
                         const uint8_t* digest, uint8_t* signature_out,
                         size_t* signature_size_out);
};

// --------------------------------------------------------
// PE parsing
//
// Minimal PE parser that works on a raw byte buffer.
// No file I/O, no dynamic allocation for the parser
// itself. Used by the kernel module to inspect the PE
// without needing sbsign's full image.c infrastructure.
// --------------------------------------------------------

// Find the .cmdline section in a PE binary.
// Returns a pointer into pe_data and the content size.
// The returned pointer is only valid as long as pe_data
// is valid.
int pe_find_cmdline(const uint8_t* pe_data, size_t pe_size,
                    const uint8_t** content_out, size_t* content_size_out);

// Compute the Authenticode SHA-256 digest of a PE binary.
// This hashes specific regions of the PE, skipping the
// checksum field and certificate table directory entry,
// matching the behavior of sbsign's image_hash_sha256.
int pe_authenticode_digest(const uint8_t* pe_data, size_t pe_size,
                           const struct sign_crypto_backend* crypto,
                           uint8_t digest_out[SHA256_DIGEST_SIZE]);

// --------------------------------------------------------
// Core verify-and-sign pipeline
// --------------------------------------------------------

// All the data needed for a signing request. In the
// kernel module, these fields are populated from the
// ioctl arguments and the module's built-in keys.
struct sign_request {
  // The unsigned PE binary
  const uint8_t* pe_data;
  size_t pe_size;

  // The kernel command-line parameters string that the
  // server authorized
  const char* parameters;

  // The server's RSA signature over SHA-256 of the
  // parameters string
  const uint8_t* server_authorization;
  size_t server_authorization_size;

  // The authenticated attributes DER blob from the
  // request program. This is what gets RSA-signed.
  const uint8_t* attributes_der;
  size_t attributes_der_size;

  // The IDC DER blob from the request program. Contains
  // the PE Authenticode hash.
  const uint8_t* idc_data;
  size_t idc_size;

  // Server's public key in DER format
  // (SubjectPublicKeyInfo)
  const uint8_t* server_public_key_der;
  size_t server_public_key_der_size;

  // Device's Secure Boot private key in DER format
  const uint8_t* secure_boot_private_key_der;
  size_t secure_boot_private_key_der_size;

  // Output: the raw RSA signature. Caller allocates
  // this buffer (at least 256 bytes for RSA-2048).
  // sign_verify_and_sign writes the signature here
  // and updates signature_out_size.
  uint8_t* signature_out;
  size_t signature_out_size;
};

// Execute the full verify-and-sign pipeline:
//
// 1. Verify server authorization (RSA verify)
// 2. Parse PE and verify .cmdline matches the
//    authorized parameters
// 3. Independently recompute the PE Authenticode hash
// 4. Verify the computed hash appears in the IDC blob
// 5. SHA-256 the authenticated attributes
// 6. RSA-sign that hash with the device's private key
//
// Returns SIGN_OK on success or a negative error code.
int sign_verify_and_sign(struct sign_request* request,
                         const struct sign_crypto_backend* crypto);

#endif
