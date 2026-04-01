// Builds a signing request for offline Authenticode
// signing.
//
// Computes the Authenticode hash of an unsigned PE
// binary, builds the Indirect Data Content (IDC) and
// PKCS7 authenticated attributes, and outputs both as
// DER blobs. The authenticated attributes DER is what
// the kernel signing module will RSA-sign.
//
// This program does not need any private key. It uses
// only the Secure Boot certificate to set up the PKCS7
// signer information.
//
// Usage:
//   puavo-command-line-sign-request <unsigned-efi>
//       <certificate> <attributes-output> <idc-output>

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/pkcs7.h>
#include <openssl/err.h>
#include <openssl/x509.h>
#include <openssl/sha.h>
#include <openssl/objects.h>

#include <ccan/talloc/talloc.h>

#include "idc.h"
#include "image.h"
#include "fileio.h"

// The SPC Indirect Data Content OID identifies the
// Authenticode content type inside the PKCS7 structure.
// See assemble.c for a detailed explanation of SPC, OIDs,
// and where this value comes from.
#define SPC_INDIRECT_DATA_OID "1.3.6.1.4.1.311.2.1.4"

int main(int argument_count, char** arguments) {
  if (argument_count != 5) {
    fprintf(stderr,
            "Usage: %s <unsigned-efi>"
            " <certificate>"
            " <attributes-output>"
            " <idc-output>\n",
            arguments[0]);
    return 1;
  }

  // Terminology and structure overview
  //
  // PE    Portable Executable, the UEFI binary format
  // PKCS7 Cryptographic Message Syntax, the signature
  //       envelope
  // IDC   Indirect Data Content, contains the PE hash
  // SPC   Software Publishing Certificate, Microsoft's
  //       Authenticode content type
  // OID   Object Identifier, a globally unique number
  // DER   Distinguished Encoding Rules, binary ASN.1
  //       serialization
  // BIO   OpenSSL's Basic I/O abstraction, a chainable
  //       stream that can filter data (for example,
  //       a digest BIO hashes everything written
  //       through it)
  //
  // What this program produces:
  //
  // +----------------------------------------------+
  // | Authenticated attributes (DER)               |
  // | +------------------------------------------+ |
  // | | Content type: SPC IDC OID                | |
  // | | Message digest: SHA-256 of IDC content   | |
  // | +------------------------------------------+ |
  // +----------------------------------------------+
  //   The kernel module RSA-signs SHA-256 of this blob.
  //
  // +----------------------------------------------+
  // | IDC (DER)                                    |
  // | +------------------------------------------+ |
  // | | SPC PE Image Data (obsolete fields)      | |
  // | | PE Authenticode digest (SHA-256)         | |
  // | +------------------------------------------+ |
  // +----------------------------------------------+
  //   The kernel module verifies its PE digest matches.
  //   The assemble program embeds it as PKCS7 content.

  const char* pe_path = arguments[1];
  const char* certificate_path = arguments[2];
  const char* attributes_output_path = arguments[3];
  const char* idc_output_path = arguments[4];

  struct image* image = NULL;
  X509* certificate = NULL;
  PKCS7* pkcs7 = NULL;
  uint8_t* idc_buffer = NULL;
  int return_code = 1;

  // Load and parse the unsigned PE binary. sbsign's
  // image_load reads the file, validates the PE/COFF
  // headers, and identifies the regions that
  // contribute to the Authenticode hash.
  image = image_load(pe_path);
  if (!image) {
    fprintf(stderr, "error: cannot load PE image from '%s'\n", pe_path);
    goto cleanup;
  }

  // Load the Secure Boot certificate. We only need the
  // public certificate here, not the private key. The
  // certificate provides the issuer name, serial
  // number, and signing algorithm that go into the
  // PKCS7 SignerInfo.
  certificate = fileio_read_cert(certificate_path);
  if (!certificate) {
    fprintf(stderr, "error: cannot load certificate from '%s'\n",
            certificate_path);
    goto cleanup;
  }

  // Create an empty PKCS7 SignedData container. We need
  // this structure so that OpenSSL can set up the
  // internal BIO chain for computing the message digest
  // over the IDC content.
  pkcs7 = PKCS7_new();
  PKCS7_set_type(pkcs7, NID_pkcs7_signed);
  PKCS7_content_new(pkcs7, NID_pkcs7_data);
  PKCS7_add_certificate(pkcs7, certificate);

  // Build the SignerInfo manually without a private
  // key. This follows systemd-sbsign's offline signing
  // approach (see systemd's src/shared/openssl-util.c,
  // function pkcs7_new, the "out-of-band" branch).
  //
  // Normally OpenSSL's PKCS7_sign_add_signer does this
  // automatically, but it requires a private key that
  // matches the certificate. Since the private key
  // lives in the kernel module, we populate each field
  // by hand.
  PKCS7_SIGNER_INFO* signer_info = PKCS7_SIGNER_INFO_new();

  // SignerInfo version 1 (required by PKCS7)
  ASN1_INTEGER_set(signer_info->version, 1);

  // The issuer name and serial number identify which
  // certificate produced the signature. When verifying,
  // the firmware looks up the certificate in the PKCS7
  // certificate bag by matching these fields.
  X509_NAME_set(&signer_info->issuer_and_serial->issuer,
                X509_get_issuer_name(certificate));

  // PKCS7_SIGNER_INFO_new allocates a default serial
  // number (typically zero). We free it and replace it
  // with a copy of the certificate's actual serial. We
  // use ASN1_INTEGER_dup (duplicate) because
  // X509_get0_serialNumber returns a pointer into the
  // certificate's internal data, which we must not take
  // ownership of.
  ASN1_INTEGER_free(signer_info->issuer_and_serial->serial);
  signer_info->issuer_and_serial->serial =
      ASN1_INTEGER_dup(X509_get0_serialNumber(certificate));

  // The digest algorithm tells the verifier which hash
  // function was used (SHA-256 in our case).
  X509_ALGOR_set0(signer_info->digest_alg, OBJ_nid2obj(NID_sha256), V_ASN1_NULL,
                  NULL);

  // The signature encryption algorithm is read from the
  // certificate itself. The NID (numeric identifier) is
  // OpenSSL's internal number for the algorithm. For an
  // RSA certificate this will be NID_rsaEncryption.
  int public_key_algorithm_nid = 0;
  X509_get_signature_info(certificate, NULL, &public_key_algorithm_nid, NULL,
                          NULL);
  X509_ALGOR_set0(signer_info->digest_enc_alg,
                  OBJ_nid2obj(public_key_algorithm_nid), V_ASN1_NULL, NULL);

  // Register the signer info with the PKCS7 structure.
  // After this call, pkcs7 owns the signer_info memory.
  PKCS7_add_signer(pkcs7, signer_info);

  // Build the IDC DER blob using sbsign's IDC code.
  // IDC_build_der computes the PE Authenticode hash
  // (SHA-256 over the PE regions, excluding the
  // checksum field and certificate table) and wraps it
  // in the SPC Indirect Data Content ASN.1 structure.
  int idc_length;
  if (IDC_build_der(image, &idc_buffer, &idc_length) != 0) {
    fprintf(stderr, "error: IDC_build_der failed\n");
    goto cleanup;
  }

  // Write the IDC to a file. It will be used by two
  // consumers: the kernel module reads it to verify
  // that the PE digest inside matches the PE it
  // received, and the assemble program embeds it as the
  // PKCS7 content.
  fileio_write_file(idc_output_path, idc_buffer, idc_length);

  // Register the SPC Indirect Data Content OID with
  // OpenSSL and add it as the content type
  // authenticated attribute. This attribute tells the
  // verifier that the signed content is an Authenticode
  // PE image hash (as opposed to, for example, a plain
  // data blob or an email message).
  int idc_nid = OBJ_create(SPC_INDIRECT_DATA_OID, "spcIndirectDataContext",
                           "Indirect Data Context");
  PKCS7_add_signed_attribute(signer_info, NID_pkcs9_contentType, V_ASN1_OBJECT,
                             OBJ_nid2obj(idc_nid));

  // Now we need to compute the message digest of the
  // IDC content. This digest becomes the second
  // authenticated attribute. The verifier will
  // recompute it from the IDC and compare.
  //
  // OpenSSL's BIO (Basic I/O) is a chainable stream
  // abstraction. PKCS7_dataInit creates a BIO chain
  // that includes a digest filter. Anything written
  // through this chain gets hashed automatically. We
  // write the IDC content bytes (skipping the outer
  // ASN.1 tag and length, which is the first 2 bytes)
  // to match sbsign's IDC_set behavior.
  BIO* signature_bio = PKCS7_dataInit(pkcs7, NULL);
  BIO_write(signature_bio, idc_buffer + 2, idc_length - 2);

  // Walk the BIO chain to find the digest filter and
  // extract the computed hash. BIO_find_type locates
  // the digest BIO in the chain, and BIO_get_md_ctx
  // gives us the hash context to finalize.
  BIO* digest_bio = BIO_find_type(signature_bio, BIO_TYPE_MD);
  EVP_MD_CTX* digest_context;
  BIO_get_md_ctx(digest_bio, &digest_context);

  // Finalize the hash computation. This produces the
  // SHA-256 digest of the IDC content that we wrote
  // through the BIO chain above.
  unsigned char idc_digest[EVP_MAX_MD_SIZE];
  unsigned int idc_digest_length;
  EVP_DigestFinal_ex(digest_context, idc_digest, &idc_digest_length);
  BIO_free_all(signature_bio);

  // Add the computed digest as the message digest
  // authenticated attribute. Together with the content
  // type attribute added earlier, these two attributes
  // form the "authenticated attributes" that the kernel
  // module will sign.
  PKCS7_add1_attrib_digest(signer_info, idc_digest, idc_digest_length);

  // Serialize the authenticated attributes to DER
  // format. This DER blob is the final output that the
  // kernel module will RSA-sign after hashing it with
  // SHA-256. The PKCS7_ATTR_SIGN item type tells
  // OpenSSL to use the SET OF encoding (tag 0x31)
  // required by the PKCS7 signature computation.
  uint8_t* attributes_buffer = NULL;
  int attributes_length =
      ASN1_item_i2d((ASN1_VALUE*)signer_info->auth_attr, &attributes_buffer,
                    ASN1_ITEM_rptr(PKCS7_ATTR_SIGN));

  // Write the authenticated attributes DER to a file
  // for the kernel module to sign.
  fileio_write_file(attributes_output_path, attributes_buffer,
                    attributes_length);

  // Free the buffer allocated by OpenSSL's i2d
  // (internal to DER) serialization.
  OPENSSL_free(attributes_buffer);
  return_code = 0;

cleanup:
  free(idc_buffer);
  if (pkcs7) {
    PKCS7_free(pkcs7);
  }
  if (image) {
    talloc_free(image);
  }

  return return_code;
}
