#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More;

use lib 't/data';

BEGIN {
    use_ok('Wrap::Sub');
    use_ok('Two');
};
{
    my $wrap = Wrap::Sub->new;

    my $w = $wrap->wrap('One::call');

    my $caller = One::call();

    is ($caller, 'main', "caller() in a wrapped sub works");
    ok ($caller ne 'Wrap::Sub::Child', "caller() in a wrapped sub works");

    my @call_data = One::call();

    print Dumper \@call_data;

};

done_testing();
