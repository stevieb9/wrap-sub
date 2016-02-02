#!/usr/bin/perl
use strict;
use warnings;

use lib 't/data';

use Three;
use Time::HiRes qw(gettimeofday);
use Wrap::Sub;

    my $wrapper = Wrap::Sub->new;

    # simple example

    my $foo_obj  = $wrapper->wrap(
        'Three::foo',
        pre  => sub { print "$Wrap::Sub::name in pre\n"; },
        post => sub { print "$Wrap::Sub::name in post\n"; },
    );

    $foo_obj->post(sub { print "changed post\n"; } );

    # unwrap

    $foo_obj->unwrap;

    # rewrap

    $foo_obj->rewrap;

    # state

    print $foo_obj->name . " is wrapped\n" if $foo_obj->wrapped_state;

    # list the names of all subs

    print "$_\n" for $wrapper->wrapped_subs;

    # time sub

    my $pre_cref = sub {
        return gettimeofday();
    };

    my $post_cref = sub {
        my $pre_return = shift;
        my $time = gettimeofday() - $pre_return->[0];
        print "$Wrap::Sub::name finished in $time seconds\n";
    };

    $foo_obj->pre($pre_cref);
    $foo_obj->post($post_cref);

    # manipulate sub return and do post return

    #
    $foo_obj->pre(undef);
    #

    $post_cref = sub {
        my ($pre_return, $sub_return) = @_;
        if ($sub_return->[0] != 1){
            die "$Wrap::Sub::name returned an error\n";
        }
        else {
            $sub_return->[0] = 100;
            return $sub_return->[0];
        }
    };
    $foo_obj->post($post_cref, post_return => 1);

    # my $ret = Three::foo(1);
    # print "$ret\n";

    {
        # wrap all subs in module to do the same thing

        my $w = Wrap::Sub->new(
            pre  => sub { print "start $Wrap::Sub::name\n"; },
            post => sub { print "finish $Wrap::Sub::name\n"; },
        );

        my $module_subs = $w->wrap('Three');

        Three::one();

        # unwrap them all, and confirm

        for my $sub_name (keys %$module_subs){
            my $sub_obj = $module_subs->{$sub_name};

            print "$sub_name is wrapped\n" if $sub_obj->wrapped_state;

            $sub_obj->unwrap;
            if ($sub_obj->wrapped_state) {
                die "$sub_name not unwrapped!"
            }
        }
    }
