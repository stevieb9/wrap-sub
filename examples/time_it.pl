#!/usr/bin/perl
use strict;
use warnings;

use Data::Dump;
use Time::HiRes qw(gettimeofday);
use Wrap::Sub;

# configure a pre-sub-call hook

my $pre = sub {
            return gettimeofday();
};

# configure a post-sub-call hook, using the result of the pre hook (the post
# return is stashed internally in this case).

my $post = sub {
            my ($pre_return, $sub_return) = @_;
            my $start = $pre_return->[0];
            my $time = gettimeofday() - $start;
            return "$Wrap::Sub::name ran for $time seconds";
};

# create the wrapper object, and set the hooks up. Setting the hooks in new()
# ensures that all subs in the module will be wrapped with the same actions

my $wrapper = Wrap::Sub->new(pre => $pre, post => $post);

# use the wrapper object, and wrap all subs in the module. Void context
# is not allowed, even though we won't be using the return value in this
# short example

my $wrapped_subs = $wrapper->wrap('Data::Dump');

# call a function within the wrapped module

dd {a => 1};

# later, near program exit, fetch the results of your hooks for every wrapped
# sub that was called. Note that the wrapped subs act as they always have,
# including output, return values etc.

my @results = $wrapper->results;

for (@results){
    print "$_->[0]\n";
}

__END__

# output

{ a => 1 }
Data::Dump::tied_str ran for 0.576534986495972 seconds
Data::Dump::_dump ran for 0.576592922210693 seconds
Data::Dump::_dump ran for 0.576611995697021 seconds
Data::Dump::format_list ran for 0.576628923416138 seconds
Data::Dump::dump ran for 0.576636075973511 seconds

