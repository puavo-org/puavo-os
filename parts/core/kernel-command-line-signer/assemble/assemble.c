// Assembles a signed PE addon from pre-computed parts.
//
// Takes the authenticated attributes DER, Indirect Data
// Content (IDC) DER, and a raw RSA signature produced by
// the kernel signing module. Rebuilds the PKCS7
// Authenticode structure and embeds it into the unsigned
// PE binary to produce a Secure Boot signed addon.
//
// Usage:
//   puavo-command-line-sign-assemble <unsigned-efi>
//       <certificate> <attributes> <idc> <signature>
//       <output>

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
#include <openssl/objects.h>

#include <ccan/talloc/talloc.h>

#include "image.h"
#include "fileio.h"

// The SPC Indirect Data Content OID is defined by the
// Microsoft Authenticode specification (section 6). It
// is used as the content type inside PKCS7 SignedData
// to indicate that the signed content is a PE image
// hash. The OID is 1.3.6.1.4.1.311.2.1.4 and is also
// used in sbsign's idc.c (IDC_set function, line 170).
// The specification is available at:
//   https://download.microsoft.com/download/9/c/5/
//   9c5b2167-8017-4bae-9fde-d599bac8184a/
//   Authenticode_PE.docx
#define SPC_INDIRECT_DATA_OID "1.3.6.1.4.1.311.2.1.4"

int main(int argument_count, char** arguments) {
  if (argument_count != 7) {
    fprintf(stderr,
            "Usage: %s <unsigned-efi>"
            " <certificate>"
            " <attributes> <idc>"
            " <signature> <output>\n",
            arguments[0]);
    return 1;
  }

  // Terminology:
  //   PE    Portable Executable, the binary format
  //         used by UEFI firmware
  //   PKCS7 Cryptographic Message Syntax, the envelope
  //         format that carries the signature
  //   IDC   Indirect Data Content, an Authenticode
  //         structure containing the PE image hash
  //   SPC   Software Publishing Certificate, the
  //         Microsoft term for Authenticode content
  //   OID   Object Identifier, a globally unique dotted
  //         number identifying a data type or algorithm
  //   DER   Distinguished Encoding Rules, the binary
  //         serialization format for ASN.1 structures
  //
  // This program takes five pre-computed inputs
  // (unsigned PE, certificate, attributes, IDC, and
  // RSA signature) and assembles them into the
  // following structure which gets appended to the PE:
  //
  // Signed PE file
  // +------------------------------------------+
  // | PE headers + sections (.cmdline, etc.)   |
  // +------------------------------------------+
  // | WIN_CERTIFICATE header                   |
  // | +--------------------------------------+ |
  // | | PKCS7 SignedData                     | |
  // | | +----------------------------------+ | |
  // | | | Certificate (public key)         | | |
  // | | +----------------------------------+ | |
  // | | | SignerInfo                       | | |
  // | | | +------------------------------+ | | |
  // | | | | Issuer + Serial              | | | |
  // | | | | Digest algorithm (SHA-256)   | | | |
  // | | | | Signing algorithm (RSA)      | | | |
  // | | | | Authenticated attributes     | | | |
  // | | | |   Content type (SPC IDC OID) | | | |
  // | | | |   Message digest (of IDC)    | | | |
  // | | | | Encrypted digest (RSA sig)   | | | |
  // | | | +------------------------------+ | | |
  // | | +----------------------------------+ | |
  // | | | Content: IDC                     | | |
  // | | |   PE Authenticode hash (SHA-256) | | |
  // | | +----------------------------------+ | |
  // | +--------------------------------------+ |
  // +------------------------------------------+
  //
  // The SignerInfo does not point to the IDC directly.
  // Instead, the message digest attribute inside the
  // authenticated attributes contains SHA-256 of the
  // IDC content. The verifier recomputes this hash
  // from the IDC and compares it to the attribute
  // value. The RSA signature covers the authenticated
  // attributes (not the IDC directly), creating a
  // chain: RSA sig -> attributes -> IDC hash -> PE
  // hash.

  const char* pe_path = arguments[1];
  const char* certificate_path = arguments[2];
  const char* attributes_path = arguments[3];
  const char* idc_path = arguments[4];
  const char* signature_path = arguments[5];
  const char* output_path = arguments[6];

  // These are set to NULL so the cleanup label can
  // safely free them regardless of where we jump from.
  struct image* image = NULL;
  X509* certificate = NULL;
  PKCS7* pkcs7 = NULL;
  uint8_t* attributes_data = NULL;
  uint8_t* idc_data = NULL;
  uint8_t* signature_data = NULL;
  int return_code = 1;

  // Load the unsigned PE binary. sbsign's image_load
  // parses the PE/COFF headers and prepares the
  // internal structures needed for signature embedding.
  image = image_load(pe_path);
  if (!image) {
    fprintf(stderr, "error: cannot load PE image from '%s'\n", pe_path);
    goto cleanup;
  }

  // Load the Secure Boot certificate. This is the
  // public certificate corresponding to the private key
  // that the kernel module used for signing. It gets
  // embedded in the PKCS7 so that Secure Boot firmware
  // can verify the signature.
  certificate = fileio_read_cert(certificate_path);
  if (!certificate) {
    fprintf(stderr, "error: cannot load certificate from '%s'\n",
            certificate_path);
    goto cleanup;
  }

  // Load the authenticated attributes in DER encoding.
  // DER (Distinguished Encoding Rules) is a binary
  // serialization format for ASN.1 data structures.
  // It is the standard wire format for cryptographic
  // objects like certificates, signatures, and PKCS7
  // structures. The attributes blob was produced by the
  // request program and contains the content type and
  // message digest that were signed by the kernel
  // module.
  size_t attributes_size;
  if (fileio_read_file(NULL, attributes_path, &attributes_data,
                       &attributes_size)) {
    fprintf(stderr, "error: cannot read attributes from '%s'\n",
            attributes_path);
    goto cleanup;
  }

  // Load the Indirect Data Content (IDC) DER blob. The
  // IDC contains the PE Authenticode hash wrapped in an
  // ASN.1 structure defined by the Microsoft
  // Authenticode specification. It becomes the content
  // of the PKCS7 SignedData.
  size_t idc_size;
  if (fileio_read_file(NULL, idc_path, &idc_data, &idc_size)) {
    fprintf(stderr, "error: cannot read IDC from '%s'\n", idc_path);
    goto cleanup;
  }

  // Load the raw RSA signature produced by the kernel
  // signing module. This is the RSA-PKCS1v15 signature
  // over SHA-256 of the authenticated attributes.
  size_t signature_size;
  if (fileio_read_file(NULL, signature_path, &signature_data,
                       &signature_size)) {
    fprintf(stderr, "error: cannot read signature from '%s'\n", signature_path);
    goto cleanup;
  }

  // Build a PKCS7 SignedData structure without a
  // private key. The private key is not needed because
  // we inject a pre-computed signature directly into
  // the structure.
  pkcs7 = PKCS7_new();
  PKCS7_set_type(pkcs7, NID_pkcs7_signed);
  PKCS7_content_new(pkcs7, NID_pkcs7_data);

  // Embed the certificate in the PKCS7 certificate
  // bag. Secure Boot firmware reads it from here to
  // verify the signature.
  PKCS7_add_certificate(pkcs7, certificate);

  // Build the SignerInfo structure manually. Normally
  // OpenSSL's PKCS7_sign_add_signer does this, but
  // that function requires a private key. Instead we
  // populate the fields directly: version, issuer and
  // serial (to identify the signing certificate),
  // digest algorithm (SHA-256), and the signing
  // algorithm (read from the certificate itself).
  PKCS7_SIGNER_INFO* signer_info = PKCS7_SIGNER_INFO_new();

  // PKCS7 SignerInfo version 1
  ASN1_INTEGER_set(signer_info->version, 1);

  // Issuer and serial number identify which certificate
  // produced the signature. The verifier uses these to
  // find the matching certificate in the PKCS7
  // certificate bag.
  X509_NAME_set(&signer_info->issuer_and_serial->issuer,
                X509_get_issuer_name(certificate));

  // PKCS7_SIGNER_INFO_new allocates a default serial
  // number. We free it and replace with a copy of the
  // certificate's serial. We use ASN1_INTEGER_dup
  // (duplicate) because X509_get0_serialNumber returns
  // a pointer to the certificate's internal data which
  // we must not take ownership of.
  ASN1_INTEGER_free(signer_info->issuer_and_serial->serial);
  signer_info->issuer_and_serial->serial =
      ASN1_INTEGER_dup(X509_get0_serialNumber(certificate));

  // The digest algorithm used for hashing (SHA-256)
  X509_ALGOR_set0(signer_info->digest_alg, OBJ_nid2obj(NID_sha256), V_ASN1_NULL,
                  NULL);

  // The signing algorithm is extracted from the
  // certificate. The numeric identifier (NID) tells
  // OpenSSL which algorithm the certificate's public
  // key uses (typically RSA).
  int public_key_algorithm_nid = 0;
  X509_get_signature_info(certificate, NULL, &public_key_algorithm_nid, NULL,
                          NULL);
  X509_ALGOR_set0(signer_info->digest_enc_alg,
                  OBJ_nid2obj(public_key_algorithm_nid), V_ASN1_NULL, NULL);

  // Add the signer info to the PKCS7 structure
  PKCS7_add_signer(pkcs7, signer_info);

  // Restore the authenticated attributes from the DER
  // blob produced by the request program. These
  // attributes (content type and message digest) were
  // what the kernel module signed. We parse the DER
  // back into OpenSSL's internal representation.
  //
  // ASN1_item_d2i means "ASN.1 item DER to internal",
  // the OpenSSL convention where d2i converts from DER
  // bytes to in-memory C structures (and i2d does the
  // reverse, internal to DER).
  const uint8_t* attributes_pointer = attributes_data;
  STACK_OF(X509_ATTRIBUTE)* signed_attributes = NULL;
  ASN1_item_d2i((ASN1_VALUE**)&signed_attributes, &attributes_pointer,
                attributes_size, ASN1_ITEM_rptr(PKCS7_ATTR_SIGN));

  if (!signed_attributes) {
    fprintf(stderr,
            "error: failed to parse authenticated"
            " attributes DER\n");
    ERR_print_errors_fp(stderr);
    goto cleanup;
  }

  // Attach the authenticated attributes to the signer
  // info
  signer_info->auth_attr = signed_attributes;

  // Inject the RSA signature from the kernel module
  // into the SignerInfo's encrypted digest field. This
  // is the key step that makes offline signing work:
  // instead of OpenSSL computing the signature
  // internally, we provide it externally. The signature
  // must be copied into OpenSSL-managed memory because
  // ASN1_STRING_set0 takes ownership and PKCS7_free
  // will later call OPENSSL_free on it.
  uint8_t* signature_copy = OPENSSL_malloc(signature_size);
  memcpy(signature_copy, signature_data, signature_size);
  ASN1_STRING_set0(signer_info->enc_digest, signature_copy, signature_size);

  // Register the SPC Indirect Data Content OID with
  // OpenSSL's internal object database. SPC stands for
  // Software Publishing Certificate, a Microsoft term
  // from the Authenticode specification. The OID
  // 1.3.6.1.4.1.311.2.1.4 uniquely identifies this
  // content type in the global OID tree:
  //   1.3.6.1.4.1  = iso.org.dod.internet.private.enterprise
  //   .311         = Microsoft
  //   .2.1.4       = Authenticode SPC Indirect Data
  // The same OID is used in sbsign's idc.c (IDC_set).
  // OBJ_create registers it so OpenSSL can reference it
  // by NID (numeric identifier) in PKCS7 structures.
  int idc_nid = OBJ_create(SPC_INDIRECT_DATA_OID, "spcIndirectDataContext",
                           "Indirect Data Context");
  if (idc_nid == NID_undef) {
    idc_nid = OBJ_txt2nid(SPC_INDIRECT_DATA_OID);
  }

  // Set the IDC as the PKCS7 content. The IDC is
  // wrapped in an ASN.1 SEQUENCE type and placed inside
  // the PKCS7 SignedData as the "other" content type
  // (since Authenticode uses a non-standard content
  // type, not plain data).
  ASN1_TYPE* idc_wrapper = ASN1_TYPE_new();
  ASN1_STRING* idc_sequence = ASN1_STRING_new();
  ASN1_STRING_set(idc_sequence, idc_data, idc_size);
  ASN1_TYPE_set(idc_wrapper, V_ASN1_SEQUENCE, idc_sequence);
  PKCS7_set0_type_other(pkcs7->d.sign->contents, idc_nid, idc_wrapper);

  // Serialize the complete PKCS7 structure to DER
  // format. i2d_PKCS7 (internal to DER) is called
  // twice: first with NULL to determine the output
  // size, then with a buffer to write the bytes.
  int pkcs7_der_size = i2d_PKCS7(pkcs7, NULL);
  uint8_t* pkcs7_der_buffer = talloc_array(image, uint8_t, pkcs7_der_size);
  uint8_t* write_position = pkcs7_der_buffer;
  i2d_PKCS7(pkcs7, &write_position);

  // Append the PKCS7 signature to the PE image using
  // sbsign's image_add_signature, which creates the
  // WIN_CERTIFICATE wrapper and updates the PE data
  // directory. Then write the signed PE to disk.
  image_add_signature(image, pkcs7_der_buffer, pkcs7_der_size);

  int write_result = image_write(image, output_path);
  if (write_result) {
    fprintf(stderr, "error: failed to write signed PE to '%s'\n", output_path);
    goto cleanup;
  }

  return_code = 0;

cleanup:
  if (pkcs7) {
    PKCS7_free(pkcs7);
  }
  if (image) {
    talloc_free(image);
  }

  return return_code;
}
