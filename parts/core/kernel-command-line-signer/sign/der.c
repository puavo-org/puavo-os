// Minimal DER parser for navigating ASN.1 structures.
// Compiles in both userspace and kernel.

#ifdef __KERNEL__
#include <linux/string.h>
#else
#include <string.h>
#endif

#include "der.h"

int der_parse_element(const uint8_t* data, size_t data_size, size_t offset,
                      struct der_element* element) {
  size_t start_offset = offset;

  // Read the tag byte
  if (offset >= data_size) {
    return -1;
  }
  element->tag = data[offset];
  element->element_offset = offset;
  offset++;

  // Read the length
  if (offset >= data_size) {
    return -1;
  }
  uint8_t first_length_byte = data[offset];
  offset++;

  size_t length;

  if ((first_length_byte & DER_LENGTH_LONG_FORM_BIT) == 0) {
    // Short form: the length is the byte value itself
    length = first_length_byte;
  } else {
    // Long form: the low 7 bits tell how many
    // subsequent bytes encode the length
    uint8_t count = first_length_byte & DER_LENGTH_LONG_FORM_COUNT_MASK;

    if (count == 0 || count > DER_MAX_LENGTH_BYTES) {
      return -1;
    }
    if (offset + count > data_size) {
      return -1;
    }

    // Read the length bytes in big-endian order
    length = 0;
    for (uint8_t index = 0; index < count; index++) {
      length = (length << 8) | data[offset];
      offset++;
    }
  }

  // Validate that the value fits within the buffer
  if (offset + length > data_size) {
    return -1;
  }

  element->value_offset = offset;
  element->value_length = length;
  element->total_size = (offset - start_offset) + length;

  return 0;
}

int der_parse_child(const uint8_t* data, size_t data_size,
                    const struct der_element* parent, size_t child_index,
                    struct der_element* child) {
  // Start at the beginning of the parent's value
  // NOTE: Offsets are validated inside the parse function
  size_t offset = parent->value_offset;
  size_t parent_end = parent->value_offset + parent->value_length;

  for (size_t index = 0; index <= child_index; index++) {
    if (offset >= parent_end) {
      return -1;
    }

    if (der_parse_element(data, data_size, offset, child) != 0) {
      return -1;
    }

    // If this is not the child we want, skip past it
    if (index < child_index) {
      offset = child->value_offset + child->value_length;
    }
  }

  return 0;
}
