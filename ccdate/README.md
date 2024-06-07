# ccdate

Little C++ executable to print out [ISO8601 w/Combined Date & Time](https://en.wikipedia.org/wiki/ISO_8601#Combined_date_and_time_representations "WikiPedia - ISO 8601 with Combined Date & Time") with microseconds based on clients local timezone.
(i.e. 2024-05-29T14:19:12.131126-0700)

This is similar to Bash and Zsz's EPOCHREALTIME

## Builing
```
git clone https://github.com/franksplace/logtfmt/
cd logtfmt
./build.sh ccdate
```

## Running
```
cd logtfmt
./bin/ccdate
```

### Example
```
cd logtfmt
bin/ccdate
2024-05-29T14:19:12.131126-0700
```
