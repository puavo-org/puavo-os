#ifndef COMMON_H
#define COMMON_H

/* Standard library includes. */
#include <syslog.h>

#define log(level, format, args...)             \
  syslog(level | LOG_AUTHPRIV, format, args);

#endif /* COMMON_H */
