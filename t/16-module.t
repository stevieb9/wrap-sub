#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More;

use lib 't/data';

BEGIN {
    use_ok('Wrap::Sub');
    use_ok('Test::Three');
};
{
    my $wrap = Wrap::Sub->new;
    my $subs = $wrap->wrap('Three');

    is (ref $subs, 'HASH', "when wrapping all subs, return is a hashref");

    my @ok = qw(Three::one Three::two Three::three Three::four);

    for my $key (keys %$subs){
        my @in = grep(/$key/, @ok);

        is (@in, 1, "$key is in the return");
        is (ref $subs->{$key}, 'Wrap::Sub::Child', "$key sub has a name and is an obj") ;
    }
};

done_testing();
