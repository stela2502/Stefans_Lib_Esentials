#! /usr/bin/perl -w

#  Copyright (C) 2016-05-16 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

=head1 XML_parser.pl

prettyplot xml and probably more.

To get further help use 'XML_parser.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use XML::Simple;
use FindBin;

use Data::Dumper;

use stefans_libs::XML_parser;

my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,    $debug,      $database, $infile, $outfile,
	@options, $data_table, $values,   @tmp
);

Getopt::Long::GetOptions(
	"-infile=s"     => \$infile,
	"-outfile=s"    => \$outfile,
	"-options=s{,}" => \@options,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

my $options;

#$options->{'ignore'} = ['SPOT_DESCRIPTOR'];
#$options->{'addMultiple'} = [ 'ID'];
if ( defined $options[0] ) {
	for ( my $i = 0 ; $i < @options ; $i += 2 ) {
		if ( $options[$i] eq "ignore" ) {
			$options->{ $options[$i] } ||= [];
			$options->{ $options[$i] } = [
				split(
					" ",
					$options[ $i + 1 ]
					  . join( " ", @{ $options->{ $options[$i] } } )
				)
			];
		}
		elsif ( $options[$i] eq 'addMultiple' ) {
			$options->{ $options[$i] } ||= [];
			$options->{ $options[$i] } = [
				split(
					" ",
					$options[ $i + 1 ]
					  . join( " ", @{ $options->{ $options[$i] } } )
				)
			];
		}
		else {
			$options->{ $options[$i] } = $options[ $i + 1 ];
		}
	}
}

if ( defined $options->{'NCBI_ID'} ) {
	unless ( -f $infile ) {
		print "I try to download the file from NCBI!\n";
		system( "wget -O  $infile "
			  . "'http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&db=sra&rettype=studyinfo&term=\"$options->{'NCBI_ID'}\"'"
		);
	}
	else {
		print "I use the existsing input file '$infile'\n";
	}
}

unless ( defined $infile ) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $options ) {
	$warn .= "the cmd line switch -options is undefined!\n";
}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for XML_parser.pl

   -infile    :the infile for the conversion
   -outfile   :the outfile base for the tables
   -options 
   		NCBI_ID 'some SRA ID'  
   		      :The information for this ID id is downloaded 
   		       from NCBI and stored in the input file
   		ignore 'table1 table2 table3'
   			  :is ignoring these tables 'SPOT_DESCRIPTOR'
   		addMultiple 'colname1 colname2 colname3'
   			  :there are multiple coumns of this type allowed per line
   		inspect 'string'
   			  :search for the 'string' in all columns and show the hash

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl ' . $plugin_path . '/XML_parser.pl';
$task_description .= " -infile $infile" if ( defined $infile );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -options '" . join( "' '", @options ) . "'"
  if ( defined $options[0] );

open( LOG, ">$outfile.log" ) or die $!;
print LOG $task_description . "\n";
close(LOG);

## Do whatever you want!
my $xml = XMLin($infile);

#print XMLout( $xml );

my $IDS = stefans_libs::XML_parser->new( { debug => $debug } );

$debug = 0;
my $main_id = 1;

print scalar( &parse( $xml, 'root' ) )
  . " entries analyzed.\n"
  . "Is the resulting table close to the required / wanted output?\n";

## now I expect to have multiple entries with an .<integer> ending. These should be sample specific and that is a problem!

$IDS->write_files( $outfile, 1 );

print "Done!\n";

sub parse {
	my ( $hash, $area, $entryID, $new_line ) = @_;
	$entryID  ||= 1;
	$new_line ||= 0;
	my ( $str, $keys, $delta, $tmp );
	foreach ( @{ $options->{'ignore'} } ) {
		return $delta if ( $area =~ m/$_/ );
	}
	$delta = 0;
	if ( ref($hash) eq "ARRAY" ) {
		foreach (@$hash) {
			$delta = &parse( $_, $area, $entryID, 1 );
			$entryID += $delta;
		}
	}
	elsif ( ref($hash) eq "HASH" ) {
		$str = lc( join( " ", sort keys %$hash ) );
		if ( defined $options->{'inspect'} ){
			$options->{'inspect'} = lc( $options->{'inspect'} );
			if ( join(" ", lc(values %$hash), $str) =~ m/$options->{'inspect'}/ ){
				print_and_die( $hash, "You have searched for the sring '$options->{'inspect'}':\n");
			}
		}
		#If it is some numers - ignore that
		if ( $str eq "count value" ) {
			return 0;    ## I skip the crap!
		}
		if ( $str eq "tag value" || $str eq "tag units value" ) {
			$keys = { map { lc($_) => $_ } keys %$hash };
			@tmp = split( "-", $area );
			pop(@tmp);
			$area = join( "-", @tmp );
			## Here I do not want to create a new entry!
			$delta = $IDS->add_if_empty( "$area-" . $hash->{ $keys->{'tag'} },
				$hash->{ $keys->{'value'} }, $entryID );
		}
		elsif ( $str =~ m/content/ and $str =~ m/namespace/ ) {
			$delta = $IDS->add_if_empty( $area . ".$hash->{'namespace'}",
				$hash->{'content'}, $entryID );
		}
		elsif ( $str eq 'refcenter refname' ) {
			$delta = $IDS->add_if_empty( $area . ".$hash->{'refcenter'}",
				$hash->{'refname'}, $entryID );
		}
		else {
			## If I have an accession or PRIMARY_ID entry I want to process that first!
			$tmp = 0;
			my $overall_delta = 0;
			foreach my $key (
				sort {
					my @a = split( "-", $a );
					my @b = split( "-", $b );
					lc( $a[$#a] ) cmp lc( $b[$#b] )
				} keys %$hash
			  )
			{
				print "$key  =>  $hash->{$key} on line $entryID\n" if ($debug and $tmp ++ == 0 );
				## this might need a new line, but that is not 100% sure!
				$str = 0;
				foreach ( @{ $options->{'addMultiple'} } ) {
					if ( $key =~ m/$_/ ) {
						$delta =
						  &parse( $hash->{$key}, "$area-$key", $entryID, 0 );
						$str = 1;
					}
				}
				if ( $str == 0 ) {
					$delta = &parse( $hash->{$key}, "$area-$key", $entryID, 1 );
				}
#				$overall_delta = $delta unless ( $delta == 0);
				( $entryID, $delta ) = __cleanup( $entryID, $delta );
				print "\t\tafterwards we are on line $entryID\n" if ( $tmp == 1 and $debug );
			}
			$delta = $overall_delta; ## I need to report back if I (ever) changed my entryID!!
		}
	}
	else {    ## some real data

#		return 0 if ( defined $values -> { $hash } ) ;
#		as the new column might come from a new hash, that might need merging to the last line - check that!
		foreach ( @{$options->{'addMultiple'}}) {
			if ( $area =~ m/$_/ ) {
				$delta = $IDS->register_column( $area, $hash, $entryID, 0 );
			}
		}
		if ( $area =~ m/accession$/ ) {
			$delta = $IDS->register_column( $area, $hash, $entryID, 1 );
		}
		elsif ( $hash =~ m/^\w\w\w\d+$/ ) {    ## an accession!
			$delta = $IDS->add_if_unequal( $area, $hash, $entryID );
		}
		else {
			$delta = $IDS->register_column( $area, $hash, $entryID, 1 );
		}
	}

	return
	  $delta
	  ;    ## we did add some data or respawned so if necessary update the id!
}

sub __cleanup {
	my ( $entryID, $delta ) = @_;
	$delta ||= 0;
	$delta = 1  if ( $delta > 1 );
	$delta = -1 if ( $delta < -1 );
	$entryID += $delta;
	return ( $entryID, $delta );
}

sub print_and_die {
	my $xml = shift;
	print Dumper($xml);
	Carp::confess(shift);
}

sub print_debug {
	my ( $hash, $area, $entryID, $new_line, $delta, $str ) = @_;
	$str ||= '';
	print
	  "$str final delta = $delta for $area, line =$entryID, and hash $hash\n"
	  if ($debug);
}

