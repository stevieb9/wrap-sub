#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Wrap::Sub');
};
{
    my $wrap = Wrap::Sub->new;
    my $w = $wrap->wrap('One::foo');

    One::foo();

    is ($w->wrapped_state, 1, "sub is wrapped");

    $w->unwrap;

    is ($w->wrapped_state, 0, "sub is unwrapped");
}
{
    my $wrap = Wrap::Sub->new;

    my $foo = $wrap->wrap('One::foo');
    is ($foo->wrapped_state, 1, "obj 1 has proper wrap state");

    is ($wrap->wrapped_state('One::foo'), 1, "wrap has proper wrap state on obj 1");

    my $bar = $wrap->wrap('One::bar');
    is ($bar->wrapped_state, 1, "obj 2 has proper wrap state");
    is ($bar->wrapped_state, 1, "wrap has proper wrap state on obj 2");

    $foo->unwrap;
    is ($foo->wrapped_state, 0, "obj 1 has proper unwrap state");
    is ($wrap->wrapped_state('One::foo'), 0, "wrap has proper umwrap state on obj 1");

    my $wrap2 = Wrap::Sub->new;

    eval { $wrap2->wrapped_state('One::foo'); };
    like (
        $@,
        qr/can't call wrapped_state()/,
        "can't call wrapped_state() on parent if a child hasn't been initialized and wrapped"
    );

    $foo->rewrap;
    is ($foo->wrapped_state, 1, "obj has proper wrap state with 2 wraps");
    is ($foo->wrapped_state, 1, "...and original wrap obj still has state");

    eval { $wrap->wrapped_state; };
    like ($@, qr/calling wrapped_state()/, "can't call wrapped_state on a top-level obj");
}

done_testing();
