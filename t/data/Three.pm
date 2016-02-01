package Three;
use strict;
use warnings;

sub one {
    sleep 1;
    two();
    sleep 1;
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
    sleep 1;
    five();
    five();
    five();
    five();
    return 1;
}
sub five {
    return 1;
}
1;