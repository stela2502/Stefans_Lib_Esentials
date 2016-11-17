#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2016-11-01 Stefan Lang

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

=head1  SYNOPSIS

    create_a_data_table_based_file_interface_class.pl
       -name   :the name of the new data interface class - give me the full path!
   	   -pod    :the pod description of the interface

       -column_headers  :A list of column header the new interface should have - this will be enforced!
       
       -force  :overwrite if file exists


       -help           :print this help
       -debug          :verbose output

   
   
   
   -force :if you want to overwrite an old lib file use this option - DANGEROUS!!

   -help   :print this help
   -debug  :verbose output
   
   
=head1 DESCRIPTION

  Create a stefans_libs::data_table based file interface that is based on a known structure represented by a fixed colname set.

  To get further help use 'create_a_data_table_based_file_interface_class.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;
use stefans_libs::root;
use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $name, $test_folder, $pod, @column_headers, $force);

Getopt::Long::GetOptions(
	 "-name=s"    => \$name,
	 "-pod=s"    => \$pod,
       "-column_headers=s{,}"    => \@column_headers,
       "-force"    => \$force,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $name) {
	$error .= "the cmd line switch -name is undefined!\n";
}

unless ( defined $pod) {
	$error .= "the cmd line switch -pod is undefined!\n";
}
unless ( defined $column_headers[0]) {
	$error .= "the cmd line switch -column_headers is undefined!\n";
}
# force - no checks necessary


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

$task_description .= 'perl '.$plugin_path .'/create_a_data_table_based_file_interface_class.pl';
$task_description .= " -name '$name'" if (defined $name);
$task_description .= " -test_folder '$test_folder'" if (defined $test_folder);
$task_description .= " -pod '$pod'" if (defined $pod);
$task_description .= ' -column_headers "'.join( '" "', @column_headers ).'"' if ( defined $column_headers[0]);
$task_description .= " -force " if ( $force);

## Do whatever you want!


$name .= ".pm" unless ( $name =~ m/\.pm$/ );
if ( -f $name && ! defined $force ){
	warn "We will not overwrite the old file unless you use the -force option\n\n";
	exit -1;
}

## define the class name!
## I expect the important part to be downtream of a /lib/ folder!
my (@class_components, $important_part);
$important_part = 0;
my $path;
foreach ( split(/\//,$name)){
	if ( $_ eq "lib" ){
		$important_part = 1;
		next;
	}
	unless ( $important_part ){
		$path .= "$_/";
		next;
	}
	$_ =~s/\.pm$//;
	push ( @class_components, $_);
}
if (scalar(@class_components) == 0){
	die "Sorry, you need to give me a class name, that is downstream of a lib folder!\n".
		"Otherwise I will not be able to determine the right package name!\n";
}

my $class_string = join('::',@class_components);

my $owner = "Stefan Lang";

## Print the licence information
open ( OUT ,">$name") or die "I could not create the lib file '$name'\n$!\n";

print OUT "package $class_string;\n".
"
#  Copyright (C) ".root->Today()." $owner 

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

";

## use the data_table as base package!
print OUT "
use strict;
use warnings;

use stefans_libs::flexible_data_structures::data_table;
use base 'data_table';

=head1 General description

$pod

=cut
";

## print the sub 'new'
my ($header_hash_str, $header_array_str );
$header_hash_str = $header_array_str = '';
for ( my $i = 0; $i < @column_headers; $i ++ ){
	$header_hash_str .= "            '$column_headers[$i]' => $i,\n";
	$header_array_str .= "            '$column_headers[$i]',\n";
};
chop($header_hash_str);
chop ($header_array_str);

print OUT  'sub new {

    my ( $class, $debug ) = @_;
    my ($self);
    $self = {
        \'debug\'           => $debug,
        \'arraySorter\'     => arraySorter->new(),
        \'header_position\' => { 
'.$header_hash_str.'
        },
        \'default_value\'   => [],
        \'header\'          => [
'.$header_array_str.
'       ],
        \'data\'            => [],
        \'index\'           => {},
        \'last_warning\'    => \'\',
        \'subsets\'         => {}
    };
    bless $self, $class if ( $class eq "'.$class_string.'" );

    return $self;
}

';

## print the modified Add_2_Header function, that will take care, that the file structure is enforced
print OUT '
## two function you can use to modify the reading of the data.

sub pre_process_array{
	my ( $self, $data ) = @_;
	##you could remove some header entries, that are not really tagged as such...
	return 1;
}

sub After_Data_read {
	my ($self) = @_;
	return 1;
}


';

print OUT '
sub Add_2_Header {
    my ( $self, $value ) = @_;
    return undef unless ( defined $value );
    unless ( defined $self->{\'header_position\'}->{$value} ) {
        Carp::confess( "You try to change the table structure - That is not allowed!\n".
            "If you really want to change the data please use ".
            "the original data_table class to modify the table structure!\n"
        ) ;
    }
    return $self->{\'header_position\'}->{$value};
}

';

## print the end

print OUT "\n\n1;\n";

close ( OUT );
print "created the lib file '$name'\n";
$test_folder = "$path/t/";

if ( defined $test_folder ){
	my $test_file = $test_folder."/".join("_",@class_components).".t";
	unless ( -f $test_file ){
		open ( OUT ,">$test_file") or die "I could not create the test file '$test_file'\n$!\n";
		print OUT &test_file_string( \@class_components, $header_hash_str );
		close ( OUT );
		print "we craeted the test script '$test_file'\n";
	}
	elsif ( !defined $force) {
		die "Sorry - you will have a problem in this lib, as you have the same lib file twice!!\n";
	}
	elsif ( $force ){
		open ( OUT ,">$test_file") or die "I could not create the test file '$test_file'\n$!\n";
		print OUT &test_file_string( \@class_components,  $header_hash_str);
		close ( OUT );
		print "we craeted the test script '$test_file'\n";
	}
	print "you should be able to find the test file $test_file\n";
}

sub test_file_string{
	my ( $class_components, $header_hash_str ) = @_;
	Carp::confess ( "Clean up your script - I need an class information string!\n")
		unless ( ref($class_components) eq "ARRAY" );
	my $additional_test = '';
	if ( defined $header_hash_str){
		$additional_test = '$value = $test_object->AddDataset ( { '.$header_hash_str.' } );
is_deeply( $value, 1, "we could add a sample dataset");'
	}
	return "#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok '".join("::",@$class_components)."' }

my (\$test_object, \$value, \$exp, \@values);
\$test_object = ".join("::",@$class_components)." -> new();
is_deeply ( ref(\$test_object) , '".join("::",@$class_components)."', 'simple test of function ".join("::",@$class_components)." -> new()' );

$additional_test

## A handy help if you do not know what you should expect
#print \"\\\$exp = \".root->print_perl_var_def(\$value ).\";\\n\";\n";
}


