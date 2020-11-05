#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 13;
BEGIN { use_ok 'stefans_libs::flexible_data_structures::optionsFile' }

use FindBin;
use File::Spec::Functions;
use stefans_libs::root;

my $plugin_path = "$FindBin::Bin";

my $outpath = "$plugin_path/data/output/optionsFile";
if ( -d $outpath ) {
	system("rm -Rf $outpath/*");
}else {
	mkdir( $outpath );
}

my $ofile = File::Spec::Functions::catfile($outpath,"test_options.txt");

if ( -f $ofile ){
	unlink( $ofile );
}

my ( $value, @values, $exp );
my $OBJ = stefans_libs::flexible_data_structures::optionsFile -> new({
	'default_file' => $ofile,
	'required' => [ 'A', 'B', 'C'], 
	'optional' => ['a','b','c'], 
	'debug' => 1
});

$OBJ->load(undef,0);

$OBJ = stefans_libs::flexible_data_structures::optionsFile -> new({
	'default_file' => $ofile,
	'required' => [ 'A', 'B', 'C'], 
	'optional' => ['a','b','c'], 
	'debug' => 1
});

ok (1 ,"loding a not existing file does not need to kill the script");

is_deeply ( ref($OBJ) , 'stefans_libs::flexible_data_structures::optionsFile', 'simple test of function stefans_libs::flexible_data_structures::optionsFile -> new() ');

ok ( ! $OBJ->OK(), "the object is not OK if nothing is loaded or added" );


foreach (@{ $OBJ->{required} }) {
	$OBJ->add( $_, lc($_) );
}

ok ( $OBJ->OK(), "the object is OK after adding the required options" );

is_deeply( $OBJ->options(), { 'A' => 'a', 'B' => 'b', 'C' => 'c'}, "options stored correctly in memory" );

foreach (@{ $OBJ->{optional} }) {
	$OBJ->add( $_, uc($_) );
}
if ( -f $ofile){
	unlink($ofile)
}
ok( ! -f $ofile, "ofile not existsing" );
$OBJ->save();
ok( -f $ofile , "ofile created" );

@values= &to_array();
#print "\$exp = ".root->print_perl_var_def(\@values ).";\n";
$exp = [ '## required:', 'A	a', 'B	b', 'C	c', '## optional:', 'a	A', 'b	B', 'c	C' ];

is_deeply( \@values, $exp, "options file created correctly");

$OBJ = stefans_libs::flexible_data_structures::optionsFile -> new({
	'default_file' => $ofile,
	'required' => [ 'A', 'B', 'C'], 
	'optional' => ['a','b','c'], 
	'debug' => 1
});

ok ( ! $OBJ->OK(), "the re-created object is not OK if nothing is loaded or added" );

$OBJ->load();

is_deeply( $OBJ->options(), { 'A' => 'a', 'B' => 'b', 'C' => 'c', 'a' => 'A', 'b'=> 'B', 'c' => 'C' }, "options stored correctly in file" );

$OBJ->drop('a');
is_deeply( $OBJ->options(), { 'A' => 'a', 'B' => 'b', 'C' => 'c', 'b'=> 'B', 'c' => 'C' }, "options stored correctly in file" );

ok ( $OBJ->value('A') eq "a", "value function");

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


sub to_array {
	open ( IN, "<$ofile" ) or die $!;
	my @return  = map{ chomp; $_ } <IN>;
	close ( IN );
	return @return;
}
