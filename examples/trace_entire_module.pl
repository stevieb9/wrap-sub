#!/usr/bin/perl
use strict;
use warnings;

use lib 't/data';

use Devel::Trace::Subs qw(trace trace_dump);
use Three;
use Wrap::Sub;

$ENV{DTS_ENABLE} = 1;

my $pre = sub {
    trace();
};

my $wrapper = Wrap::Sub->new(pre => $pre);
my $wrapped_subs = $wrapper->wrap('Three');

Three::one();

trace_dump();


