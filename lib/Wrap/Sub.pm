package Wrap::Sub;
use 5.006;
use strict;
use warnings;

use Carp qw(croak);
use Devel::Examine::Subs;
use Scalar::Util qw(weaken);
use Wrap::Sub::Child;

our $VERSION = '0.04';

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
sub __end {}; # vim fold placeholder

1;
=head1 NAME

Wrap::Sub - Wrap subroutines with pre and post hooks, and more.

=for html
<a href="http://travis-ci.org/stevieb9/wrap-sub"><img src="https://secure.travis-ci.org/stevieb9/wrap-sub.png"/>
<a href='https://coveralls.io/github/stevieb9/wrap-sub?branch=master'><img src='https://coveralls.io/repos/stevieb9/wrap-sub/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

=head1 DESCRIPTION

This module allows you to wrap subroutines with pre and post hooks, with the
ability to change the parameters sent to the sub, and/or the return from the
sub. Thanks to code taken out of L<Hook::LexWrap>.

There are other modules that do this, see L<SEE ALSO>. I wrote it out of sheer
curiosity and experience.

=head1 WRAP OBJECT METHODS

=head2 C<new(%opts)>

Instantiates and returns a new C<Wrap::Sub> object, ready to be used to start
cteating wrapped sub objects.

Options (note that if these are set in C<new()>, all subs wrapped with this
object will exhibit the same behaviour. Set in C<mock()> or use C<pre()> and
C<post()> methods to individualize wrapped subroutine behaviour.

=over 4

=item C<pre =E<gt> $cref>

A code reference containing actions that will be executed prior to executing
the sub that's wrapped. Receives the parameters that are sent into the wrapped
sub (C<@_>).

=item C<post =E<gt> $cref>

A code reference containing actions that will be executed after the wrapped
sub is executed.

Receives an array reference containing an array reference holding the return
values from C<pre()> and a second array reference containing the return values
from the actual wrapped sub. If neither C<pre> or the actual sub have return
values, the respective array reference will be empty.

Returns an array reference containing any return values specified in the passed
in code reference.

=item C<post_return =E<gt> Bool>

Set this to true if you want your C<post()> hook to return it's results, and
false if you want the return value(s) from the actual wrapped sub instead.

=back

=head2 C<wrap('sub', %opts)>

Instantiates and returns a new wrap object on each call. 'sub' is the name of
the subroutine to wrap (requires full package name if the sub isn't in
C<main::>).

Options:

See C<new()> for a description of the parameters. Setting them here allows you
to individualize behaviour of the hooks for each wrapped subroutine.

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

=head1 WRAPPED SUB OBJECT METHODS

These methods are for the children wrapped sub objects returned from the
parent wrap object. See L<WRAP OBJECT METHODS> for methods related
to the parent wrap object.

=head2 C<unwrap>

Restores the original functionality back to the sub, and runs C<reset()> on
the object.

=head2 C<rewrap>

Re-wraps the sub within the object after calling C<unwrap> on it.

=head2 C<called>

Returns true (1) if the sub being wrapped has been called, and false (0) if not.

=head2 C<called_with>

Returns an array of the parameters sent to the subroutine. C<croak()s> if
we're called before the wrapped sub has been called.

=head2 C<wrapped_state>

Returns true (1) if the sub the object refers to is currently wrapped, and
false (0) if not.

=head2 C<name>

Returns the name of the sub being wrapped.

=head2 C<pre($cref)>

Send in a code reference containing actions that you want to have performed
prior to the wrapped sub being executed.

=head2 C<post($cref, post_return =E<gt> Bool)>

A code reference containing actions that will be executed after the wrapped
sub is executed.

The code supplied receives an array reference containing an array reference
holding the return values from C<pre()> and a second array reference containing
the return values from the actual wrapped sub. If neither C<pre> or the actual
sub have return values, the respective array reference will be empty.

The optional parameter C<post_return> specifies that you want the return
value(s) from this function instead of the return value(s) generated by the
wrapped sub. Disabled by default.

=head2 C<reset>

Resets the functional parameters (C<pre>, C<post> and C<post_return>), along
with C<called()> and C<called_with> back to undef/false. Does not restore
the sub back to its original state.

=head1 NOTES

This module has a backwards parent-child relationship. To use, you create a
wrap object using L<WRAP OBJECT METHODS> C<new> and C<wrap> methods,
thereafter, you use the returned wrapped sub object L<WRAPPED SUB OBJECT METHODS>
to perform the work.

=head1 SEE ALSO

This module was created for my own sheer curiosity and experience. There are
quite a few like it. I've never used any of them (this list was taken from
L<Hook::WrapSub>):

L<Hook::LexWrap> provides a similar capability to C<Hook::WrapSub>,
but has the benefit that the C<caller()> function works correctly
within the wrapped subroutine.

L<Sub::Prepend> lets you provide a sub that will be called before
a named sub. The C<caller()> function works correctly in the
wrapped sub.

L<Sub::Mage> provides a number of related functions.
You can provide pre- and post-call hooks,
you can temporarily override a function and then restore it later,
and more.

L<Class::Hook> lets you add pre- and post-call hooks around any
methods called by your code. It doesn't support functions.

L<Hook::Scope> lets you register callbacks that will be invoked
when execution leaves the scope they were registered in.

L<Hook::PrePostCall> provides an OO interface for wrapping
a function with pre- and post-call hook functions.
Last updated in 1997, and marked as alpha.

L<Hook::Heckle> provides an OO interface for wrapping pre- and post-call
hooks around functions or methods in a package. Not updated sinc 2003,
and has a 20% failed rate on CPAN Testers.

L<Class::Wrap> provides the C<wrap()> function, which takes a coderef
and a package name. The coderef is invoked every time a method in
the package is called.

L<Sub::Versive> lets you stack pre- and post-call hooks.
Last updated in 2001.

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

