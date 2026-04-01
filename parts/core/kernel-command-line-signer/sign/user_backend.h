// OpenSSL crypto backend for the verify-and-sign
// pipeline. Used in --user mode where the Secure Boot
// private key is available on the filesystem.

#ifndef USER_BACKEND_H
#define USER_BACKEND_H

#include "core.h"

// OpenSSL-based crypto backend that implements SHA-256,
// RSA verify, and RSA sign using the EVP API.
extern const struct sign_crypto_backend user_backend;

// Reads a PEM public key and returns it as DER-encoded
// SubjectPublicKeyInfo. Used by the --user mode where
// OpenSSL verifies the signature. The caller must free
// the result.
uint8_t* pem_public_key_to_der(const char* path,
                               size_t* der_size_out);

// Reads a PEM private key and returns it as DER-encoded
// private key. Used by the --user mode where OpenSSL
// signs directly. The caller must free the result.
uint8_t* pem_private_key_to_der(const char* path,
                                size_t* der_size_out);

#endif
