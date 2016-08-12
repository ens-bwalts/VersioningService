=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

=pod

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <dev@ensembl.org>.

  Questions may also be sent to the Ensembl help desk at
  <helpdesk@ensembl.org>.

=head1 NAME

Bio::EnsEMBL::Versioning::Pipeline::ParseSource

=head1 DESCRIPTION

eHive pipeline module for the consumption of a downloaded resource into a document store

=cut

package Bio::EnsEMBL::Versioning::Pipeline::ParseSource;

use strict;
use warnings;

use Bio::EnsEMBL::Versioning::Broker;
use parent qw/Bio::EnsEMBL::Versioning::Pipeline::Base/;

use Try::Tiny;

sub run {
  my ($self) = @_;
  my $source_name = $self->param('source_name');
  my $specific_version = $self->param('version');
  my $broker = Bio::EnsEMBL::Versioning::Broker->new;

  my $version;
  if (defined $specific_version) {
    $version = $broker->get_version_of_source($source_name,$specific_version);
  } else {
    $version = $broker->get_current_version_of_source($source_name);
  }
  # Choose parser from DB entry for this source
  my $parser_name = $broker->get_module($broker->get_source($source_name)->parser);
  my $files = $broker->get_file_list_for_version($version);
  $files = $broker->shunt_to_fast_disk($files);
  my $temp = $broker->temp_location.'/'.$source_name.'.index';
  my $total_records = 0;
  my $doc_store;
  foreach (@$files) {
    my $parser = $parser_name->new(source_file => $_);
    
    $doc_store = $broker->document_store($temp);
    my $buffer = 0; 

    while($parser->read_record) {
      my $record = $parser->record;
      # validate record for key fields. No accession or ID makes it pretty useless to us
      if ($record->has_taxon_id && ($record->has_accessions || defined $record->id)) {
        $doc_store->store_record($record);
        $buffer++;
      }
      if ($buffer % 10000 == 0) {
          $doc_store->commit;
          $doc_store = $broker->document_store($temp);
      }
    }
    $total_records += $buffer;
    $doc_store->commit;
  }
  $self->warning(sprintf "Source %s,%s parsed with %d records and %d from the last loop",$source_name,$specific_version,$total_records,$buffer);
  # Copy finished index to desired location managed by Broker
  my $source = $broker->get_source($source_name);
  $broker->finalise_index($source,$specific_version,$doc_store,$total_records);
}

1;