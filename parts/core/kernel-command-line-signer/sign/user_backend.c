// OpenSSL crypto backend for the verify-and-sign
// pipeline. Implements SHA-256, RSA verify, and RSA
// sign using the OpenSSL EVP API.
//
// Also provides PEM-to-DER key conversion helpers
// needed by the --user mode CLI.

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/rsa.h>

#include "fileio.h"
#include "core.h"
#include "user_backend.h"

// Computes SHA-256 of the given data using OpenSSL.
static int user_sha256(const uint8_t* data, size_t length,
                       uint8_t output[SHA256_DIGEST_SIZE]) {
  EVP_MD_CTX* context = EVP_MD_CTX_new();
  if (!context) {
    return -1;
  }

  unsigned int output_length;
  int result = EVP_DigestInit_ex(context, EVP_sha256(), NULL) &&
               EVP_DigestUpdate(context, data, length) &&
               EVP_DigestFinal_ex(context, output, &output_length);

  EVP_MD_CTX_free(context);
  return result == 1 ? 0 : -1;
}

// Verifies an RSA-PKCS1v15-SHA256 signature using
// OpenSSL. The key is a DER-encoded SubjectPublicKeyInfo.
static int user_rsa_verify(const uint8_t* key_data, size_t key_size,
                           const uint8_t* data, size_t data_size,
                           const uint8_t* signature, size_t signature_size) {
  const uint8_t* key_pointer = key_data;
  EVP_PKEY* public_key = d2i_PUBKEY(NULL, &key_pointer, key_size);
  if (!public_key) {
    return -1;
  }

  EVP_MD_CTX* context = EVP_MD_CTX_new();
  int result = -1;

  if (!context) {
    EVP_PKEY_free(public_key);
    return -1;
  }

  if (EVP_DigestVerifyInit(context, NULL, EVP_sha256(), NULL, public_key) !=
      1) {
    goto cleanup;
  }

  if (EVP_DigestVerifyUpdate(context, data, data_size) != 1) {
    goto cleanup;
  }

  if (EVP_DigestVerifyFinal(context, signature, signature_size) == 1) {
    result = 0;
  }

cleanup:
  EVP_MD_CTX_free(context);
  EVP_PKEY_free(public_key);
  return result;
}

// Signs a pre-computed SHA-256 digest with RSA using
// PKCS1v15 padding via OpenSSL. The key is a
// DER-encoded private key.
static int user_rsa_sign_digest(const uint8_t* key_data, size_t key_size,
                                const uint8_t* digest, uint8_t* signature_out,
                                size_t* signature_size_out) {
  const uint8_t* key_pointer = key_data;
  EVP_PKEY* private_key = d2i_AutoPrivateKey(NULL, &key_pointer, key_size);
  if (!private_key) {
    ERR_print_errors_fp(stderr);
    return -1;
  }

  EVP_PKEY_CTX* context = EVP_PKEY_CTX_new(private_key, NULL);
  int result = -1;

  if (!context) {
    EVP_PKEY_free(private_key);
    return -1;
  }

  if (EVP_PKEY_sign_init(context) != 1) {
    goto cleanup;
  }

  if (EVP_PKEY_CTX_set_rsa_padding(context, RSA_PKCS1_PADDING) != 1) {
    goto cleanup;
  }

  if (EVP_PKEY_CTX_set_signature_md(context, EVP_sha256()) != 1) {
    goto cleanup;
  }

  // Determine the required output buffer size
  size_t maximum_size;
  EVP_PKEY_sign(context, NULL, &maximum_size, digest, SHA256_DIGEST_SIZE);

  // Produce the signature
  if (EVP_PKEY_sign(context, signature_out, &maximum_size, digest,
                    SHA256_DIGEST_SIZE) == 1) {
    *signature_size_out = maximum_size;
    result = 0;
  }

cleanup:
  EVP_PKEY_CTX_free(context);
  EVP_PKEY_free(private_key);
  return result;
}

const struct sign_crypto_backend user_backend = {
    .sha256 = user_sha256,
    .rsa_verify = user_rsa_verify,
    .rsa_sign_digest = user_rsa_sign_digest,
};

uint8_t* pem_public_key_to_der(const char* path, size_t* der_size_out) {
  FILE* file = fopen(path, "r");
  if (!file) {
    return NULL;
  }

  EVP_PKEY* key = PEM_read_PUBKEY(file, NULL, NULL, NULL);
  fclose(file);
  if (!key) {
    return NULL;
  }

  int length = i2d_PUBKEY(key, NULL);
  uint8_t* buffer = malloc(length);
  uint8_t* temporary = buffer;
  i2d_PUBKEY(key, &temporary);

  EVP_PKEY_free(key);
  *der_size_out = length;
  return buffer;
}

uint8_t* pem_private_key_to_der(const char* path, size_t* der_size_out) {
  EVP_PKEY* key = fileio_read_pkey(path);
  if (!key) {
    return NULL;
  }

  int length = i2d_PrivateKey(key, NULL);
  uint8_t* buffer = malloc(length);
  uint8_t* temporary = buffer;
  i2d_PrivateKey(key, &temporary);

  EVP_PKEY_free(key);
  *der_size_out = length;
  return buffer;
}
