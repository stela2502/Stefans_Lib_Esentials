#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 49;
use stefans_libs::flexible_data_structures::data_table;
use File::Spec;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $startFolder, );

my $exec = $plugin_path . "/../bin/cleanRFtmp.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/cleanRFtmp";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}

sub createFiles {
	my ( $path, @ext ) = @_;
	unless ( defined $ext[0] ) {
		@ext = ('txt','log', 'R', 'lock', 'exe', 'xml' );
	}
	unless ( -d  $path ){
		mkdir( $path )
	}
	my ($fn, $blob, @files );
	foreach ( @ext ) {
		$fn = File::Spec->catfile( $path, "testFile.".$_ );
		open ($blob, ">$fn" ) or die "I can not create the file $fn: $!\n;";
		close ( $blob );
		push ( @files, $fn );
	}
	return @files;
}
## first lest try to create some crap
my $opath = File::Spec->catfile( $plugin_path,'data', 'output', 'toBeCleaned' );
push ( @values, &createFiles ( $opath ) );
push ( @values, &createFiles ( File::Spec->catfile( $opath, 'subpath1' ) ) );
push ( @values, &createFiles ( File::Spec->catfile( $opath, 'subpath1', 'subpath2' ) ) );
$exp = [ 
File::Spec->catfile( $opath, 'testFile.txt'), 
File::Spec->catfile( $opath, 'testFile.log'), 
File::Spec->catfile( $opath, 'testFile.R'), 
File::Spec->catfile( $opath, 'testFile.lock'), 
File::Spec->catfile( $opath, 'testFile.exe'), 
File::Spec->catfile( $opath, 'testFile.xml'), 
File::Spec->catfile( $opath, 'subpath1','testFile.txt'), 
File::Spec->catfile( $opath, 'subpath1','testFile.log'), 
File::Spec->catfile( $opath, 'subpath1','testFile.R'), 
File::Spec->catfile( $opath, 'subpath1','testFile.lock'), 
File::Spec->catfile( $opath, 'subpath1','testFile.exe'), 
File::Spec->catfile( $opath, 'subpath1','testFile.xml'), 
File::Spec->catfile( $opath, 'subpath1','subpath2','testFile.txt'), 
File::Spec->catfile( $opath, 'subpath1','subpath2','testFile.log'), 
File::Spec->catfile( $opath, 'subpath1','subpath2','testFile.R'), 
File::Spec->catfile( $opath, 'subpath1','subpath2','testFile.lock'), 
File::Spec->catfile( $opath, 'subpath1','subpath2','testFile.exe'), 
File::Spec->catfile( $opath, 'subpath1','subpath2','testFile.xml') 
];

#print "\$exp = ".root->print_perl_var_def( \@values ).";\n";

is_deeply( \@values, $exp, "expected files created");

my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -startFolder " .  $opath
. " -fileMatch 'nothing'"
;
#. " -debug";
my $start = time;
system( $cmd );
my $duration = time - $start;
print "Execution time: $duration s\n";

for (my $i = 0; $i< @values; $i ++ ) {
	ok(-f $values[$i], "files #$i");
}

$cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -startFolder " .  $opath
. " -fileMatch '^testFile'"
. " -ext unm"
;

system( $cmd );

for (my $i = 0; $i< @values; $i ++ ) {
	ok(-f $values[$i], "match unm files #$i");
}


$cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -startFolder " .  $opath
. " -fileMatch '^testFile'"
. " -ext log lock R"
;

system( $cmd );

my $drop = [ 
File::Spec->catfile( $opath, 'testFile.log'), 
File::Spec->catfile( $opath, 'testFile.R'), 
File::Spec->catfile( $opath, 'testFile.lock'), 
File::Spec->catfile( $opath, 'subpath1','testFile.log'), 
File::Spec->catfile( $opath, 'subpath1','testFile.R'), 
File::Spec->catfile( $opath, 'subpath1','testFile.lock'), 
File::Spec->catfile( $opath, 'subpath1','subpath2','testFile.log'), 
File::Spec->catfile( $opath, 'subpath1','subpath2','testFile.R'), 
File::Spec->catfile( $opath, 'subpath1','subpath2','testFile.lock') 
];

for (my $i = 0; $i < @$drop; $i ++ ) {
	ok( ! -f @$drop[$i], "match drop[$i] removed");
}

## And now kill the rest

my @ext = ('txt','log', 'R', 'lock', 'exe', 'xml' );

$cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -startFolder " .  $opath
. " -fileMatch '^testFile'"
. " -ext ". join(" ", @ext)
;

system( $cmd );

ok(  -d $opath,  "main folder still here" );

ok( ! -d File::Spec->catfile( $opath, 'subpath1'),  "the empty subfolder 1 is already removed." );


#print "\$exp = ".root->print_perl_var_def($value ).";\n";