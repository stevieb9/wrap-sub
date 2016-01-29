package Wrap::Sub;
use 5.006;
use strict;
use warnings;

use Carp qw(croak);
use Wrap::Sub::Child;
use Scalar::Util qw(weaken);

our $VERSION = '0.01';

sub new {
    my $self = bless {}, shift;
    %{ $self } = @_;
    return $self;
}
sub wrap {
    my $self = shift;
    my $sub = shift;

    if (ref $self ne 'Wrap::Sub'){
        croak "\ncan't call wrap() directly from the class. Create an object ".
              "with new() first.\n";
    }
    if (! defined wantarray){
        croak "\n\ncalling wrap() in void context isn't allowed. ";
    }

    my %p = @_;
    for (keys %p){
        $self->{$_} = $p{$_};
    }

    my $child = Wrap::Sub::Child->new;

    $child->pre($self->{pre}) if $self->{pre};

    if (defined $self->{post_return} && $self->{post}){
        $child->post($self->{post}, post_return => $self->{post_return});
    }
    elsif ($self->{post}){
        $child->post($self->{post});
    }

    $self->{objects}{$sub}{obj} = $child;
    $child->_wrap($sub);

    # remove the REFCNT to the child, or else DESTROY won't be called
    weaken $self->{objects}{$sub}{obj};

    return $child;
}
sub wrapped_subs {
    my $self = shift;

    my @names;

    for (keys %{ $self->{objects} }) {
        if ($self->wrapped_state($_)){
            push @names, $_;
        }
    }
    return @names;
}
sub wrapped_objects {
    my $self = shift;

    my @wrapped;
    for (keys %{ $self->{objects} }){
        push @wrapped, $self->{objects}{$_}{obj};
    }
    return @wrapped;
}
sub wrapped_state {
    my ($self, $sub) = @_;

    if (! $sub){
        croak "calling wrapped_state() on a Wrap::Sub object requires a sub " .
              "name to be passed in as its only parameter. ";
    }

    eval {
        my $test = $self->{objects}{$sub}{obj}->wrapped_state;
    };
    if ($@){
        croak "can't call wrapped_state() on the class if the sub hasn't yet " .
              "been wrapped. ";
    }
    return $self->{objects}{$sub}{obj}->wrapped_state;
}
sub DESTROY {
}
sub __end {}; # vim fold placeholder

1;
=head1 NAME

Wrap::Sub - Wrap subroutines with pre and post hooks, and more.

=for html
<a href="http://travis-ci.org/stevieb9/wrap-sub"><img src="https://secure.travis-ci.org/stevieb9/wrap-sub.png"/>
<a href='https://coveralls.io/github/stevieb9/wrap-sub?branch=master'><img src='https://coveralls.io/repos/stevieb9/wrap-sub/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    # see EXAMPLES for a full use case and caveats

    use Wrap::Sub;

    # create the parent wrap object

    my $wrap = Wrap::Sub->new;

    # wrap some subs...

    my $foo = $wrap->wrap('Package::foo');
    my $bar = $wrap->wrap('Package::bar');

    # wait until a wrapped sub is called

    Package::foo();

    # then...

    $foo->name;         # name of sub that's wrapped
    $foo->called;       # was the sub called?
    $foo->called_count; # how many times was it called?
    $foo->called_with;  # array of params sent to sub

    # have the wrapped sub return something when it's called (list or scalar).

    $foo->return_value(1, 2, {a => 1});
    my @return = Package::foo;

    # have the wrapped sub perform an action

    $foo->side_effect( sub { die "eval catch" if @_; } );

    eval { Package::foo(1); };
    like ($@, qr/eval catch/, "side_effect worked with params");

    # extract the parameters the sub was called with

    my @args = $foo->called_with;

    # reset the wrap object for re-use within the same scope

    $foo->reset;

    # restore original functionality to the sub

    $foo->unwrap;

    # re-wrap a previously unwrap()ed sub

    $foo->rewrap;

    # check if a sub is wrapped

    my $state = $foo->wrapped_state;

    # wrap out a CORE:: function. Be warned that this *must* be done within
    # compile stage (BEGIN), and the function can NOT be unwrapped prior
    # to the completion of program execution

    my ($wrap, $caller);

    BEGIN {
        $wrap = Wrap::Sub->new;
        $caller = $wrap->wrap('caller');
    };

    $caller->return_value(55);
    caller(); # wrapped caller() called

=head1 DESCRIPTION

Easy to use and very lightweight module for wraping out sub calls.
Very useful for testing areas of your own modules where getting coverage may
be difficult due to nothing to test against, and/or to reduce test run time by
eliminating the need to call subs that you really don't want or need to test.

=head1 EXAMPLE

Here's a full example to get further coverage where it's difficult if not
impossible to test certain areas of your code (eg: you have if/else statements,
but they don't do anything but call other subs. You don't want to test the
subs that are called, nor do you want to add statements to your code).

Note that if the end subroutine you're testing is NOT Object Oriented (and
you're importing them into your module that you're testing), you have to wrap
them as part of your own namespace (ie. instead of Other::first, you'd wrap
MyModule::first).

   # module you're testing:

    package MyPackage;
    
    use Other;
    use Exporter qw(import);
    @EXPORT_OK = qw(test);
   
    my $other = Other->new;

    sub test {
        my $arg = shift;
        
        if ($arg == 1){
            # how do you test this?... there's no return etc.
            $other->first();        
        }
        if ($arg == 2){
            $other->second();
        }
    }

    # your test file

    use MyPackage qw(test);
    use Wrap::Sub;
    use Test::More tests => 2;

    my $wrap = Wrap::Sub->new;

    my $first = $wrap->wrap('Other::first');
    my $second = $wrap->wrap('Other::second');

    # coverage for first if() in MyPackage::test
    test(1);
    is ($first->called, 1, "1st if() statement covered");

    # coverage for second if()
    test(2);
    is ($second->called, 1, "2nd if() statement covered");

=head1 MOCK OBJECT METHODS

=head2 C<new(%opts)>

Instantiates and returns a new C<Wrap::Sub> object, ready to be used to start
cteating wrapped sub objects.

Optional options:

=over 4

=item C<return_value =E<gt> $scalar>

Set this to have all wrapped subs created with this wrap object return anything
you wish (accepts a single scalar only. See C<return_value()> method to return
a list and for further information). You can also set it in individual wraps
only (see C<return_value()> method).

=item C<side_effect =E<gt> $cref>

Set this in C<new()> to have the side effect passed into all child wraps
created with this object. See C<side_effect()> method.

=back

=head2 C<wrap('sub', %opts)>

Instantiates and returns a new wrap object on each call. 'sub' is the name of
the subroutine to wrap (requires full package name if the sub isn't in
C<main::>).

The wrapped sub will return undef if a return value isn't set, or a side effect
doesn't return anything.

Optional parameters:

See C<new()> for a description of the parameters. Both the C<return_value> and
C<side_effect> parameters can be set in this method to individualize each wrap
object, and will override the global configuration if set in C<new()>.

There's also C<return_value()> and C<side_effect()> methods if you want to
set, change or remove these values after instantiation of a child sub object.

=head2 wrapped_subs

Returns a list of all the names of the subs that are currently wrapped under
the parent wrap object.

=head2 wrapped_objects

Returns a list of all sub objects underneath the parent wrap object, regardless
if its sub is currently wrapped or not.

=head2 wrapped_state('Sub::Name')

Returns 1 if the sub currently under the parent wrap object is wrapped or not,
and 0 if not. Croaks if there hasn't been a child sub object created with this
sub name.

=head1 SUB OBJECT METHODS

These methods are for the children wrapped sub objects returned from the
parent wrap object. See L<MOCK OBJECT METHODS> for methods related
to the parent wrap object.

=head2 C<unwrap>

Restores the original functionality back to the sub, and runs C<reset()> on
the object.

=head2 C<rewrap>

Re-wraps the sub within the object after calling C<unwrap> on it (accepts the
side_effect and return_value parameters).

=head2 C<called>

Returns true (1) if the sub being wrapped has been called, and false (0) if not.

=head2 C<called_count>

Returns the number of times the wrapped sub has been called.

=head2 C<called_with>

Returns an array of the parameters sent to the subroutine. C<croak()s> if
we're called before the wrapped sub has been called.

=head2 C<wrapped_state>

Returns true (1) if the sub the object refers to is currently wrapped, and
false (0) if not.

=head2 C<name>

Returns the name of the sub being wrapped.

=head2 C<side_effect($cref)>

Add (or change/delete) a side effect after instantiation.

Send in a code reference containing an action you'd like the
wrapped sub to perform.

The side effect function will receive all parameters sent into the wrapped sub.

You can use both C<side_effect()> and C<return_value()> params at the same
time. C<side_effect> will be run first, and then C<return_value>. Note that if
C<side_effect>'s last expression evaluates to any value whatsoever
(even false), it will return that and C<return_value> will be skipped.

To work around this and have the side_effect run but still get the
return_value thereafter, write your cref to evaluate undef as the last thing
it does: C<sub { ...; undef; }>.

=head2 C<return_value>

Add (or change/delete) the wrapped sub's return value after instantiation.
Can be a scalar or list. Send in C<undef> to remove previously set values.

=head2 C<reset>

Resets the functional parameters (C<return_value>, C<side_effect>), along
with C<called()> and C<called_count()> back to undef/false. Does not restore
the sub back to its original state.

=head1 NOTES

This module has a backwards parent-child relationship. To use, you create a
wrap object using L<PARENT MOCK OBJECT METHODS> C<new> and C<wrap> methods,
thereafter, you use the returned wrapped sub object L<METHODS> to perform the
work.

The parent wrap object retains certain information and statistics of the child
wrapped objects (and the subs themselves).

To wrap CORE::GLOBAL functions, you *must* initiate within a C<BEGIN> block
(see C<SYNOPSIS> for details). It is important that if you wrap a CORE sub,
it can't and won't be returned to its original state until after the entire
program process tree exists. Period.

I didn't make this a C<Test::> module (although it started that way) because
I can see more uses than placing it into that category.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 BUGS

Please report any bugs or requests at
L<https://github.com/stevieb9/wrap-sub/issues>

=head1 REPOSITORY

L<https://github.com/stevieb9/wrap-sub>

=head1 BUILD RESULTS

CPAN Testers: L<http://matrix.cpantesters.org/?dist=Wrap-Sub>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Wrap::Sub

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Wrap::Sub

