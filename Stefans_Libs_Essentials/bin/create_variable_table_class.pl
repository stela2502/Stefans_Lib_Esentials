#! /usr/bin/perl -w

#  Copyright (C) 2008 Stefan Lang

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
package create_hashes_from_mysql_create;

=head1 create_hashes_from_mysql_create.pl

A small tool that reads perl lib files, searches for the $createString and converts that into an hash with the table definition.


To get further help use 'create_hashes_from_mysql_create.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::root;
use stefans_libs::database::variable_table;
use base "variable_table";

my ( $help, $debug, $inpath, $outfile, @include_strings, @links, $owner );

Getopt::Long::GetOptions(
	"-mysql_create_String=s"  => \$inpath,
	"-new_class_file=s"       => \$outfile,
	"-my_name=s"              => \$owner,
	"-include_strings=s{,}"   => \@include_strings,
	'-variables_link_to=s{,}' => \@links,
	"-help"                   => \$help,
	"-debug"                  => \$debug
);

my ( $error, $warning );
$error = $warning = '';

unless ( defined $inpath ) {
	$error .= "we need an mysql create string!";
}
unless ( defined $outfile ) {
	$warning .=
"we could create a whole new database class if you wish (new_class_file)\n";
	$outfile = '';
}
unless ( defined $owner ) {
	$warning .=
"If you are not Stefan Lang, you want to set the 'my_name' option to your name\n"
	  . " to include your name in the copyright of this class.\n";
	$owner = "Stefan Lang";
}

warn $warning if ( $warning =~ m/\w/ );
if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

if ($help) {
	print helpString();
	exit;
}

my $self = {};
bless $self, 'create_hashes_from_mysql_create';

$inpath =~ s/\$/\\\$/g;
my @string = split( /[\n]/, $inpath );

my ( $hash, $temp, $names, @temp );
$hash->{'variables'} = [];
$hash->{'INDICES'}   = [];
$hash->{'UNIQUES'}   = [];

my ($package, @test_path);
$outfile =~ s/\.pm$//;
$package = $outfile;
my ( @package, $use );
$use = 0;
print "we got the package $package\n";
if ( $package =~ m/\// ) {
	foreach ( split("/",$package) ) {
		print "we check the part $_\n";
		if ( $_ eq "lib" ) {
			$use = 1;
			next;
		}
		if ( $use == 1 ) {
			print "and this part is important!\n";
			push( @package, $_ );
		}
		else {
			push( @test_path, $_ );
		}
	}
	if ( scalar(@package) == 0 ) {
		foreach ( $package =~ m/.*\/(.*)/ ) {
			push( @package, $1 );
		}
	}
	$package = join( "::", @package );
}
push( @test_path, 't' );
print "We created the test file '". &createTestFile (join("/", @test_path), $package, join("_", split("::", $package)))."'\n";
my $uniques;
my $other_includes = '';
foreach (@include_strings) {
	$other_includes .= "use $_;\n";
}
my $links_to_hash = {};
foreach (@links) {
	@temp = split( ";", $_ );
	unless ( scalar(@temp) >= 2 ) {
		die
"Sorry, but a value for the option variables_link_to needs to have at least two ';'-separated enries\n$_\n";
	}
	$temp[2] = '' unless ( defined $temp[2] );
	$links_to_hash->{ $temp[0] } =
	  { 'obj_name' => $temp[1], 'links_to' => $temp[2] };
}

my $file_content = "package $package;\n" . '

#  Copyright (C) 2010 ' . $owner . '

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

use stefans_libs::database::variable_table;
use base variable_table;

' . $other_includes . '
##use some_other_table_class;

use strict;
use warnings;


sub new {

    my ( $class, $dbh, $debug ) = @_;
    
    Carp::confess ("$class : new -> we need a acitve database handle at startup!, not "
	  . ref($dbh))
	  unless ( ref($dbh) =~ m/::db$/ );

    my ($self);

    $self = {
        debug => $debug,
        dbh   => $dbh
    };

    bless $self, $class if ( $class eq "' . $package . '" );
    $self->init_tableStructure();

    return $self;

}

sub  init_tableStructure {
     my ($self, $dataset) = @_;
     my $hash;
     $hash->{\'INDICES\'}   = [];
     $hash->{\'UNIQUES\'}   = [];
     $hash->{\'variables\'} = [];
';

foreach my $variable_line (@string) {
	if ( $variable_line =~ m/id .* auto_increment/ ) {
		$hash->{'primary_key'} = 'id';
		next;
	}
	$variable_line =~ s/[dD]efault/DEFAULT/;
	$variable_line =~ s/[Vv]archar/VARCHAR /;
	$variable_line =~ s/[Ff]loat/FLOAT/;
	$variable_line =~ s/[Nn][Oo][Tt] [Nn][Uu][Ll][Ll]/NOT NULL/;
	$variable_line =~ s/[Cc]har/CHAR /;
	$variable_line =~ s/[Tt]inyint/TINYINT/;
	$variable_line =~
	  s/[Ii][Nn][Tt][Ee]?[Gg]?[Ee]?[rR]? unsigned/INTEGER UNSIGNED/;
	$variable_line =~ s/[Uu]nique/UNIQUE/;
	$variable_line =~
	  s/[Cc][Rr][Ee][Aa][Tt][Ee] +[Tt][Aa][Bb][Ll][Ee]/CREATE TABLE/;
	$variable_line =~ s/[Ll]ongtext/LONGTEXT/;
	$variable_line =~ s/[Bb][Oo][oO][Ll] /BOOLEAN/;

	next if ( $variable_line =~ m/PRIMARY KEY/ );
	if ( $variable_line =~ m/ *CREATE TABLE *(\\?[\$\w]+) *\(/ ) {
		$hash->{'table_name'} = $1;
		$file_content .=
		  "     \$hash->{'table_name'} = \"$hash->{'table_name'}\";\n";
		next;
	}
	if ( $variable_line =~ m/ *([\w_]+) *VARCHAR *\( *(\d+) *\)/ ) {
		my $val = { 'name' => $1, 'type' => "VARCHAR ($2)" };
		$names->{ $val->{'name'} } = 1;
		&handle_Variable_line( $val, $variable_line );
		next;
	}
	if ( $variable_line =~ m/ *([\w_]+) INTEGER UNSIGNED/ ) {
		my $val = { 'name' => $1, 'type' => "INTEGER UNSIGNED" };
		$names->{ $val->{'name'} } = 1;
		&handle_Variable_line( $val, $variable_line );

		next;
	}
	if ( $variable_line =~ m/ *([\w_]+) INTEGER/ ) {
		my $val = { 'name' => $1, 'type' => "INTEGER" };
		$names->{ $val->{'name'} } = 1;
		&handle_Variable_line( $val, $variable_line );

		next;
	}
	if ( $variable_line =~ m/ *([\w_]+) TIMESTAMP/ ) {
		my $val = { 'name' => $1, 'type' => "TIMESTAMP" };
		$names->{ $val->{'name'} } = 1;
		&handle_Variable_line( $val, $variable_line );
		next;
	}
	if ( $variable_line =~ m/ *([\w_]+) FLOAT/ ) {
		my $val = { 'name' => $1, 'type' => "FLOAT" };
		$names->{ $val->{'name'} } = 1;
		&handle_Variable_line( $val, $variable_line );
		next;
	}
	if ( $variable_line =~ m/ *([\w_]+) TEXT/ ) {
		my $val = { 'name' => $1, 'type' => "TEXT" };
		$names->{ $val->{'name'} } = 1;
		&handle_Variable_line( $val, $variable_line );
		next;
	}
	if ( $variable_line =~ m/ *([\w_]+) DATE/ ) {
		my $val = { 'name' => $1, 'type' => "DATE" };
		$names->{ $val->{'name'} } = 1;
		&handle_Variable_line( $val, $variable_line );
		next;
	}
	if ( $variable_line =~ m/ *([\w_]+) CHAR *\( *(\d+) *\)/ ) {
		my $val = { 'name' => $1, 'type' => "CHAR ($2)" };
		$names->{ $val->{'name'} } = 1;
		&handle_Variable_line( $val, $variable_line );
		next;
	}
	if ( $variable_line =~ m/ *([\w_]+) *TINYINT/ ) {
		my $val = { 'name' => $1, 'type' => "TINYINT" };
		$names->{ $val->{'name'} } = 1;
		&handle_Variable_line( $val, $variable_line );
		next;
	}
	if ( $variable_line =~ m/ *([\w_]+) *BOOLEAN/ ) {
		my $val = { 'name' => $1, 'type' => "BOOLEAN" };
		$names->{ $val->{'name'} } = 1;
		&handle_Variable_line( $val, $variable_line );
		next;
	}
	if ( $variable_line =~ m/ *([\w_]+) *LONGTEXT/ ) {
		my $val = { 'name' => $1, 'type' => "LONGTEXT" };
		$names->{ $val->{'name'} } = 1;
		&handle_Variable_line( $val, $variable_line );
		next;
	}
	if ( $variable_line =~ m/ *INDEX .*\( ?([\w ]+) ?\)/ ) {
		my $val = [ split( " ", $1 ) ];
		push( @{ $hash->{'INDICES'} }, $val );
		$file_content .=
		    "     push ( \@{\$hash->{'INDICES'}}, [ '"
		  . join( "', ", @$val )
		  . "' ] ) ;\n";
		next;
	}
	if ( $variable_line =~ m/ *UNIQUE *\( ?([\w, ]+) ?\)/ ) {
		$temp = $1;
		while ( $temp =~ m/ +$/ ) {
			chop($temp);
		}
		my $val = [ split( ", +", $temp ) ];
		push( @{ $hash->{'UNIQUES'} }, $val );
		$uniques = "'" . join( "', '", @$val ) . "'";
		$file_content .=
		  "     push ( \@{\$hash->{'UNIQUES'}}, [ $uniques ]);\n";
		next;
	}
	if ( $variable_line =~ m/ *\)/ ) {
		if ( $variable_line =~ m/ENGINE=(\w+)/ ) {
			$hash->{'ENGINE'} = $1;
			$file_content .= "     \$hash->{'ENGINE'} = '$hash->{'ENGINE'}';\n";
		}
		if ( $variable_line =~ m/DEFAULT CHARSET=([\w\d]+)/ ) {
			$hash->{'CHARACTER_SET'} = $1;
			$file_content .=
			  "     \$hash->{'CHARACTER_SET'} = '$hash->{'CHARACTER_SET'}';\n";
		}
		next;
	}
	unless ( $variable_line =~ m/\w/ ) {
		next;
	}
	die "sorry, but we could not parse the string '$variable_line'\n";
}

$file_content .= '
     $self->{\'table_definition\'} = $hash;
     $self->{\'UNIQUE_KEY\'} = [ ' . $uniques . ' ];
	
';

$file_content .= "     \$self->{'table_definition'} = \$hash;\n\n";
$file_content .=
"     \$self->{'Group_to_MD5_hash'} = [ ]; # define which values should be grouped to get the 'md5_sum' entry\n"
  if ( defined $names->{'md5_sum'} );
$file_content .=
"     \$self->{'_tableName'} = \$hash->{'table_name'}  if ( defined  \$hash->{'table_name'} ); # that is helpful, if you want to use this class without any variable tables\n";
$file_content .= "\n";
$file_content .=
"     ##now we need to check if the table already exists. remove that for the variable tables!
     unless ( \$self->tableExists( \$self->TableName() ) ) {
     	\$self->create();
     }\n";
$file_content .=
"     ## Table classes, that are linked to this class have to be added as 'data_handler',
     ## both in the variable definition and here to the 'data_handler' hash.
     ## take care, that you use the same key for both entries, that the right data_handler can be identified.
";

foreach my $val ( keys %$links_to_hash ) {
	$file_content .=
"     \$self->{'data_handler'}->{'$links_to_hash->{$val}->{'obj_name'}'} = "
	  . "$links_to_hash->{$val}->{'obj_name'}->new(\$self->{'dbh'}, \$self->{'debug'});\n";
}

$file_content .=
  "     #\$self->{'data_handler'}->{''} = some_other_table_class->new( );\n";
$file_content .= "     return \$dataset;\n";
$file_content .= "}\n\n\n

#sub DO_ADDITIONAL_DATASET_CHECKS {
#	my ( \$self, \$dataset ) = \@_;
#
#	\$self->{'error'} .= ref(\$self) . \"::DO_ADDITIONAL_DATASET_CHECKS \\n\"
#	  unless (1);
#
#	return 0 if ( \$self->{'error'} =~ m/\\w/ );
#	return 1;
#}
#
#sub INSERT_INTO_DOWNSTREAM_TABLES {
#	my ( \$self, \$dataset ) = \@_;
#	$self->{'error'} .= '';
#	return 1;
#}
#
#sub post_INSERT_INTO_DOWNSTREAM_TABLES {
#	my ( \$self, \$id, \$dataset ) = \@_;
#	\$self->{'error'} .= '';
#	return 1;
#}
#
#sub CHECK_BEFORE_UPDATE{
#	my ( \$self, \$dataset ) = \@_;
#
#	\$self->{'error'} .= ref(\$self) . \"::DO_ADDITIONAL_DATASET_CHECKS \\n\"
#	  unless (1);
#
#	return 0 if ( \$self->{'error'} =~ m/\\w/ );
#	return 1;
#}


sub expected_dbh_type {
	return 'dbh';
	#return 'database_name';
}


1;\n";

if ( $outfile =~ m/\w/ ) {
	open( OUT, ">$outfile.pm" )
	  or die
"could not create class file '$outfile.pm'\nplease store the string wherever you want:\n$file_content\n";
	print OUT $file_content;
	close(OUT);
	print "Package information written to $outfile\n";
}
else {
	print
	  "please store the class information wherever you want:\n$file_content\n";
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for create_hashes_from_mysql_create.pl
 
   -mysql_create_String :the create statement that should be converted into a hash
   -my_name             :your name or the name of the copyright owner of the created class
   -new_class_file      :the filename for the new class file
   -include_strings     :the perl include strings to set up the connections
   -variables_link_to   :strings formated like '<variable name>;<perl class name>[;<other column name>]'
   
   -help           :print this help
   -debug          :verbose output


";
}

sub handle_Variable_line {
	my ( $val, $variable_line ) = @_;
	&add_NULL_info( $val, $variable_line );
	&add_DEFAULT_info( $val, $variable_line );
	push( @{ $hash->{'variables'} }, $val );
	&printValue_createHASH($val);
	return 1;
}

sub add_NULL_info {
	my ( $hash, $variable_line ) = @_;

	if ( $variable_line =~ m/NOT NULL/ ) {
		$hash->{'NULL'} = 0;
	}
	else {
		$hash->{'NULL'} = 1;
	}
	return 1;
}

sub add_DEFAULT_info {
	my ( $hash, $variable_line ) = @_;

	if ( $variable_line =~ m/DEFAULT (.+) / ) {
		$hash->{'DEFAULT'} = $1;
	}
	return 1;
}

sub printValue_createHASH {
	my ($val) = @_;
	$file_content .=
	    "     push ( \@{\$hash->{'variables'}}, " . " {\n"
	  . "               'name'         => '$val->{'name'}',\n"
	  . "               'type'         => '$val->{'type'}',\n"
	  . "               'NULL'         => '$val->{'NULL'}',\n"
	  . "               'description'  => '',\n";
	if ( defined $links_to_hash->{ $val->{'name'} } ) {
		$file_content .=
"               'data_handler' => '$links_to_hash->{$val->{'name'}}->{'obj_name'}',\n";
		$file_content .=
"               'link_to'      => '$links_to_hash->{$val->{'name'}}->{'links_to'}',\n"
		  if ( $links_to_hash->{ $val->{'name'} }->{'links_to'} =~ m/\w/ );
	}
	$file_content .= "          }\n     );\n";
}


sub createTestFile {
	my ( $testPath, $includeStr, $package ) = @_;

	if ( -f "$testPath/$package.t" ) {
		print "test file is already present ($testPath/$package.t)\n";
		return "$testPath/$package.t";
	}
	open( Test, ">$testPath/$package.t" )
	  or die "could not open testFile $testPath/$package.t\n";

	## we have to create a stup for each sub in the INFILE!
	print Test "#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok '$includeStr' }

my ( \$value, \@values, \$exp );
my \$obj = $includeStr -> new();
is_deeply ( ref(\$obj) , '$includeStr', 'simple test of function $includeStr -> new()' );

#print \"\\\$exp = \".root->print_perl_var_def(\$value ).\";\\n\";
\n\n";

	close(OUT);
	return "$testPath/$package.t";
}

