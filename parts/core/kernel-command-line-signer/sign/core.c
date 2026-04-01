// Platform-independent verify-and-sign pipeline.
//
// This file compiles under both userspace and kernel.
// It uses no OS-specific APIs directly, only the crypto
// backend interface from core.h.

#ifdef __KERNEL__
#include <linux/string.h>
#include <linux/kernel.h>
#include <linux/slab.h>
#else
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#endif

#include "core.h"
#include "pe.h"
#include "authenticode.h"
#include "log.h"

// Parsed PE header locations needed for section lookup
// and Authenticode hashing. These are file offsets into
// the raw PE buffer, computed once by pe_parse_layout.
struct pe_layout {
  uint32_t checksum_offset;
  uint32_t certificate_table_offset;
  uint16_t number_of_sections;
  uint32_t section_table_offset;
};

// Parses PE headers and extracts layout information
// needed for section lookup and Authenticode hashing.
// Validates the DOS header, PE signature, COFF header,
// and optional header magic.
static int pe_parse_layout(const uint8_t* pe_data, size_t pe_size,
                           struct pe_layout* layout) {
  // The DOS header must be at least 64 bytes to contain
  // the lfanew field at offset 0x3C
  if (pe_size < PE_DOS_HEADER_SIZE) {
    return SIGN_ERROR_PE_PARSE;
  }

  // Read the PE signature offset from the DOS header
  uint32_t pe_offset = *(const uint32_t*)(pe_data + PE_DOS_LFANEW_OFFSET);

  // Verify there is room for the COFF header
  if (pe_offset + sizeof(struct pe_coff_header) > pe_size) {
    return SIGN_ERROR_PE_PARSE;
  }

  const struct pe_coff_header* coff =
      (const struct pe_coff_header*)(pe_data + pe_offset);

  // Verify the PE signature ("PE\0\0")
  if (coff->signature != PE_SIGNATURE) {
    return SIGN_ERROR_PE_PARSE;
  }

  // The optional header follows the COFF header
  uint32_t optional_header_offset = pe_offset + sizeof(struct pe_coff_header);

  // Read the optional header magic to determine PE32
  // vs PE32+ (32-bit vs 64-bit)
  if (optional_header_offset + 2 > pe_size) {
    return SIGN_ERROR_PE_PARSE;
  }

  uint16_t magic = *(const uint16_t*)(pe_data + optional_header_offset);

  // Compute the offset of the checksum field and the
  // data directories based on the optional header format
  uint32_t checksum_offset;
  uint32_t data_directories_offset;

  if (magic == PE32_PLUS_MAGIC) {
    // PE32+ (64-bit): optional header is 112 bytes,
    // data directories follow immediately after
    const struct pe32_plus_optional_header* optional =
        (const struct pe32_plus_optional_header*)(pe_data +
                                                  optional_header_offset);

    checksum_offset = optional_header_offset +
                      (uint32_t)((const uint8_t*)&optional->checksum -
                                 (const uint8_t*)optional);

    data_directories_offset =
        optional_header_offset + sizeof(struct pe32_plus_optional_header);
  } else if (magic == PE32_MAGIC) {
    // PE32 (32-bit): optional header is 96 bytes
    const struct pe32_optional_header* optional =
        (const struct pe32_optional_header*)(pe_data + optional_header_offset);

    checksum_offset = optional_header_offset +
                      (uint32_t)((const uint8_t*)&optional->checksum -
                                 (const uint8_t*)optional);

    data_directories_offset =
        optional_header_offset + sizeof(struct pe32_optional_header);
  } else {
    return SIGN_ERROR_PE_PARSE;
  }

  // The certificate table is data directory entry 4.
  // Each entry is a pe_data_directory (8 bytes: RVA +
  // size).
  uint32_t certificate_table_offset =
      data_directories_offset +
      PE_DIRECTORY_ENTRY_CERTIFICATE * sizeof(struct pe_data_directory);

  if (certificate_table_offset + sizeof(struct pe_data_directory) > pe_size) {
    return SIGN_ERROR_PE_PARSE;
  }

  layout->checksum_offset = checksum_offset;
  layout->certificate_table_offset = certificate_table_offset;
  layout->number_of_sections = coff->number_of_sections;
  layout->section_table_offset =
      optional_header_offset + coff->size_of_optional_header;

  return SIGN_OK;
}

// Finds the .cmdline section in a PE binary. Returns a
// pointer into pe_data and the content size. The
// returned pointer is only valid while pe_data is valid.
int pe_find_cmdline(const uint8_t* pe_data, size_t pe_size,
                    const uint8_t** content_out, size_t* content_size_out) {
  struct pe_layout layout;
  int result = pe_parse_layout(pe_data, pe_size, &layout);
  if (result != SIGN_OK) {
    return result;
  }

  // Section headers follow the optional header. Each
  // header is 40 bytes. The section name is 8 bytes,
  // null-padded but not necessarily null-terminated.
  uint32_t offset = layout.section_table_offset;

  for (uint16_t index = 0; index < layout.number_of_sections; index++) {
    if (offset + sizeof(struct pe_section_header) > pe_size) {
      return SIGN_ERROR_PE_PARSE;
    }

    const struct pe_section_header* section =
        (const struct pe_section_header*)(pe_data + offset);

    if (memcmp(section->name, ".cmdline", PE_SECTION_NAME_SIZE) == 0) {
      if (section->pointer_to_raw_data + section->size_of_raw_data > pe_size) {
        return SIGN_ERROR_PE_PARSE;
      }

      *content_out = pe_data + section->pointer_to_raw_data;

      // Use virtual_size if smaller than raw size,
      // as raw size may include alignment padding
      if (section->virtual_size > 0 &&
          section->virtual_size < section->size_of_raw_data) {
        *content_size_out = section->virtual_size;
      } else {
        *content_size_out = section->size_of_raw_data;
      }

      return SIGN_OK;
    }

    offset += sizeof(struct pe_section_header);
  }

  return SIGN_ERROR_CMDLINE;
}

// Computes the Authenticode SHA-256 digest of a PE
// binary. Hashes three regions of the PE, skipping the
// checksum field (4 bytes) and the certificate table
// data directory entry (8 bytes). This matches the
// behavior of sbsign's image_hash_sha256 and the
// Microsoft Authenticode specification (section 4).
int pe_authenticode_digest(const uint8_t* pe_data, size_t pe_size,
                           const struct sign_crypto_backend* crypto,
                           uint8_t digest_out[SHA256_DIGEST_SIZE]) {
  struct pe_layout layout;
  int result = pe_parse_layout(pe_data, pe_size, &layout);
  if (result != SIGN_OK) {
    return result;
  }

  // If the PE already has a signature, hash only up to
  // the start of the signature data
  const struct pe_data_directory* certificate_table =
      (const struct pe_data_directory*)(pe_data +
                                        layout.certificate_table_offset);

  size_t hash_end;
  if (certificate_table->virtual_address > 0 && certificate_table->size > 0) {
    hash_end = certificate_table->virtual_address;
  } else {
    hash_end = pe_size;
  }

  // The Authenticode hash covers three regions,
  // skipping the checksum field and the certificate
  // table data directory entry:
  //
  //   Region 1: file start to checksum field
  //   Region 2: after checksum to certificate table entry
  //   Region 3: after certificate table entry to hash_end
  size_t region1_end = layout.checksum_offset;
  size_t region2_start = layout.checksum_offset + sizeof(uint32_t);
  size_t region2_end = layout.certificate_table_offset;
  size_t region3_start =
      layout.certificate_table_offset + sizeof(struct pe_data_directory);

  size_t region1_size = region1_end;
  size_t region2_size = region2_end - region2_start;
  size_t region3_size = 0;
  if (region3_start < hash_end) {
    region3_size = hash_end - region3_start;
  }

  size_t total = region1_size + region2_size + region3_size;

#ifdef __KERNEL__
  uint8_t* buffer = kmalloc(total, GFP_KERNEL);
#else
  uint8_t* buffer = malloc(total);
#endif
  if (!buffer) {
    return SIGN_ERROR_PE_PARSE;
  }

  // Region 1: everything before the checksum field
  size_t position = 0;
  memcpy(buffer + position, pe_data, region1_size);
  position += region1_size;

  // Region 2: between checksum and certificate table
  memcpy(buffer + position, pe_data + region2_start, region2_size);
  position += region2_size;

  // Region 3: after certificate table to hash end
  if (region3_size > 0) {
    memcpy(buffer + position, pe_data + region3_start, region3_size);
    position += region3_size;
  }

  result = crypto->sha256(buffer, position, digest_out);

#ifdef __KERNEL__
  kfree(buffer);
#else
  free(buffer);
#endif

  return result;
}

// Verifies that the .cmdline section in the PE contains
// exactly the authorized parameters string. Trailing
// null bytes and whitespace in the section are ignored.
static int verify_cmdline_content(const uint8_t* pe_data, size_t pe_size,
                                  const char* parameters) {
  const uint8_t* content;
  size_t content_size;

  int result = pe_find_cmdline(pe_data, pe_size, &content, &content_size);
  if (result != SIGN_OK) {
    return result;
  }

  // Strip trailing padding from the section
  while (content_size > 0 && (content[content_size - 1] == '\0' ||
                              content[content_size - 1] == ' ' ||
                              content[content_size - 1] == '\n')) {
    content_size--;
  }

  size_t parameters_length = strlen(parameters);
  if (content_size != parameters_length ||
      memcmp(content, parameters, parameters_length) != 0) {
    LOG_ERROR("rejected: command-line mismatch");
    return SIGN_ERROR_CMDLINE;
  }

  return SIGN_OK;
}

// Executes the full verification and signing pipeline.
// Runs inside the kernel module in production. Performs
// seven steps, each of which must succeed before the
// next.
int sign_verify_and_sign(struct sign_request* request,
                         const struct sign_crypto_backend* crypto) {
  int result;

  // Verify server authorization.
  // The server signed SHA-256(parameters) with its
  // private key. We verify that signature using the
  // server's public key.
  LOG_INFO("verify server authorization");

  result = crypto->rsa_verify(
      request->server_public_key_der, request->server_public_key_der_size,
      (const uint8_t*)request->parameters, strlen(request->parameters),
      request->server_authorization, request->server_authorization_size);
  if (result != 0) {
    LOG_ERROR("rejected: server authorization failed");
    return SIGN_ERROR_AUTH_FAILED;
  }

  // Verify .cmdline matches authorized parameters.
  // Parse the PE binary and check that the
  // .cmdline section contains exactly the parameters
  // the server authorized.
  LOG_INFO("verify command-line content");

  result = verify_cmdline_content(request->pe_data, request->pe_size,
                                  request->parameters);
  if (result != SIGN_OK) {
    return result;
  }

  // Independently recompute PE Authenticode
  // digest. We hash the PE regions ourselves (skipping
  // the checksum and certificate table fields) to get
  // the canonical Authenticode hash. We do not trust
  // the hash that userspace computed.
  LOG_INFO("recompute PE digest");

  uint8_t pe_digest[SHA256_DIGEST_SIZE];
  result = pe_authenticode_digest(request->pe_data, request->pe_size, crypto,
                                  pe_digest);
  if (result != SIGN_OK) {
    return result;
  }

  // Parse the IDC ASN.1 and verify its PE
  // digest matches our independently computed one.
  LOG_INFO("verify PE digest in IDC");

  uint8_t idc_pe_digest[SHA256_DIGEST_SIZE];
  if (authenticode_extract_pe_digest_from_idc(
          request->idc_data, request->idc_size, idc_pe_digest) != 0) {
    LOG_ERROR("rejected: failed to parse IDC");
    return SIGN_ERROR_IDC_MISMATCH;
  }
  if (memcmp(pe_digest, idc_pe_digest, SHA256_DIGEST_SIZE) != 0) {
    LOG_ERROR("rejected: PE digest in IDC does not match");
    return SIGN_ERROR_IDC_MISMATCH;
  }

  // Verify the attributes are bound to the IDC.
  // We verify that the messageDigest field inside
  // the attributes equals SHA-256 of the IDC content.
  LOG_INFO("verify attributes bound to IDC");

  uint8_t idc_content_hash[SHA256_DIGEST_SIZE];
  if (authenticode_compute_idc_content_hash(request->idc_data,
                                            request->idc_size, crypto,
                                            idc_content_hash) != 0) {
    LOG_ERROR("rejected: failed to hash IDC content");
    return SIGN_ERROR_IDC_MISMATCH;
  }

  uint8_t attributes_message_digest[SHA256_DIGEST_SIZE];
  if (authenticode_extract_message_digest_from_attributes(
          request->attributes_der, request->attributes_der_size,
          attributes_message_digest) != 0) {
    LOG_ERROR("rejected: failed to parse attributes");
    return SIGN_ERROR_IDC_MISMATCH;
  }
  if (memcmp(idc_content_hash, attributes_message_digest, SHA256_DIGEST_SIZE) !=
      0) {
    LOG_ERROR("rejected: attributes message digest does not match IDC content");
    return SIGN_ERROR_IDC_MISMATCH;
  }

  // Hash the authenticated attributes and
  // RSA-sign them with the device's Secure Boot private
  // key. The resulting signature is returned to
  // userspace, which injects it into the PKCS7
  // structure to produce the final signed PE addon.
  LOG_INFO("rsa-signing the attributes");

  uint8_t attributes_digest[SHA256_DIGEST_SIZE];
  result = crypto->sha256(request->attributes_der, request->attributes_der_size,
                          attributes_digest);
  if (result != 0) {
    return SIGN_ERROR_SIGN_FAILED;
  }

  result = crypto->rsa_sign_digest(request->secure_boot_private_key_der,
                                   request->secure_boot_private_key_der_size,
                                   attributes_digest, request->signature_out,
                                   &request->signature_out_size);
  if (result != 0) {
    LOG_ERROR("rsa sign failed");
    return SIGN_ERROR_SIGN_FAILED;
  }

  LOG_INFO("signature: %zu bytes", request->signature_out_size);

  return SIGN_OK;
}
