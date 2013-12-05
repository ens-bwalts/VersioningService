use strict;
use warnings;

use Test::More;
use Test::Exception;

use Bio::EnsEMBL::Versioning::DB;
use Bio::EnsEMBL::DBSQL::DBAdaptor;

my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
-host => 'ens-production',
-species => 'multi',
-group => 'versioning',
-user => 'ensadmin',
-pass => 'ensembl',
-dbname => 'mr6_versioning_db'
);
Bio::EnsEMBL::Versioning::DB->register_DBAdaptor($dba);

require Bio::EnsEMBL::Versioning::Manager::Version;
require Bio::EnsEMBL::Versioning::Manager::Process;
require Bio::EnsEMBL::Versioning::Manager::Source;
require Bio::EnsEMBL::Versioning::Manager::SourceGroup;
require Bio::EnsEMBL::Versioning::Manager::SourceDownload;
require Bio::EnsEMBL::Versioning::Manager::Resources;
require Bio::EnsEMBL::Versioning::Manager::Run;

my $source = Bio::EnsEMBL::Versioning::Object::Source->new(name => 'RefSeq');
$source->source_group(name => 'RefSeq');
$source->save();
is($source->source_group_id, 1, "Source group was saved along with source");

my $resource = Bio::EnsEMBL::Versioning::Object::Resources->new(name => 'refseq_file', type => 'file', value => 'refseq.txt');
$resource->source_download(module => 'RefSeqParser');
$resource->source_download->source(name => 'RefSeq');
$resource->save();
is($resource->source_download_id(), 1, "Source download was saved along with resource");

my $version = Bio::EnsEMBL::Versioning::Object::Version->new(version => '12', record_count => 350, is_current => 1);
$version->source(name => 'Uniprot');
$version->source->source_group(name => 'UniprotGroup');
$version->save();
is($version->source->source_group->source_group_id(), 2, "UniprotGroup was correctly saved");


my $run = Bio::EnsEMBL::Versioning::Object::Run->new(start => 'now()');
$run->version($version);
$run->save();
my $process = Bio::EnsEMBL::Versioning::Object::Process->new(name => 'update');
$process->run($run);
$process->save();
is($process->run->start(), 'now()', "Updated start date for run");

my $second_version = Bio::EnsEMBL::Versioning::Object::Version->new(version => '11', record_count => 999);
$second_version->source(name => 'Uniprot');
$second_version->save();

my $third_version = Bio::EnsEMBL::Versioning::Object::Version->new(version => '12', record_count => 238, is_current => 1);
$third_version->source(name => 'UniprotTrEMBL');
$third_version->source->source_group(name => 'UniprotGroup');
$third_version->save();


my $versions = Bio::EnsEMBL::Versioning::Manager::Version->get_versions();
is(scalar(@$versions), 3, "Fetched all version");
my $uniprot_versions = Bio::EnsEMBL::Versioning::Manager::Version->get_all_versions('Uniprot');
is(scalar(@$uniprot_versions), 2, "Found all Uniprot versions");

my $current = Bio::EnsEMBL::Versioning::Manager::Version->get_current('Uniprot');
is($current->version(), 12, "Matching current version for Uniprot");


done_testing();