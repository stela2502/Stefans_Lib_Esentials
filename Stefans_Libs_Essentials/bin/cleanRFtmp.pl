#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2018-10-08 Stefan Lang

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
   
   binCreate.pl from git@github.com:stela2502/Stefans_Lib_Esentials.git commit c35cfea822cac3435c5821897ec3976372a89673
   

=head1  SYNOPSIS

    cleanRFtmp.pl
       -startFolder       :a project folder that cointains RF tmp files/folder structures


       -help           :print this help
       -debug          :do not remove but state only
   
=head1 DESCRIPTION

  cleans the BioData RFcluster tmp folders.

  To get further help use 'cleanRFtmp.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;
use File::Spec;
use File::Basename;

use stefans_libs::root;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $startFolder);

Getopt::Long::GetOptions(
	 "-startFolder=s"    => \$startFolder,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $startFolder) {
	$error .= "the cmd line switch -startFolder is undefined!\n";
}


if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
	print "$errorMessage.\n";
	pod2usage(q(-verbose) => 1);
}



my ( $task_description);

$task_description .= 'perl '.$plugin_path .'/cleanRFtmp.pl';
$task_description .= " -startFolder '$startFolder'" if (defined $startFolder);


## Do whatever you want!

&checkPath( $startFolder );



sub checkPath {
	my $path = shift;
	my (@tmp, @files, $remaining, $subdir_rem, $file, $ext) ;
	opendir ( my $p , "$path" ) or die $!;
	@files = readdir( $p );
	closedir($p);
	$remaining = 0;
	my $remove = { map {$_ => 1} 'err', 'out', 'Rout', 'R', 'RData', 'sh', 'lock'  };
	
	#print "\$exp = " . root->print_perl_var_def( $remove) . ";\n";
	
	foreach $file ( @files ){
		next if ( $file=~m/^\./);
		if ( -d File::Spec->catfile( $path, $file ) ) {
			$file = File::Spec->catfile( $path, $file );
			$remaining += $subdir_rem = &checkPath ( $file );
			unless ( $subdir_rem) {
				rmdir( $file ) or warn "Could not rmdir $file: $!" unless $debug;
			}
		}elsif ($file=~m/^runRFclust_/) {
			@tmp = split( /\./, $file);
			$ext = pop(@tmp);
			#print "$file has ext '$ext'\n";
			if ( $remove->{$ext}) {
				#warn "I should delete this file $file\n";
				$file = File::Spec->catfile( $path, $file );
				unless($debug) {
					print "removing file".$file ."\n";
					unlink  $file or warn "Could not unlink $file: $!";
				}
			}else {
				print "keeping file $file\n" if ( $debug);
				$remaining ++;
			}
		}
		else {
			print "keeping file $file\n" if ( $debug);
			$remaining ++;
		}
	}
	unless ( $remaining ) {
		if ( -f File::Spec->catfile( $path, '.RData' ) ) {
			$file = File::Spec->catfile( $path, '.RData' ); 
			unless ( $debug ){
				unlink  $file or warn "Could not unlink $file: $!";
			}
		}
	}
	warn "path $path had $remaining remaining files\n";
	return $remaining;
}




