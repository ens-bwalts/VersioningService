use Test::More;
use Test::Differences;

use FindBin qw/$Bin/;
use Log::Log4perl;
Log::Log4perl::init("$Bin/../conf/logger.conf");

use Bio::EnsEMBL::Mongoose::Parser::Swissprot;

# Uses uniprot BRAF record (P15056) to validate the Swissprot parser.
my $xml_reader = new Bio::EnsEMBL::Mongoose::Parser::Swissprot(
    source_file => "data/braf.xml"
);

my $seq = "MAALSGGGGGGAEPGQALFNGDMEPEAGAGAGAAASSAADPAIPEEVWNIKQMIKLTQEHIEALLDKFGGEHNPPSIYLEAYEEYTSKLDALQQREQQLLESLGNGTDFSVSSSASMDTVTSSSSSSLSVLPSSLSVFQNPTDVARSNPKSPQKPIVRVFLPNKQRTVVPARCGVTVRDSLKKALMMRGLIPECCAVYRIQDGEKKPIGWDTDISWLTGEELHVEVLENVPLTTHNFVRKTFFTLAFCDFCRKLLFQGFRCQTCGYKFHQRCSTEVPLMCVNYDQLDLLFVSKFFEHHPIPQEEASLAETALTSGSSPSAPASDSIGPQILTSPSPSKSIPIPQPFRPADEDHRNQFGQRDRSSSAPNVHINTIEPVNIDDLIRDQGFRGDGGSTTGLSATPPASLPGSLTNVKALQKSPGPQRERKSSSSSEDRNRMKTLGRRDSSDDWEIPDGQITVGQRIGSGSFGTVYKGKWHGDVAVKMLNVTAPTPQQLQAFKNEVGVLRKTRHVNILLFMGYSTKPQLAIVTQWCEGSSLYHHLHIIETKFEMIKLIDIARQTAQGMDYLHAKSIIHRDLKSNNIFLHEDLTVKIGDFGLATVKSRWSGSHQFEQLSGSILWMAPEVIRMQDKNPYSFQSDVYAFGIVLYELMTGQLPYSNINNRDQIIFMVGRGYLSPDLSKVRSNCPKAMKRLMAECLKKKRDERPLFPQILASIELLARSLPKIHRSASEPSLNRAGFQTEDFSLYACASPKTPIQAGGYGAFPVH";


$xml_reader->read_record;

my $record = $xml_reader->record;

is($record->gene_name,"BRAF", 'gene_name attribute check');
is($record->primary_accession, "P15056", 'primary_accession check');
cmp_ok($record->taxon_id, '==', 9606, 'taxon_id check');
cmp_ok($record->sequence_length, '==', 766, 'sequence_length check');
is($record->sequence,$seq, 'Make sure sequence regex-trimming does no harm, but removes white space');

ok(!$xml_reader->read_record, 'Check end-of-file behaviour. Reader should return false.');


done_testing;