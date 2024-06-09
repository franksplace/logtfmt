#include <stdio.h>
#include <sys/time.h>

int main () {
  struct timespec now;
  struct tm tm;
  int exitval = clock_gettime(CLOCK_REALTIME, &now);

  tzset();
  localtime_r(&now.tv_sec, &tm);

  char buf[sizeof "9999-01-02T01:02:03.999999+0000"];
  size_t bufsize = sizeof buf;

  int off = 0;

  off = strftime(buf, bufsize, "%FT%T", &tm);
  off += snprintf(buf+off, bufsize-off, ".%03ld", now.tv_nsec/1000);
  off += strftime(buf+off, bufsize-off, "%z", &tm);

  printf("%s\n", buf);
  return exitval;
}
