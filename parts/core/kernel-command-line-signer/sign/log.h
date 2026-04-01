// Logging macros that work in both userspace and kernel.
#ifndef LOG_H
#define LOG_H

#ifdef __KERNEL__

#include <linux/kernel.h>

#define LOG_PREFIX "puavo-command-line-signer: "
#define LOG_INFO(format, ...) pr_info(LOG_PREFIX format, ##__VA_ARGS__)
#define LOG_ERROR(format, ...) pr_err(LOG_PREFIX format, ##__VA_ARGS__)

#else // __KERNEL__

#include <stdio.h>

#define LOG_INFO(format, ...) printf("  " format "\n", ##__VA_ARGS__)
#define LOG_ERROR(format, ...) fprintf(stderr, "  " format "\n", ##__VA_ARGS__)

#endif // __KERNEL__

#endif // LOG_H
