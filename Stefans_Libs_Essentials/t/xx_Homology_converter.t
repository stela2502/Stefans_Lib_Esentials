#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 6;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, @names, $outfile, $hom_file, $name_type, $B, $A, );

my $exec = $plugin_path . "/../bin/Homology_converter.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/Homology_converter";
if ( -d $outpath ) {
	system("rm -Rf $outpath/*");
}

$A = 10090;
$B = 9606;

#$A = 9606;
#$B = 10090;

ok( -f $plugin_path . "/data/some_mouse_genes.txt",
	"the input mouse genes file is OK" );

open( Mgenes, "<$plugin_path/data/some_mouse_genes.txt" ) or die $!;
while (<Mgenes>) {
	chomp();
	push( @names, split( /\s+/, $_ ) );
}
close(Mgenes);

#print "\$exp = ".root->print_perl_var_def( \@names ).";\n";
$exp = [
	'0610010K14Rik', '1110037F02Rik', '1700024P03Rik', '1700054O19Rik',
	'1700055D18Rik', '1700094J05Rik', '1700109H08Rik', '1810026B05Rik',
	'2310008H04Rik', '2310033P09Rik', '2310057M21Rik', '2500004C02Rik',
	'2510039O18Rik', '2610005L07Rik', '2610020C07Rik', '2610301B20Rik',
	'2610507B11Rik', '2700029M09Rik', '2700049A03Rik', '2700050L05Rik',
	'2700099C18Rik', '2810013P06Rik', '2810403A07Rik', '2810417H13Rik',
	'2810455O05Rik', '4632419I22Rik', '4632434I11Rik', '4833417C18Rik',
	'4922501C03Rik', '4930422G04Rik', '4930473A02Rik', '4930512B01Rik',
	'4930549G23Rik', '4932438A13Rik', '4933426M11Rik', '6330403K07Rik',
	'6330403N20Rik', '9030025P20Rik', '9130004J05Rik', '9130020K20Rik',
	'9130206I24Rik', '9430037G07Rik', '9630013D21Rik', 'A130049A11Rik',
	'A230045G11Rik', 'A430005L14Rik', 'A430104N18Rik', 'A430107P09Rik',
	'A830080D01Rik', 'Abca7',         'Abce1',         'Abcf1',
	'Abhd2',         'Acadl',         'Acat1',         'Acsl4',
	'Actl6a',        'Actr1a',        'Adipor2',       'Adnp',
	'Adrbk1',        'Afg3l2',        'Agfg2',         'Agrn',
	'Agtpbp1',       'Ahctf1',        'Ahcyl1',        'Ahsa2',
	'AI314180',      'Aida',          'Akap11',        'Akap8',
	'Akip1',         'Alms1',         'Amd1',          'Amfr',
	'Ammecr1l',      'Anapc15',       'Anapc2',        'Anapc4',
	'Anapc5',        'Anapc7',        'Angel2',        'Angpt2',
	'Ankhd1',        'Ankle2',        'Ankrd13a',      'Ankrd17',
	'Ankrd61',       'Anln',          'Anp32b',        'Ap1ar',
	'Apaf1',         'Apip',          'Apoo-ps',       'Arcn1',
	'Arf4',          'Arglu1',        'Arhgap11a',     'Arhgap17'
];

is_deeply( \@names, $exp, "right genes loaded" );

#$names[0] = $plugin_path."/data/some_mouse_genes.txt";

$outfile = "$outpath/to_human_symbols.txt";

$hom_file = $plugin_path . "/../data/HOM_MouseHumanSequence.rpt.gz";

my $cmd =
    "perl -I $plugin_path/../lib  $exec "
  . " -names "
  . join( ' ', @names )
  . " -outfile "
  . $outfile
  . " -hom_file "
  . $hom_file

  #. " -name_type " . $name_type
  . " -B " . $B . " -A " . $A . " -debug";
my $start = time;
system($cmd );
my $duration = time - $start;
print "Execution time: $duration s\n";

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
ok( -f $outfile, "outfile '$outfile'" );
@values = file_2_array($outfile);

#print "\$exp = " . root->print_perl_var_def( \@values ) . ";\n";

$exp = [
	'C17orf49', 'FAM98A',   'C1orf35',  'C10orf88', 'HDHD2',     'C8orf37',
	'KIAA0100', 'SNX17',    'KIAA0907', 'PRRT3',    'LOC728392', 'C1orf174',
	'CXorf23',  'ABCA7',    'RNH1',     'ABCF1',    'ABHD2',     'ACAA1',
	'ACAT1',    'ACSL4',    'ZNF213',   'ACTR1A',   'ADIPOR2',   'ADNP',
	'AFG3L2',   'AGFG2',    'CLVS2',    'ADGRF5',   'TMEM158',   'AHCYL1',
	'SPIRE2',   'KIAA0368', 'AIDA',     'SP1',      'AKAP8',     'AKIP1',
	'PHF8',     'AMFR',     'AMMECR1L', 'PNMA3',    'CNOT4',     'PACSIN3',
	'ANAPC7',   'SPICE1',   'ANGPT2',   'ANKHD1',   'PRR27',     'ANKRD13A',
	'FOXO6',    'ANKRD61',  'BATF3',    'DCANP1',   'AP1AR',     'APAF1',
	'APIP',     'ARCN1',    'ABCA2',    'TAPBPL',   'TSC22D2',   'GPATCH2'
];

is_deeply( \@values, $exp, "Human gene names" );

@names= ("$plugin_path/data/some_mouse_genes.txt" );

$cmd =
    "perl -I $plugin_path/../lib  $exec "
  . " -names "
  . join( ' ', @names )
  ." -name_is_list"
  . " -outfile "
  . $outfile
  . " -hom_file "
  . $hom_file

  #. " -name_type " . $name_type
  . " -B " . $B . " -A " . $A . " -debug";
$start = time;
unlink($outfile);
system($cmd );
$duration = time - $start;
print "Execution time: $duration s\n";

@values = file_2_array($outfile);

is_deeply( \@values, $exp, "read from flist file" );


sub file_2_array {
	my $file = shift;
	my @names;
	open( Mgenes, "<$file" ) or die $!;
	while (<Mgenes>) {
		chomp();
		push( @names, split( /\s+/, $_ ) );
	}
	close(Mgenes);
	return @names;
}


