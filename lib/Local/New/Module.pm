use strict;
use warnings;

## no critic (RequireCarping)
BEGIN { die 'Unsupported Perl version, stopped' if $] < 5.006_002 };    # uncoverable branch true
## use critic (RequireCarping)

package Local::New::Module;

# keeping the following $VERSION declaration on a single line is important
#<<<
use version 0.9915 qw( ); our $VERSION = version->declare( '1.0.0' );
#>>>

1
