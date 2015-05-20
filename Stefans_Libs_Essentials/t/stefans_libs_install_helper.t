#! /usr/bin/perl
use strict;
use warnings;
use Digest::MD5;
use stefans_libs::root;
use Test::More tests => 13;
BEGIN { use_ok 'stefans_libs::install_helper' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
my $obj = stefans_libs::install_helper->new();
is_deeply(
	ref($obj),
	'stefans_libs::install_helper',
	'simple test of function stefans_libs::install_helper -> new()'
);

## create some files to be copied
## folder D with files E, F and G
my $files = [ 'A', 'B', 'C', { 'D' => [ 'E', 'F', 'G' ] }, ];

my $inpath = $plugin_path."/data/output/source_files/";
my $outpath = $plugin_path."/data/output/target_files/";
system ( "rm -Rf $outpath") if ( -d $outpath);
mkdir ( $inpath ) unless ( -d $inpath);
&create_files( $files, $inpath );
$value = &check_files( $files, $inpath, 1 );
$exp = {
  'D' => {
  'F' => '1',
  'E' => '1',
  'G' => '1'
},
  'C' => '1',
  'A' => '1',
  'B' => '1'
};
is_deeply( $value, $exp, "the files have been created as expected" );
#print "\$exp = ".root->print_perl_var_def($value ).";\n";

$obj-> copy_files ( $inpath, $outpath );

is_deeply ( &check_files( $files, $inpath ),&check_files( $files, $outpath ), "did copy the files as expected" );
my $old_exp = &check_files( $files, $inpath );

&create_files( $files, $inpath );
$obj-> copy_files ( $inpath, $outpath );
is_deeply ( &check_files( $files, $inpath ),&check_files( $files, $outpath ), "the files are updated :-)" );
#is_deeply (&check_files( $files, $outpath ), $old_exp, "the files are not updated!" );

system ( "rm -Rf $outpath");

$obj-> copy_files ( $inpath, $outpath, '', {'A' => 1, 'D' => {'E' => 1} } );

ok( -f $outpath.'A', 'first level copy files if not existent');
ok( -f $outpath.'D/E', 'second level copy files if not existent');
$old_exp = &check_files( $files, $inpath );
&create_files( $files, $inpath );
my $new_exp = &check_files( $files, $inpath );
$obj-> copy_files ( $inpath, $outpath, '', {'A' => 1, 'D' => {'E' => 1} } );
$value = check_files( $files, $outpath );
ok ( $old_exp->{'A'} eq $value->{'A'}, 'old file A' );
ok ( !( $new_exp->{'A'} eq $value->{'A'}), 'the new file A is different from the used');
ok ( $old_exp->{'D'}->{'E'} eq $value->{'D'}->{'E'}, 'old file D/E' );
ok ( !( $new_exp->{'D'}->{'E'} eq $value->{'D'}->{'E'}), 'the new file D/E is different from the used');
ok ( !( $old_exp->{'B'} eq $value->{'B'}), 'old file B has been lost' );
ok ( $new_exp->{'B'} eq $value->{'B'}, 'the file B has been updated to the new version');

#warn  "OLD_EXP = ".root->print_perl_var_def( $old_exp ).";\n";
#warn  "NEW_EXP = ".root->print_perl_var_def( $new_exp ).";\n";
#warn  "copied = ".root->print_perl_var_def( $value ).";\n";


sub create_files {
	my ( $files, $path ) = @_;
	foreach ( @{$files} ) {
		if ( ref($_) eq "HASH" ) {
			foreach my $subfolder ( keys %$_ ) {
				mkdir ( $path.$subfolder );
				&create_files( $_->{$subfolder}, $path . "$subfolder/" );
			}
		}
		else {
			open( OUT, ">$path/$_" ) or die $!;
			print OUT rand(9000);
			close(OUT);
		}
	}
}

sub check_files {
	my ( $files, $path ,$noMD5 ) = @_;
	my $ret;
	foreach ( @{$files} ) {
		if ( ref($_) eq "HASH" ) {
			foreach my $subfolder ( keys %$_ ) {
				next unless ( -d $path . "$subfolder/" );
				$ret -> { $subfolder } = 
				&check_files( $_->{$subfolder}, $path . "$subfolder/", $noMD5 );
			}
		}
		else {
			next unless ( -f  "$path/$_" );
			if ( $noMD5 ) {
				$ret -> { $_ } = 1;
			}
			else {
				$ret -> { $_ } = $obj->file2md5str( "$path/$_" );
			}
		}
	}
	return $ret;
}




#print "\$exp = ".root->print_perl_var_def($value ).";\n";

