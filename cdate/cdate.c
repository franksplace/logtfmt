#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include <string.h>
#include <math.h>

int local_system_timestamp(char[]);

int main(void) {
    char buf[31];
    local_system_timestamp(buf);
    printf("%s\n", buf);
}

int local_system_timestamp(char buf[]) {
    const int tmpsize = 21;
    char tzchar[5];
    struct timespec now;
    struct tm tm;
    int retval = clock_gettime(CLOCK_REALTIME, &now);

    tzset();
    localtime_r(&now.tv_sec, &tm);

    strftime(buf, tmpsize, "%Y-%m-%dT%H:%M:%S.", &tm);
    strftime(tzchar, 5, "%z", &tm);
    
    int micro = lrint(now.tv_nsec/1000.000);
    sprintf(buf + strlen(buf), "%03d%s", micro, tzchar);
    return retval;
}
