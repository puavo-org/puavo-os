// Minimal PE (Portable Executable) format structures
// for parsing UKI addon binaries.
//
// Only the structures needed for Authenticode hashing
// and .cmdline section lookup are defined here. This is
// not a complete PE implementation.
//
// Reference: https://wiki.osdev.org/PE
// Reference: Microsoft PE Format Specification

#ifndef PE_H
#define PE_H

#ifdef __KERNEL__
#include <linux/types.h>
#else
#include <stdint.h>
#endif

// DOS header. Only the fields we need are listed.
// The full header is 64 bytes. We only read lfanew
// which points to the PE signature.
#define PE_DOS_HEADER_SIZE 64
#define PE_DOS_LFANEW_OFFSET 0x3C

// PE signature: the four bytes "PE\0\0"
#define PE_SIGNATURE 0x00004550

// COFF header immediately follows the PE signature.
// 20 bytes.
struct __attribute__((packed)) pe_coff_header {
  uint32_t signature;
  uint16_t machine;
  uint16_t number_of_sections;
  uint32_t time_date_stamp;
  uint32_t pointer_to_symbol_table;
  uint32_t number_of_symbols;
  uint16_t size_of_optional_header;
  uint16_t characteristics;
};

// Optional header magic values
#define PE32_MAGIC 0x010B
#define PE32_PLUS_MAGIC 0x020B

// PE32 optional header (32-bit). 96 bytes before data
// directories.
struct __attribute__((packed)) pe32_optional_header {
  uint16_t magic;
  uint8_t major_linker_version;
  uint8_t minor_linker_version;
  uint32_t size_of_code;
  uint32_t size_of_initialized_data;
  uint32_t size_of_uninitialized_data;
  uint32_t address_of_entry_point;
  uint32_t base_of_code;
  uint32_t base_of_data;
  uint32_t image_base;
  uint32_t section_alignment;
  uint32_t file_alignment;
  uint16_t major_operating_system_version;
  uint16_t minor_operating_system_version;
  uint16_t major_image_version;
  uint16_t minor_image_version;
  uint16_t major_subsystem_version;
  uint16_t minor_subsystem_version;
  uint32_t win32_version_value;
  uint32_t size_of_image;
  uint32_t size_of_headers;
  uint32_t checksum;
  uint16_t subsystem;
  uint16_t dll_characteristics;
  uint32_t size_of_stack_reserve;
  uint32_t size_of_stack_commit;
  uint32_t size_of_heap_reserve;
  uint32_t size_of_heap_commit;
  uint32_t loader_flags;
  uint32_t number_of_rva_and_sizes;
};

// PE32+ optional header (64-bit). 112 bytes before data
// directories. Differs from PE32: no base_of_data,
// and image_base/stack/heap sizes are 64-bit.
struct __attribute__((packed)) pe32_plus_optional_header {
  uint16_t magic;
  uint8_t major_linker_version;
  uint8_t minor_linker_version;
  uint32_t size_of_code;
  uint32_t size_of_initialized_data;
  uint32_t size_of_uninitialized_data;
  uint32_t address_of_entry_point;
  uint32_t base_of_code;
  uint64_t image_base;
  uint32_t section_alignment;
  uint32_t file_alignment;
  uint16_t major_operating_system_version;
  uint16_t minor_operating_system_version;
  uint16_t major_image_version;
  uint16_t minor_image_version;
  uint16_t major_subsystem_version;
  uint16_t minor_subsystem_version;
  uint32_t win32_version_value;
  uint32_t size_of_image;
  uint32_t size_of_headers;
  uint32_t checksum;
  uint16_t subsystem;
  uint16_t dll_characteristics;
  uint64_t size_of_stack_reserve;
  uint64_t size_of_stack_commit;
  uint64_t size_of_heap_reserve;
  uint64_t size_of_heap_commit;
  uint32_t loader_flags;
  uint32_t number_of_rva_and_sizes;
};

// Data directory entry. Each entry is 8 bytes: a
// virtual address (or file offset for certificates)
// and a size.
struct __attribute__((packed)) pe_data_directory {
  uint32_t virtual_address;
  uint32_t size;
};

// Data directory indices
#define PE_DIRECTORY_ENTRY_CERTIFICATE 4

// Section header. 40 bytes. The name is 8 bytes,
// null-padded but not necessarily null-terminated.
#define PE_SECTION_NAME_SIZE 8

struct __attribute__((packed)) pe_section_header {
  char name[PE_SECTION_NAME_SIZE];
  uint32_t virtual_size;
  uint32_t virtual_address;
  uint32_t size_of_raw_data;
  uint32_t pointer_to_raw_data;
  uint32_t pointer_to_relocations;
  uint32_t pointer_to_line_numbers;
  uint16_t number_of_relocations;
  uint16_t number_of_line_numbers;
  uint32_t characteristics;
};

#endif
