// Authenticode structure parsing for IDC and PKCS7
// authenticated attributes.
//
// Extracts digests from their defined ASN.1 positions
// to prevent attacks where an adversary places correct
// values at decoy positions while putting malicious
// values in the real fields.

#ifndef AUTHENTICODE_H
#define AUTHENTICODE_H

#ifdef __KERNEL__
#include <linux/types.h>
#else
#include <stdint.h>
#include <stddef.h>
#endif

#include "core.h"

// Extracts the PE Authenticode digest from an IDC
// (Indirect Data Content) DER blob by parsing the
// ASN.1 structure at its defined position.
//
// IDC layout:
//   SEQUENCE {
//     SEQUENCE { ... }      (SPC PE Image Data)
//     SEQUENCE {            (DigestInfo)
//       SEQUENCE { ... }    (AlgorithmIdentifier)
//       OCTET STRING <32>   (PE digest)
//     }
//   }
//
// Returns 0 on success, -1 on parse error.
int authenticode_extract_pe_digest_from_idc(
    const uint8_t* idc_data, size_t idc_size,
    uint8_t digest_out[SHA256_DIGEST_SIZE]);

// Extracts the messageDigest value from PKCS7
// authenticated attributes DER by parsing the ASN.1
// structure at its defined position.
//
// Attributes layout:
//   SET {
//     SEQUENCE {            (contentType attribute)
//       OID contentType
//       SET { OID }
//     }
//     SEQUENCE {            (messageDigest attribute)
//       OID messageDigest
//       SET {
//         OCTET STRING <32> (IDC content hash)
//       }
//     }
//   }
//
// Returns 0 on success, -1 on parse error.
int authenticode_extract_message_digest_from_attributes(
    const uint8_t* attributes_data, size_t attributes_size,
    uint8_t digest_out[SHA256_DIGEST_SIZE]);

// Computes the content hash of an IDC DER blob. The
// content is the bytes after the outer SEQUENCE tag and
// length header, matching sbsign's IDC_set behavior
// where BIO_write skips the outer wrapper.
//
// Returns 0 on success, negative on error.
int authenticode_compute_idc_content_hash(
    const uint8_t* idc_data, size_t idc_size,
    const struct sign_crypto_backend* crypto,
    uint8_t hash_out[SHA256_DIGEST_SIZE]);

#endif
