/*
Copyright 2024 Frank Stutz.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


*/

#include <stdio.h>
#include <time.h>
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
  off += snprintf(buf+off, bufsize-off, ".%06ld", now.tv_nsec/1000);
  off += strftime(buf+off, bufsize-off, "%z", &tm);

  printf("%s\n", buf);
  return exitval;
}
