=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 NAME

Bio::EnsEMBL::Versioning::Pipeline::Downloader::DBASS

=head1 DESCRIPTION

A module for DBASS data specific downloading methods

=cut

package Bio::EnsEMBL::Versioning::Pipeline::Downloader::DBASS;

use Moose;
use Try::Tiny;

extends 'Bio::EnsEMBL::Versioning::Pipeline::Downloader';

has host => (
  isa => 'Str',
  is => 'ro',
  default => 'http://www.dbass.soton.ac.uk/'
);

has remote_path => (
  isa => 'Str', 
  is => 'ro',
  default => 'dbass5/download.aspx?item=genes',
);

has file_pattern => (
  isa => 'Str',
  is => 'rw', # to allow test runs
  default => 'xref.php',
);

with 'Bio::EnsEMBL::Versioning::Pipeline::Downloader::RESTClient','MooseX::Log::Log4perl';

sub get_version
{
  my $self = shift;
  return $self->timestamp; 
}

sub _get_remote {
  my $self = shift;
  my $path = shift; # path is already checked as valid.

  my $result = $self->call(
    host => $self->host,
    path => $self->remote_path,
    file_path => $path,
    accepts => 'text/plain',
    file_name => 'dbass.csv');
  
  $self->log->debug('Downloaded DBASS file: ' . join("\n",  @$result));

  return $result if (scalar @$result > 0);

  Bio::EnsEMBL::Mongoose::NetException->throw("No files downloaded from DBASS site");
}

__PACKAGE__->meta->make_immutable;

1;