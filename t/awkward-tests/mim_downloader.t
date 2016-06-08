use Test::More;
use Test::Differences;
use Cwd;
use Bio::EnsEMBL::Versioning::Pipeline::Downloader::MIM;

use Log::Log4perl;
Log::Log4perl::init("$ENV{MONGOOSE}/conf/logger.conf");

my $mim = Bio::EnsEMBL::Versioning::Pipeline::Downloader::MIM->new();

my $version = $mim->get_version;
note("Downloading mim version (timestamp): ".$version);

my $result = $mim->download_to(cwd());
is($result->[0],cwd().'/omim.txt.gz','Download of matching OMIM file successful');

done_testing;