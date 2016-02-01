#!/usr/bin/perl
use strict;
use warnings;

use lib 't/data';

use Time::HiRes qw(gettimeofday);
use Three;
use Wrap::Sub;

my $pre = sub {
            return gettimeofday();
};
my $post = sub {
            my ($name, $pre_return, $sub_return) = @_;
            my $start = $pre_return->[0];
            my $time = gettimeofday() - $start;
            print "$name ran for $time seconds\n";
};

my $wrapper = Wrap::Sub->new(pre => $pre, post => $post);

my $wrapped_subs = $wrapper->wrap('Three');

Three::one();


