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

  FusekiWrapper - interface of functions that wrap a transitory triplestore Fuseki instance

=head1 SYNOPSIS

  my $fuseki = Bio::EnsEMBL::RDF::FusekiWrapper->new();
  $fuseki->load_data([$ttl_file1, $ttl_file2, $ttl_file3]);
  $query($sparql);
  
=head1 DESCRIPTION

  Provides functionality to deploy a memory-only triplestore instance
  Note, needs the FUSEKI_HOME environmental set to the folder where fuseki-server and its libraries reside

=cut

package Bio::EnsEMBL::RDF::FusekiWrapper;

use Moose;
use Bio::EnsEMBL::Mongoose::NetException;
use Bio::EnsEMBL::Mongoose::IOException;
use Bio::EnsEMBL::Mongoose::DBException;
use Bio::EnsEMBL::Mongoose::UsageException;
use Bio::EnsEMBL::Mongoose::Persistence::TriplestoreQuery;
use Try::Tiny;

has port => ( isa => 'Int', is => 'rw', default => sub {{ return int(rand(1000)) +3000 }});
has graph_name => ( isa => 'Str', is => 'rw', default => 'xref');
has server_url => ( isa => 'Str', is => 'rw');
# Port randomly selected between 3000 and 4000 to try to avoid collision if two processes launch on the same machine
has sparql => ( is => 'rw', lazy => 1, builder => '_init_sparql_client');

with 'Bio::EnsEMBL::Mongoose::Utils::BackgroundLauncher';

sub _init_sparql_client {
  my $self = shift;
  Bio::EnsEMBL::Mongoose::Persistence::TriplestoreQuery->new(
    triplestore_url => sprintf ("%ssparql", $self->server_url), 
    graph => $self->graph_name
  )
}

sub start_server {
  my $self = shift;
  $self->command('java');
  # Note, cannot mix java opts with process opts without the option hash getting shuffled
  $self->args->{'-Xmx10000M'} = undef;
  unless (defined $ENV{FUSEKI_HOME}) { Bio::EnsEMBL::Mongoose::UsageException->throw("Cannot run Fuseki without FUSEKI_HOME environment variable set")}
  $self->args->{'-jar'} = $ENV{FUSEKI_HOME}.'fuseki-server.jar';
  $self->tail_end(sprintf "--update --port %s --mem %s ",$self->port,'/'.'xref');
  # print "Fuseki options: ".join ',',$self->unpack_args,"\n";
  try {
    $self->run_command();
    sleep 3; # Wait a bit while the VM lurches into life
    print "Started Fuseki instance on port ".$self->port if $self->background_process_alive;
  } catch {
    Bio::EnsEMBL::Mongoose::DBException->throw("Unable to start Fuseki server: \n$_ \n");
  };
  $self->server_url(sprintf "http://0.0.0.0:%s/xref/",$self->port);
  return $self->server_url;
}

sub load_data {
  my $self = shift;
  my $data_files = shift;
  my $optional_graph_name = shift;
  $optional_graph_name ||= $self->graph_name;
  $self->graph_name($optional_graph_name) if $optional_graph_name;
  $self->start_server unless $self->background_process_alive;
  my @files = @$data_files;
  try {
    foreach my $file (@files) {
      my @commands = ('s-put', sprintf('%s',$self->server_url,'xref'), $optional_graph_name,$file);
      my $response = system(@commands);
      # if response is favourable?
      if ($response != 0) {
        Bio::EnsEMBL::Mongoose::DBException->throw("Loading data into Fuseki failed with error $?");    
      }
    }
  } catch {
    Bio::EnsEMBL::Mongoose::DBException->throw("Attempting to load files into server on ".$self->port.":".join(',',@files)." but failed with error $_");
  };
}

sub query {
  my $self = shift;
  my $query = shift;
  # print "Query received in FusekiWrapper: $query\n";
  # print "Sending query in FusekiWrapper to: ".$self->sparql->triplestore_url."\n";
  try {
    $self->sparql->query($query);
    # $self->sparql($sparqler);
  } catch {
    Bio::EnsEMBL::Mongoose::DBException->throw("Unable to query Fuseki graph ".$self->graph_name." with error $_");
  };
  return;
}

sub delete_data {
  my $self = shift;
  my $graph_name = shift;
  Bio::EnsEMBL::Mongoose::DBException->throw("Cannot delete $graph_name from Fuseki, server not running.") unless $self->background_process_alive;
  my @commands = ('s-update', '--service',sprintf('%supdate',$self->server_url),"CLEAR GRAPH <$graph_name>");
  my $response = system(@commands);
  if ($response != 0) {
    Bio::EnsEMBL::Mongoose::DBException->throw("Delete did not go as planned, $?");
  }
}

__PACKAGE__->meta->make_immutable;
1;
