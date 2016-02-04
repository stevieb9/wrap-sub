#!/usr/bin/perl
use strict;
use warnings;

use lib 't/data';

use Data::Dumper;
use Devel::Trace::Subs qw(trace trace_dump);
use Three;
use Wrap::Sub;

$ENV{DTS_ENABLE} = 1;

my $pre = sub {
    return (caller(1))[3];
};

my $wrapper = Wrap::Sub->new(pre => $pre);
my $wrapped_subs = $wrapper->wrap('Three');

Three::one();

my @ret = $wrapper->pre_results;

print "$_->[0]\n" for @ret;

