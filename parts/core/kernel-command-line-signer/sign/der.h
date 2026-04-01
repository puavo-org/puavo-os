// Minimal DER (Distinguished Encoding Rules) parser
// for extracting values from ASN.1 structures.
//
// DER is the binary encoding used for cryptographic
// objects like certificates, PKCS7 structures, and
// Authenticode signatures. Each element is encoded as
// tag-length-value (TLV).
//
// Reference: ITU-T X.690 (DER encoding rules)

#ifndef DER_H
#define DER_H

#ifdef __KERNEL__
#include <linux/types.h>
#else
#include <stdint.h>
#include <stddef.h>
#endif

// ASN.1 tag values used in Authenticode structures.
// The tag byte encodes the class (bits 7-6), whether
// the encoding is constructed (bit 5), and the tag
// number (bits 4-0).

// SEQUENCE: constructed, universal, tag 16
#define DER_TAG_SEQUENCE 0x30

// SET: constructed, universal, tag 17
#define DER_TAG_SET 0x31

// OCTET STRING: primitive, universal, tag 4
#define DER_TAG_OCTET_STRING 0x04

// OID: primitive, universal, tag 6
#define DER_TAG_OID 0x06

// DER length encoding constants.
// If the high bit of the first length byte is set, the
// low 7 bits indicate how many subsequent bytes encode
// the actual length (long form).
#define DER_LENGTH_LONG_FORM_BIT 0x80
#define DER_LENGTH_LONG_FORM_COUNT_MASK 0x7F

// Maximum number of bytes we support for long-form
// length encoding (4 bytes = up to 4 GB)
#define DER_MAX_LENGTH_BYTES 4

// A parsed DER element. Points into the original buffer
// and does not own any memory.
struct der_element {
  // Tag byte identifying the element type
  uint8_t tag;

  // Offset of the element value (content) within the
  // original buffer
  size_t value_offset;

  // Length of the element value in bytes
  size_t value_length;

  // Total size of the element including tag and length
  // bytes (value_offset - element_offset + value_length)
  size_t total_size;

  // Offset of the element itself (the tag byte)
  size_t element_offset;
};

// Parses a DER element at the given offset in the
// buffer. Reads the tag and length, validates bounds,
// and populates the element structure. Returns 0 on
// success, -1 on error.
int der_parse_element(const uint8_t* data, size_t data_size, size_t offset,
                      struct der_element* element);

// Parses the Nth child element (zero-indexed) inside a
// constructed DER element. The parent must be a
// SEQUENCE or SET. Returns 0 on success, -1 if the
// child index is out of range or parsing fails.
int der_parse_child(const uint8_t* data, size_t data_size,
                    const struct der_element* parent, size_t child_index,
                    struct der_element* child);

#endif
