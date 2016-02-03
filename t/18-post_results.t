#!/usr/bin/perl
use strict;
use warnings;

use Data::Dump;
use Data::Dumper;
use Test::More;
use Time::HiRes qw(gettimeofday);

use lib 't/data';

BEGIN {
    use_ok('Wrap::Sub');
    use_ok('Three');
};
{
    my $pre_cref = sub { return gettimeofday(); };

    my $post_cref = sub {
        my $pre_return = shift;
        my $time = gettimeofday() - $pre_return->[0];
        return "$Wrap::Sub::name took $time seconds\n";
    };

    my $w = Wrap::Sub->new( pre => $pre_cref, post => $post_cref);

    my $subs = $w->wrap('Three');

    Three::one();

    my @results = $w->results;

    is (@results, 8, "results() provides results");

    for (@results){
        like ($_->[0], qr/Three.*?took/, "results() $_->[0] ok");
    }

}
done_testing();

__DATA__
Three::one
Three::two
Three::three
Three::four
Three::five
