package Bio::EnsEMBL::Mongoose::Persistence::Record;
use Moose;

use Bio::EnsEMBL::Mongoose::Persistence::RecordXref;

has id => (
    isa => 'Str',
    is => 'rw',
    required => 0,
);

has sequence => (
    isa => 'Str',
    is => 'rw',
);

has sequence_length => (
    isa => 'Int',
    is => 'rw',
);

# Sequence version is independent of record version for some sources
has sequence_version => (
    isa => 'Int',
    is => 'rw',
);

# A location string, such as 6:1000-1010
has region => (
    isa => 'Str',
    is => 'rw',
);

has gene_name => (
    isa => 'Str',
    is => 'rw',
);

has protein_name => (
    isa => 'Str',
    is => 'rw',
);

has entry_name => (
    isa => 'Str',
    is => 'rw',
);

# first accession is the "primary" accession
has accessions => (
    isa => 'ArrayRef[Str]',
    is => 'rw',
    traits => ['Array'],
    predicate => 'has_accessions',
    handles => {
        'get_any_old_accession' => 'shift',
    }
);

has synonyms => (
    isa => 'ArrayRef[Str]',
    is => 'rw',
    traits => ['Array'],
    handles => {
        add_synonym => 'push'
    }
);

has xref => (
    isa => 'ArrayRef[Bio::EnsEMBL::Mongoose::Persistence::RecordXref]',
    is => 'rw',
    traits => ['Array'],
    default => sub {[]},
    handles => {
        add_xref => 'push',
        remove_xref => 'pop',
        grep_xrefs => 'grep',
        map_xrefs => 'map',
        count_xrefs => 'count',
    }
);

# The favourite accession/id/name for displaying to users
has display_label => (
    isa => 'Str',
    is => 'rw',
);

has description => (
    isa => 'Str',
    is => 'rw',
);

# Comment field is for supporting text that will be carried through to the browser.
has comment => (
    isa => 'Str',
    is => 'rw',
);

# For sequence equality matching
has checksum => (
    isa => 'Str',
    is => 'rw',
);

has version => (
    isa => 'Int',
    is => 'rw',
);

has taxon_id => (
    isa => 'Int',
    is => 'rw',
    predicate => 'has_taxon_id',
);

has schema_version => (
    isa => 'Int',
    is => 'rw',
);

has evidence_level => (
    isa => 'Int',
    is => 'rw',
);
# 1 = Protein level
# 2 = Transcript level
# 3 = Support by homology
# 4 = Predicted
# 5 = Uncertain

# Place to put warnings about why this record may not be reliable.
has suspicion => (
    isa => 'Str',
    is => 'rw',
);

sub TO_JSON {
    return {%{shift()}};
}

sub primary_accession {
    my $self = shift;
    my $accessions = $self->accessions();
    if ($accessions) {
        return shift @$accessions;
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;