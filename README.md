# Log Time & Format (logtfmt)

Little set of executables to print out [ISO8601 w/Combined Date & Time](https://en.wikipedia.org/wiki/ISO_8601#Combined_date_and_time_representations "WikiPedia - ISO 8601 with Combined Date & Time") with microseconds based on clients local timezone.
(i.e. 2024-05-29T14:19:12.131126-0700)

The main purpose is to compare execution times betweeh different languages and understand uniqueness between how each handle "localtime".

This is similar to EPOCH Realtime in Bash and Zsh.

Bash >= 5.0

```sh
t=$EPOCHREALTIME
printf "%(%FT%T)T.${t#*.}%(%z)T\n" "${t%.*}"
```

ZSH >= 5.6

```sh
print -rP "%D{%FT%T.%6.%z}"
```

## Executables

Executable|Language|Version
:---:|:---:|:---:
cdate | C | GCC 8+
ccdate | C++ | Clang or GCC 14+
sdate | Swift | 5.10+

## Building

```sh
git clone https://github.com/franksplace/logtfmt/
cd logtfmt
./build.sh all
```

## Running

```sh
cd logtfmt
./bin/cdate
./bin/sdate
./bin/ccdate
```

### Example

```sh
cd logtfmt
bin/cdate
2024-05-29T14:19:12.131126-0700
```

## Benchmark

You'll need to install [Hyperfine](https://github.com/sharkdp/hyperfine) first.

```sh
cd logtfmt
./benchmark.zsh
```
### Benchmark Output Example

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/franksplace/logtfmt/blob/main/docs/logtfmt-benchmark-example-github-dark-theme.jpg">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/franksplace/logtfmt/blob/main/docs/logtfmt-benchmark-example-github-light-theme.jpg">
  <img alt="Benchmark Output Example" src="https://github.com/franksplace/logtfmt/blob/main/docs/logtfmt-benchmark-example-github-light-theme.jpg" width="640>
</picture>

## License

```Text
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
```
