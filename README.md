# logtfmt
Little set of executables to print out [ISO8601 w/Combined Date & Time](https://en.wikipedia.org/wiki/ISO_8601#Combined_date_and_time_representations "WikiPedia - ISO 8601 with Combined Date & Time") with microseconds based on clients local timezone.
(i.e. 2024-05-29T14:19:12.131126-0700)

This is similar to Bash and Zsz's EPOCHREALTIME

## Executables
Executable|Language
:---:|:---:
cdate | C
ccdate | C++
sdate | Swift

## Building
```
git clone https://github.com/franksplace/logtfmt/
cd logtfmt
./build.sh all
```

## Running
```
cd logtfmt
./bin/cdate
./bin/sdate
./bin/ccdate
```

### Example
```
cd logtfmt
bin/cdate
2024-05-29T14:19:12.131126-0700
```

## Benchmark
You'll need to install https://github.com/sharkdp/hyperfine first.
```
cd logtfmt
./benchmark.sh
```
