#!/usr/bin/env perl
#
# Copyright 2024-2026 Frank Stutz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;
use POSIX       qw(strftime);
use Time::HiRes qw(time);
my $t = time();

my $m = ( $t - int($t) ) * 1e6;

printf strftime("%Y-%m-%d", localtime($t)) . "T"
  . strftime("%H:%M:%S", localtime($t)) . "."
  . sprintf("%06.0f", $m)
  . strftime("%z", localtime($t)) . "\n";
