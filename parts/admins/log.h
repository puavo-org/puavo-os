#ifndef COMMON_H
#define COMMON_H

#include <syslog.h>

#define log(level, format, args...)             \
  syslog(level | LOG_AUTHPRIV, format, args);

#endif // COMMON_H
