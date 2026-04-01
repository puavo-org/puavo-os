// Server-side authorization for kernel parameter signing.
//
// Signs SHA-256 of the kernel parameters string with the
// server's private key. The resulting signature is sent
// to the device as proof that the server authorized these
// exact parameters.
//
// Usage:
//   puavo-command-line-sign-prepare <parameters>
//       <server-private-key> <authorization-output>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/err.h>

int main(int argument_count, char** arguments) {
  if (argument_count != 4) {
    fprintf(stderr,
            "Usage: %s <parameters>"
            " <server-private-key>"
            " <authorization-output>\n",
            arguments[0]);
    return 1;
  }

  const char* parameters = arguments[1];
  const char* key_path = arguments[2];
  const char* output_path = arguments[3];

  // Load the server's RSA private key from a PEM file.
  FILE* key_file = fopen(key_path, "r");
  if (!key_file) {
    fprintf(stderr, "error: cannot open key '%s': %s\n", key_path,
            strerror(errno));
    return 1;
  }

  EVP_PKEY* key = PEM_read_PrivateKey(key_file, NULL, NULL, NULL);
  fclose(key_file);
  if (!key) {
    fprintf(stderr, "error: cannot read private key from '%s'\n", key_path);
    return 1;
  }

  // Sign SHA-256 of the parameters string. The kernel
  // module on the device will verify this signature
  // against the server's public key before allowing
  // the signing operation.
  EVP_MD_CTX* context = EVP_MD_CTX_new();
  if (!context ||
      EVP_DigestSignInit(context, NULL, EVP_sha256(), NULL, key) != 1) {
    fprintf(stderr, "error: DigestSignInit failed\n");
    EVP_PKEY_free(key);
    return 1;
  }

  EVP_DigestSignUpdate(context, (const unsigned char*)parameters,
                       strlen(parameters));

  // Determine signature size, allocate, and sign
  size_t signature_size;
  EVP_DigestSignFinal(context, NULL, &signature_size);
  unsigned char* signature = malloc(signature_size);
  if (EVP_DigestSignFinal(context, signature, &signature_size) != 1) {
    fprintf(stderr, "error: DigestSignFinal failed\n");
    free(signature);
    EVP_MD_CTX_free(context);
    EVP_PKEY_free(key);
    return 1;
  }

  EVP_MD_CTX_free(context);
  EVP_PKEY_free(key);

  // Write the authorization signature to a file
  FILE* output = fopen(output_path, "wb");
  if (!output) {
    fprintf(stderr, "error: cannot create '%s': %s\n", output_path,
            strerror(errno));
    free(signature);
    return 1;
  }
  fwrite(signature, 1, signature_size, output);
  fclose(output);
  free(signature);

  return 0;
}
