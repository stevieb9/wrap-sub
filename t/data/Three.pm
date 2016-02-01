package Three;
use strict;
use warnings;

sub one {
    two();
    return 1;
}
sub two {
    three();
    return 1;
}
sub three {
    four();
    return 1;
}
sub four {
    sleep 0.5;
    return 1;
}
1;