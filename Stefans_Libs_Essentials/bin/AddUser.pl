#! /usr/bin/perl

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

=head1 AddUser.pl

Use this script to initially set up the database

To get further help use 'AddUser.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::root;
use XML::Simple;
use stefans_libs::database::userTable;
use FindBin;
use Digest::MD5 qw(md5_hex);


use strict;
use warnings;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,            $debug,              $database,
	$db_user,                
	$db_driver,          $db_pw,
	$db_host,         $db_port,            $db_name,
	$user_name,      $user_pw,           $user_e_mail,
	$user_username,  $user_workgroup,    $user_position,
	$db_config_file,
);

Getopt::Long::GetOptions(
    "-db_config_file=s"            => \$db_config_file,
	"-db_user=s"                   => \$db_user,
	"-db_pw=s"                     => \$db_pw,
	"-db_host=s"                   => \$db_host,
	"-db_driver=s"                 => \$db_driver,
	"-db_port=s"                   => \$db_port,
	"-db_name=s"                   => \$db_name,
	"-user_name=s"                => \$user_name,
	"-user_pw=s"                  => \$user_pw,
	"-user_e_mail=s"              => \$user_e_mail,
	"-user_username=s"            => \$user_username,
	"-user_workgroup=s"           => \$user_workgroup,
	"-user_position=s"            => \$user_position,
	"-help"                        => \$help,
	"-debug"                       => \$debug
);

my $warn       = '';
my $error      = '';
my $user_in_db = 0;
my $root       = root->new();
$db_config_file = '' unless ( defined  $db_config_file);
if ( -f $db_config_file ) {
     $ENV{DBFILE} = $db_config_file;
}
unless ( -f variable_table->__dbh_file() ) {
	## we need to create the database connection information!
	 warn "I could not access the dbh file (variable_table->__dbh_file()).\n";
	unless ( defined $db_user ) {
		$error .= "the cmd line switch -db_user is undefined!\n";
	}
	unless ( defined $db_pw ) {
		$error .= "the cmd line switch -db_pw is undefined!\n";
	}
	unless ( defined $db_host ) {
		$error .= "the cmd line switch -db_host is undefined!\n";
	}
	unless ( defined $db_port ) {
		$error .= "the cmd line switch -db_port is undefined!\n";
	}
	unless ( defined $db_name ) {
		$error .= "the cmd line switch -db_name is undefined!\n";
	}

	unless ( defined $db_driver ) {
		$error .= "the cmd line switch -db_driver is undefined!\n";
	}
}

else {
	my $ACL = stefans_libs::database::userTable->new();
	unless ( defined $user_username ) {
		$error .= "the cmd line switch -user_username is undefined!\n";
	}
	unless (
		defined $ACL->get_data_table_4_search(
			{
				'search_columns' => [ ref($ACL) . ".*" ],
				'where'          => [ [ 'username', '=', 'my_value' ] ]
			},
			$user_username
		)->get_line_asHash(0)
	  )
	{

		unless ( defined $user_name ) {
			$error .= "the cmd line switch -user_name is undefined!\n";
		}
		unless ( defined $user_pw ) {
			$error .= "the cmd line switch -user_pw is undefined!\n";
		}
		unless ( defined $user_e_mail ) {
			$error .= "the cmd line switch -user_e_mail is undefined!\n";
		}

		unless ( defined $user_workgroup ) {
			$error .= "the cmd line switch -user_workgroup is undefined!\n";
		}
		unless ( defined $user_position ) {
			$error .= "the cmd line switch -user_position is undefined!\n";
		}
	}
	else {
		$user_in_db = 1;
	}
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
	my $ret = "
 $errorMessage
 command line switches for AddUser.pl\n";
 
	unless ( -f variable_table->__dbh_file() ){
		$ret  .= "
   -db_user       :the database user
   -db_pw         :the password for the database user
   -db_host       :the database host
   -db_port       :the database port
   -db_driver     :the driver to use (either mysql or db2)
   -db_name       :the database name to use
   
  or as an alternative
   -db_config_file :the db_config file you want me to use\n\n";
	}
	$ret .="
   -user_name       :the 'real' name of the first genexpress web user
   -user_pw         :the password for the user
   -user_e_mail     :the email of the user (used for problem reports etc.)
   -user_username   :the UNIQUE username of the new user
   -user_workgroup  :the workgroup the user is working in
   -user_position   :the position the user has

   -help           :print this help
   -debug          :verbose output
";
	return $ret;
}

## now we set up the logging functions....

my ($task_description);

## and add a working entry

$task_description .= 'AddUser.pl';
$task_description .= " -db_user $db_user" if ( defined $db_user );
$task_description .= " -db_driver $db_driver" if ( defined $db_driver );
$task_description .= " -db_pw $db_pw" if ( defined $db_pw );
$task_description .= " -db_host $db_host" if ( defined $db_host );
$task_description .= " -db_port $db_port" if ( defined $db_port );
$task_description .= " -db_name $db_name" if ( defined $db_name );
$task_description .= " -user_name $user_name" if ( defined $user_name );
$task_description .= " -user_pw $user_pw"     if ( defined $user_pw );
$task_description .= " -user_e_mail $user_e_mail"
  if ( defined $user_e_mail );
$task_description .= " -user_username $user_username"
  if ( defined $user_username );
$task_description .= " -user_workgroup $user_workgroup"
  if ( defined $user_workgroup );
$task_description .= " -user_position $user_position"
  if ( defined $user_position );

unless ( -f variable_table->__dbh_file() ) {
	my @temp = split ( "/", variable_table->__dbh_file() );
	pop ( @temp );
	&createPath ( join("/", @temp));
	
	## ok now we create a nice looking DBH file from scratch....
	my $hash = {
		'database' => {
			'connections' => [
				{
					'driver' => $db_driver,
					'host'   => 'localhost',
					'dbuser' => $db_user,
					'dbPW'   => $db_pw,
					'port'   => $db_port
				}
			],
			'database_names'     => [ $db_name,          $db_name . '_test' ],
			'default_connection' => { 'localhost' => 0 },
			'test_connection'    => { 'localhost' => 0 },

			'default_db_name' => { 'localhost' => 0 },
			'test_db_name'    => { 'localhost' => 1 }
		}
	};
	my $XML_interface =
	  XML::Simple->new( ForceArray => ['CONFLICTS_WITH'], AttrIndent => 1 );
	my $file_str = $XML_interface->XMLout($hash);
	open( OUT, ">" . variable_table->__dbh_file() )
	  or die
"I could not create the database_definition file that would look like that:\n$file_str\n"
	  . variable_table->__dbh_file() . "\n";
	print OUT $file_str;
	close(OUT);
}

my $dbh    = variable_table->getDBH();


## everyone has to have access to the dbh info

chmod 0440, variable_table->__dbh_file();

unless ($user_in_db) {
	my $ACL     = stefans_libs::database::userTable->new();
	my ( $pw, $noting, $salt) = $ACL->_hash_pw ($user_name, $user_pw );
	my $dataset = {
		'username'  => $user_username,
		'name'      => $user_name,
		'workgroup' => $user_workgroup,
		'position'  => $user_position,
		'email'     => $user_e_mail,
		'pw'        => $pw,
		'salt'      => $salt,
	};
	
	my $user_id = $ACL->AddDataset($dataset);
	$ACL->AddRole( { 'username' => $user_username, 'role' => 'admin' } );
	$ACL->AddRole( { 'username' => $user_username, 'role' => 'user' } ) if ( $0 =~m/\.t$/); # for testing
	$ACL->AddActionGroup ( {'username' => $user_username, 'action_group_name' => 'server_admin', 'action_group_description' => 'People in this group are responsible for the server maintainance.' } );
	print "The database user $user_username has got the id $user_id\n";
}else {
	print "The user did already exist.\n";
}




sub createPath {
	my ($path) = @_;
	my @path = split( "/", $path );
	my $check_path = "/";
	for ( my $i = 0 ; $i < @path ; $i++ ) {
		$check_path .= "$path[$i]/";
		mkdir($check_path) unless ( -d $check_path );
	}
	if ( -d $check_path ) {
		print "created path $check_path\n";
	}
	else {
		Carp::confess("I could not create the path $check_path \n$!\n");
	}
	return 1;
}

## IF YOU CHANGE THIS FUNCTION YOU ALSO NEED TO CHANGE THE CODE IN THE Genexpress_Catalyst.pm function!!
sub _hash_pw {
	my ( $username, $passwd ) = @_;
	Carp::confess("You MUST NOT hash a none existing passwd ('$passwd')!!")
	  unless ( $passwd =~ m/\w/ );
	## now I need to fetch the salt
	my ($salt);
	$salt = join "",
		  map { unpack "H*", chr( rand(256) ) } 1 .. 16;

	$passwd = $salt . " " . $passwd;
	for ( my $i = 0 ; $i < 1000 ; $i++ ) {
		$passwd = md5_hex($passwd);
	}
	return $passwd, undef, $salt;
}
