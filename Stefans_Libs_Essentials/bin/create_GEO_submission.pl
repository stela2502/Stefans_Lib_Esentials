#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2017-07-05 Stefan Lang

  This program is free software; you can redistribute it 
  and/or modify it under the terms of the GNU General Public License 
  as published by the Free Software Foundation; 
  either version 3 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License 
  along with this program; if not, see <http://www.gnu.org/licenses/>.

=head1 CREATED BY
   
   binCreate.pl from  commit 
   

=head1  SYNOPSIS

    create_GEO_submission.pl
       -xls       :the GEO submission xls description file
       -dataPath  :the path where all possible data files are stored
       -outpath   :the outpath to that should go to NCBI - GEO

       -copyExisting: Do not die if a file does not exist.
       -link_only   :Do not copy but create hard links (unix only 'ln')

       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Check files and create a folder including all required files.

  To get further help use 'create_GEO_submission.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;
use File::Spec;
use File::Copy "cp";
use stefans_libs::flexible_data_structures::data_table;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $xls, $dataPath, $copyExisting, $link_only,
	$outpath );

Getopt::Long::GetOptions(
	"-xls=s"        => \$xls,
	"-dataPath=s"   => \$dataPath,
	"-outpath=s"    => \$outpath,
	"-copyExisting" => \$copyExisting,
	"-link_only"    => \$link_only,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $xls ) {
	$error .= "the cmd line switch -xls is undefined!\n";
}
unless ( defined $dataPath ) {
	$error .= "the cmd line switch -dataPath is undefined!\n";
}
unless ( defined $outpath ) {
	$error .= "the cmd line switch -outpath is undefined!\n";
}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	print "$errorMessage.\n";
	pod2usage( q(-verbose) => 1 );
}

my ($task_description);

$task_description .= 'perl ' . $plugin_path . '/create_GEO_submission.pl';
$task_description .= " -xls '$xls'" if ( defined $xls );
$task_description .= " -dataPath '$dataPath'" if ( defined $dataPath );
$task_description .= " -outpath '$outpath'" if ( defined $outpath );
$task_description .= " -copyExisting" if ($copyExisting);
$task_description .= " -link_only" if ($link_only);

mkdir($outpath) unless ( -d $outpath );
my @out = split( "/", $outpath );
my $ext;
while ( !$ext ) {
	$ext = pop(@out);
	last if ( @out == 0 );
}
open( LOG, ">$outpath/../$ext." . $$ . "_create_GEO_submission.pl.log" )
  or die $!;
print LOG $task_description . "\n";
close(LOG);

## Do whatever you want!

#(1) create a tmp folder where we can extract the XLS files to
mkdir( File::Spec->catpath( $outpath, 'tmp' ) )
  unless ( -d File::Spec->catpath( $outpath, 'tmp' ) );

cp( $xls, $outpath );    ## copy the xls file to the outpath

system( "xls_2_tab.pl -infile $xls -outfile "
	  . File::Spec->catpath( $outpath, 'tmp', "GEO_submission" ) );

## open this catpath($outpath, 'tmp',"GEO_submission_tab1.xls") file
my $data_table = data_table->new(
	{
		'filename' =>
		  File::Spec->catpath( $outpath, 'tmp', "GEO_submission_tab1.xls" )
	}
);

## this file contains rows that contain a filename in col 1 and md5sum in col 3 these files I need to find.
## and ultimately check that the md5sum is correct

my ( $files, $l );
{
	local $SIG{__WARN__} = sub { };    ## I do not want to see errors here...
	for ( my $i = 0 ; $i < $data_table->Lines() ; $i++ ) {
		$l = @{ $data_table->{'data'} }[$i];

		if ( @$l[3] eq "" and length( @$l[2] ) == 32 ) {
			## this is defined as a file here...
			if ( $files->{ @$l[0] } ) {
				Carp::confess(
"File @$l[0] is mentioned twice and has two different md5sums in the xml"
				) unless ( @$l[2] eq @$l[2] );
				warn "file @$l[0] mentioned twice - error in the xml!\n";
			}
			$files->{ @$l[0] } = @$l[2];
		}
	}
}

## now I need to identify the files and put them into the outpath.

open( MD5, "find $dataPath -type f -exec md5sum {} + |" )
  or die "I could not collect the md5sums!\n$!\n";
my $available;
while (<MD5>) {
	chomp($_);
	$l = [ split( /\s+/, $_ ) ];
	$available->{ @$l[1] } = @$l[0];
}
close(MD5);

my $available_fn;
my $err;
if ($copyExisting) {
	open( LOG, ">>$outpath/../$ext." . $$ . "_create_GEO_submission.pl.log" )

}

foreach my $required_fn ( keys %$files ) {
	($available_fn) = grep( /$required_fn/, keys %$available );
	if ( defined $available->{$available_fn} ) {
		if ( $files->{$required_fn} eq $available->{$available_fn} ) {
			warn "I copy \n\t$available_fn\nto\n\t"
			  . File::Spec->catfile( $outpath, $required_fn ) . "\n"
			  if ($debug);
			if ($link_only) {
				system( "ln "
					  . $available_fn . " "
					  . File::Spec->catfile( $outpath, $required_fn ) )
				  unless ( -f File::Spec->catfile( $outpath, $required_fn ) );
			}
			else {
				cp( $available_fn,
					File::Spec->catfile( $outpath, $required_fn ) )
				  unless ( -f File::Spec->catfile( $outpath, $required_fn ) )
				  ;
			}
		}
		else {
			$err =
"md5sums for the required file '$required_fn' ($files->{$required_fn}) "
			  . "does not match the identified file '$available_fn' ($available->{$available_fn})\n"
			  . "\$existing ="
			  . root->print_perl_var_def($available)
			  . "\n\$required="
			  . root->print_perl_var_def($files);
			if ($copyExisting) {
				Carp::cluck($err);
				print LOG
				  "missing file $required_fn ($files->{$required_fn})\n";
			}
			else {
				Carp::confess($err);
			}
		}
	}
	else {
		$err =
"required filename $required_fn could not be found downsream of $dataPath ($available_fn)\n"
		  . "\$existing ="
		  . root->print_perl_var_def($available)
		  . "\n\$required="
		  . root->print_perl_var_def($files);
		if ($copyExisting) {
			Carp::cluck($err);
			print LOG "missing file $required_fn ($files->{$required_fn})\n";
		}
		else {
			Carp::confess($err);
		}
	}
}

if ($copyExisting) {
	close(LOG);
	print "Missing files would be stated in $outpath/../$ext." . $$
	  . "_create_GEO_submission.pl.log\n";
}

system( "rm -fR " . File::Spec->catpath( $outpath, 'tmp' ) );
