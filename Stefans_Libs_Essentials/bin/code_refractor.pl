#! /usr/bin/perl -w

#  Copyright (C) 2011-09-16 Stefan Lang

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

=head1 code_refractor.pl

This tool can be used to convert single lines in a whole file structure into other lines. Especially usefull for changing a huge set of perl lib files.

To get further help use 'code_refractor.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::root;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $path, $match, $line_select, $replace );

Getopt::Long::GetOptions(
    "-path=s"          => \$path,
    "-line_selector=s" => \$line_select,
    "-match=s"         => \$match,
    "-replace=s"       => \$replace,

    "-help"  => \$help,
    "-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $path ) {
    $error .= "the cmd line switch -path is undefined!\n";
}
unless ( defined $match ) {
    $error .= "the cmd line switch -match is undefined!\n";
}
unless ( defined $replace ) {
    $error .= "the cmd line switch -replace is undefined!\n";
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
 command line switches for code_refractor.pl

   -path          :the path I should start
   -line_selector :a match statement, that can be used to select the 
                   lines where replacement should be done
   -match         :the match, that should be replaced
   -replace       :the replacement string

   -help      :print this help
   -debug     :verbose output
   

";
}

my ($task_description);

$match =~ s/\$/./g;
$match =~ s/"/./g;
$match =~ s/'/./g;

$task_description .=
  'perl ' . root->perl_include() . ' ' . $plugin_path . '/code_refractor.pl';
$task_description .= " -path $path"       if ( defined $path );
$task_description .= " -match '$line_select'"     if ( defined $line_select );
$task_description .= " -match '$match'"     if ( defined $match );
$task_description .= " -replace '$replace'" if ( defined $replace );

print "we do this:\n$task_description\n";

&work_on_path($path);

sub work_on_path_with_preselect {
    my ($path) = @_;
    opendir( Pair_PATH, $path )
      or die "I could not read from path '$path'\n$!\n";
    my @eintraege = readdir(Pair_PATH);
    closedir(Pair_PATH);
    my ( $eintrag, @file, $line, $modified );
    foreach my $eintrag (@eintraege) {
        next if ( $eintrag =~ m/^\./ );
        if ( -d "$path/$eintrag" ) {
            &work_on_path_with_preselect("$path/$eintrag");
        }
        else {
            open( IN_FILE, "<$path/$eintrag" )
              or die "I could not open the file '$path/$eintrag'\n$!\n";
            print "we work ion file '$path/$eintrag'\n" if ( $debug);
            @file = <IN_FILE>;
            close(IN_FILE);
            $modified = 0;
            foreach $line (@file) {
                if ( $line =~ m/$line_select/ ) {
                    $modified = 1;
                    $line =~ s/$match/$replace/g;
                    print "we have found a match!\n";
                }
                if ( $line =~ m/"DBI::db"/ ) {
                    print "we goot the line $line\n";
                }
            }

            if ($modified) {
                open( OUT, ">$path/$eintrag" )
                  or die "I could not write to the file '$path/$eintrag'\n$!\n";
                print OUT join( '', @file );
                close(OUT);
                print "Modified file '$path/$eintrag'\n";
            }
        }
    }
}

sub work_on_path {
    my ($path) = @_;
    if ( defined $line_select ){
	    return &work_on_path_with_preselect($path);
    }
    opendir( Pair_PATH, $path )
      or die "I could not read from path '$path'\n$!\n";
    my @eintraege = readdir(Pair_PATH);
    closedir(Pair_PATH);
    my ( $eintrag, @file, $line, $modified );
    foreach my $eintrag (@eintraege) {
        next if ( $eintrag =~ m/^\./ );
        if ( -d "$path/$eintrag" ) {
            &work_on_path("$path/$eintrag");
        }
        else {
            open( IN_FILE, "<$path/$eintrag" )
              or die "I could not open the file '$path/$eintrag'\n$!\n";
            @file = <IN_FILE>;
            close(IN_FILE);
            $modified = 0;
            foreach $line (@file) {
                if ( $line =~ m/$match/ ) {
                    $modified = 1;
                    $line =~ s/$match/$replace/g;
                    print "we have found a match!\n";
                }
                if ( $line =~ m/"DBI::db"/ ) {
                    print "we goot the line $line\n";
                }
            }

            if ($modified) {
                open( OUT, ">$path/$eintrag" )
                  or die "I could not write to the file '$path/$eintrag'\n$!\n";
                print OUT join( '', @file );
                close(OUT);
                print "Modified file '$path/$eintrag'\n";
            }
        }
    }
}

