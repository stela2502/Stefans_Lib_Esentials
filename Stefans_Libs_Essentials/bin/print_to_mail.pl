#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2017-06-20 Stefan Lang

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

    print_to_mail.pl
       -file  :the file you want to print (no type check performed!)
       -color :use color or default = grayscale


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Use print to email functionallity with thunderbird

  To get further help use 'print_to_mail.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use File::HomeDir qw(home);
use File::Spec::Functions qw(catfile);

use stefans_libs::flexible_data_structures::data_table;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $file, $color );

Getopt::Long::GetOptions(
	"-file=s" => \$file,
	"-color"  => \$color,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $file ) {
	$error .= "the cmd line switch -file is undefined!\n";
}

# color - no checks necessary

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

$task_description .= 'perl ' . $plugin_path . '/print_to_mail.pl';
$task_description .= " -file '$file'" if ( defined $file );
$task_description .= " -color " if ($color);

my $cnf = &read_cnf();
#thunderbird -compose "to=printmono@med.lu.se,from=Stefan.Lang@med.lu.se,subject=ignore that,
#attachment='file:///home/med-sal/git_Projects/SCexV/SCExV/root/tmp/727a435e37044e0f9eecfbac11ed8943961d4894/PCR_Heatmap_grayscale.pdf'"

## I try to use the unix printing system to get the pdf if its not already a pdf or jpg
my $fm = root->filemap( $file );
my $OK = { map { $_ => 1} 'jpg', 'pdf' };
if ( !$OK->{$fm->{'ext'}}) {
	system( "lpr -PPDF $fm->{'total'}");
	$fm =root->filemap( home() ."/PDF/$fm->{'filename_core'}.pdf");
}

my $cmd = "thunderbird -compose \"to=";
if ( $color ){
	$cmd .=$cnf->{color};
}else {
	$cmd .=$cnf->{monochrome};
}
$cmd .=",from=$cnf->{'from'},subject=$cnf->{'subject'},attachment='file://".$fm->{'total'}.'\'"';
if ($debug){
	print $cmd."\n";
}else {
	system ( $cmd );
}

sub read_cnf {
	my $err = 0;
	my $cnf_file =  catfile( home(), ".print_to_mail.conf" );
	if ( -f $cnf_file ) {
		open( IN, "<" . $cnf_file )
		  or die "I could not open the config file '"
		  . $cnf_file
		  . "\n$!\n";
		my @tmp;
		while ( <IN> ) {
			chomp; 
			@tmp = split( "\t", $_ ); 
			$cnf->{$tmp[0]} = $tmp[1];
		}
		close(IN);
		foreach (qw(color monochrome from subject)) {
			unless ( $cnf->{$_} ) {
				$err = 1;
			}
			if ( $cnf->{$_} =~m/,/) {
				warn "configuration $_ must not contain a comma\n";
				$err = 1;
			}
		}
	}
	else {
		$err = 1;
	}
	if ($err) {
		open ( OUT , ">" . $cnf_file ) or die "I could not create the conf file '$cnf_file'\n$!\n";
		foreach ( qw(color monochrome from subject) ) {
			print OUT "$_\tplease add the email/value here!\n";
		}
		close ( OUT );
		die "Sorry - I could not do the task\nplease configure this tool first.\nfill in ".catfile( home(), ".print_to_mail.conf" )."\n";
	}
	return $cnf;
}
