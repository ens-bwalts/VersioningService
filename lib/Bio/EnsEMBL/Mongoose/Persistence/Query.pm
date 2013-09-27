package Bio::EnsEMBL::Mongoose::Persistence::Query;
use Moose::Role;


use Config::General;

use FindBin qw/$Bin/;

has config_file => (
    isa => 'String',
    is => 'ro',
    required => 1,
    default = sub {
        return "$Bin/../conf/swissprot.conf";
    }
);

# $Bin/../conf/swissprot.conf
has config => (
    isa => 'HashRef',
    is => 'ro',
    required => 1,
    default => sub {
        my $self = shift;
        my $conf = Config::General->new($self->config_file);
        my %opts = $conf->getall();
        return \%opts;
    },
);

has query_string => (
    isa => 'Str',
    is => 'rw',
);

# Runs the supplied query through the query engine.
# Returns the result size if possible
sub query {
    
};


# Should iterate through results internally and emit the next result until there are no more.
sub next_result {
    
};

1;