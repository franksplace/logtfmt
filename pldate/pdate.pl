#!/usr/bin/env perl

use POSIX       qw(strftime);
use Time::HiRes qw(time);
$t = time;

$m = ( $t - int($t) ) * 1e6;    # microseconds e6
printf strftime( "%Y-%m-%d", localtime($t) ) . "T"
  . strftime( "%H:%M:%S", localtime($t) ) . "."
  . sprintf( "%06.0f", $m )
  . strftime( "%z", localtime($t) ) . "\n";
