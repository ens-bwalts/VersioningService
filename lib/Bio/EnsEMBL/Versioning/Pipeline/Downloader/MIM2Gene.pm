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

=cut

=head1 NAME

Bio::EnsEMBL::Versioning::Pipeline::Downloader::MIM2Gene

=head1 DESCRIPTION

A module for OMIM specific downloading methods

=cut

package Bio::EnsEMBL::Versioning::Pipeline::Downloader::MIM2Gene;

use Moose;

extends 'Bio::EnsEMBL::Versioning::Pipeline::RESTDownloader';

sub BUILD {
  my $self = shift;
  $self->host('http://omim.org/');
  $self->remote_path('static/omim/data/');
  $self->file_pattern('mim2gene.txt');
  $self->accepts('application/octet-stream');
  $self->file_name('mim2gene.txt');
}

sub get_version
{
  my $self = shift;
  return $self->timestamp;
}

__PACKAGE__->meta->make_immutable;

1;
