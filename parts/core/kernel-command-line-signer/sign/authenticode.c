// Authenticode structure parsing. Extracts digests from
// IDC and PKCS7 authenticated attributes by navigating
// the ASN.1 tree to the defined positions.
//
// Compiles in both userspace and kernel.

#ifdef __KERNEL__
#include <linux/string.h>
#else
#include <string.h>
#endif

#include "authenticode.h"
#include "der.h"
#include "log.h"

// Child indices within the IDC SEQUENCE:
//   child 0 = SPC PE Image Data
//   child 1 = DigestInfo
#define IDC_CHILD_DIGEST_INFO 1

// Child indices within DigestInfo SEQUENCE:
//   child 0 = AlgorithmIdentifier
//   child 1 = OCTET STRING (the PE digest)
#define DIGEST_INFO_CHILD_DIGEST 1

// Child indices within the authenticated attributes SET:
//   child 0 = contentType attribute
//   child 1 = messageDigest attribute
#define ATTRIBUTES_CHILD_MESSAGE_DIGEST 1

// Child indices within a PKCS7 attribute SEQUENCE:
//   child 0 = OID (attribute type)
//   child 1 = SET (attribute value)
#define ATTRIBUTE_CHILD_VALUE_SET 1

// The messageDigest SET contains a single OCTET STRING
#define MESSAGE_DIGEST_SET_CHILD_OCTET_STRING 0

int authenticode_extract_pe_digest_from_idc(
    const uint8_t* idc_data, size_t idc_size,
    uint8_t digest_out[SHA256_DIGEST_SIZE]) {
  struct der_element outer;
  struct der_element digest_info;
  struct der_element digest_octet_string;

  // Parse the outer IDC SEQUENCE
  if (der_parse_element(idc_data, idc_size, 0, &outer) != 0) {
    LOG_ERROR("idc: failed to parse outer sequence");
    return -1;
  }
  if (outer.tag != DER_TAG_SEQUENCE) {
    LOG_ERROR("idc: expected sequence, got tag 0x%02x", outer.tag);
    return -1;
  }

  // Navigate to the DigestInfo (second child)
  if (der_parse_child(idc_data, idc_size, &outer, IDC_CHILD_DIGEST_INFO,
                      &digest_info) != 0) {
    LOG_ERROR("idc: failed to parse digest info");
    return -1;
  }
  if (digest_info.tag != DER_TAG_SEQUENCE) {
    LOG_ERROR("idc: digest info is not a sequence");
    return -1;
  }

  // Navigate to the digest OCTET STRING inside
  // DigestInfo (second child, after AlgorithmIdentifier)
  if (der_parse_child(idc_data, idc_size, &digest_info,
                      DIGEST_INFO_CHILD_DIGEST, &digest_octet_string) != 0) {
    LOG_ERROR("idc: failed to parse digest octet string");
    return -1;
  }
  if (digest_octet_string.tag != DER_TAG_OCTET_STRING) {
    LOG_ERROR("idc: expected octet string, got tag 0x%02x",
            digest_octet_string.tag);
    return -1;
  }
  if (digest_octet_string.value_length != SHA256_DIGEST_SIZE) {
    LOG_ERROR("idc: digest length %zu, expected %d",
            digest_octet_string.value_length, SHA256_DIGEST_SIZE);
    return -1;
  }

  // Copy the digest value from the IDC data
  // NOTE: Offsets and sizes are validated inside the parse function
  memcpy(digest_out, idc_data + digest_octet_string.value_offset,
         SHA256_DIGEST_SIZE);
  return 0;
}

int authenticode_extract_message_digest_from_attributes(
    const uint8_t* attributes_data, size_t attributes_size,
    uint8_t digest_out[SHA256_DIGEST_SIZE]) {
  struct der_element outer;
  struct der_element message_digest_attribute;
  struct der_element value_set;
  struct der_element digest_octet_string;

  // Parse the outer SET of authenticated attributes
  if (der_parse_element(attributes_data, attributes_size, 0, &outer) != 0) {
    LOG_ERROR("attributes: failed to parse outer set");
    return -1;
  }
  if (outer.tag != DER_TAG_SET) {
    LOG_ERROR("attributes: expected set, got tag 0x%02x", outer.tag);
    return -1;
  }

  // Navigate to the messageDigest attribute (second
  // child, after contentType)
  if (der_parse_child(attributes_data, attributes_size, &outer,
                      ATTRIBUTES_CHILD_MESSAGE_DIGEST,
                      &message_digest_attribute) != 0) {
    LOG_ERROR(
        "attributes: failed to parse "
        "message digest attribute");
    return -1;
  }
  if (message_digest_attribute.tag != DER_TAG_SEQUENCE) {
    LOG_ERROR(
        "attributes: message digest attribute "
        "is not a sequence");
    return -1;
  }

  // Navigate to the value SET (second child, after OID)
  if (der_parse_child(attributes_data, attributes_size,
                      &message_digest_attribute, ATTRIBUTE_CHILD_VALUE_SET,
                      &value_set) != 0) {
    LOG_ERROR("attributes: failed to parse value set");
    return -1;
  }
  if (value_set.tag != DER_TAG_SET) {
    LOG_ERROR("attributes: expected set, got tag 0x%02x", value_set.tag);
    return -1;
  }

  // Extract the OCTET STRING from inside the SET
  if (der_parse_child(attributes_data, attributes_size, &value_set,
                      MESSAGE_DIGEST_SET_CHILD_OCTET_STRING,
                      &digest_octet_string) != 0) {
    LOG_ERROR(
        "attributes: failed to parse "
        "digest octet string");
    return -1;
  }
  if (digest_octet_string.tag != DER_TAG_OCTET_STRING) {
    LOG_ERROR(
        "attributes: expected octet string, "
        "got tag 0x%02x",
        digest_octet_string.tag);
    return -1;
  }
  if (digest_octet_string.value_length != SHA256_DIGEST_SIZE) {
    LOG_ERROR("attributes: digest length %zu, expected %d",
            digest_octet_string.value_length, SHA256_DIGEST_SIZE);
    return -1;
  }

  // Copy the digest value from the attributes data
  // NOTE: Offsets and sizes are validated inside the parse function
  memcpy(digest_out, attributes_data + digest_octet_string.value_offset,
         SHA256_DIGEST_SIZE);
  return 0;
}

int authenticode_compute_idc_content_hash(
    const uint8_t* idc_data, size_t idc_size,
    const struct sign_crypto_backend* crypto,
    uint8_t hash_out[SHA256_DIGEST_SIZE]) {
  // Parse the outer element to determine the header
  // size (tag + length bytes). The IDC content that
  // gets hashed is everything after this header,
  // matching sbsign's IDC_set behavior where BIO_write
  // skips the outer ASN.1 wrapper.
  struct der_element outer;
  if (der_parse_element(idc_data, idc_size, 0, &outer) != 0) {
    LOG_ERROR(
        "idc: failed to parse outer element "
        "for content hash");
    return -1;
  }

  return crypto->sha256(idc_data + outer.value_offset, outer.value_length,
                        hash_out);
}
