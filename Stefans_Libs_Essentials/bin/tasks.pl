#! /usr/bin/perl -w

#  Copyright (C) 2015-10-06 Stefan Lang

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

=head1 tasks.pl

A SIMPLE todo list application based on the to_do_list.pm db class.

To get further help use 'tasks.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use Cwd;
use stefans_libs::database::to_do_list;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $user, $project, $deadline, $task, @options );

Getopt::Long::GetOptions(
	"-user=s"       => \$user,
	"-summary=s"    => \$project,
	"-descr=s"       => \$task,
	"-deadline=s"   => \$deadline,
	"-options=s{,}" => \@options,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $user ) {
	$warn .= "the cmd line switch -user is undefined!\n";
}
unless ( defined $project ) {
	$warn .= "the cmd line switch -summary is undefined!\n";
}
unless ( defined $task ) {
	$warn .= "the cmd line switch -descr is undefined!\n";
}
unless ( defined $options[0] ) {
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

#warn $warn if ($warn =~ m/\w/ );

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for tasks.pl

   -user       :the username for this task
   -summary    :the project title / summary
   -descr      :the detailed task description
   -deadline   :a date this task has to be finished to
   
   -options    :optional
   				show:		show the actual task (default)
   				add:		create a new task
   				show_all:	show all tunfinished tasks for the user 
				show_fin:	show all finished tasks for the user
				show detailed :show summary and descr for each task
				relocate:   <child id> (to) <master id> 
				            link the child to the master
				            
				finish:     as first optionf followed by the id to finish
				            also use the descr to describe the outcome				
				
   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .=
  'perl ' . root->perl_include() . ' ' . $plugin_path . '/tasks.pl';
$task_description .= " -user $user"       if ( defined $user );
$task_description .= " -summary $project" if ( defined $project );
$task_description .= " -descr $task"       if ( defined $task );
$task_description .= ' -options ' . join( ' ', @options )
  if ( defined $options[0] );

my ( $User, $master_id, $last_id, $db, $child_id, $tmp );
$db = stefans_libs::database::to_do_list->new();

print "\n\n";
if ( -f ".task.info" ) {
	open( IN, "<.task.info" )
	  or die "strange - I found but could not open .task.info\n$!\n";
	( $User, $master_id, $last_id ) = map { chomp; $_ } <IN>;
	close(IN);
	$user = $User;
	warn join( "\t", "Saved information:", $User, $master_id, $last_id )
	  if ($debug);
}
unless ( $user =~ m/\w/ ) {
	die &helpString("I need to know the user\n");
}
$db->{username} = $user;
if ( !defined( $options[0] ) || $options[0] eq "show" ) {
	print "option show\n" if ( $debug );
	$tmp = { map { $_ => 1 } @options };
	if ( $tmp->{'all'} ) {
		print $db->show( undef, $tmp );
	}
	else {
		print $db->show( $master_id, $tmp );
	}
}
elsif ( $options[0] eq "add" ) {
	print "option add\n" if ( $debug );
	if ( defined $master_id ) {
		my ($master_data) =
		  @{ $db->_select_all_for_DATAFIELD( $master_id, 'id' ) };
		if ( $master_data->{'parent_id'} == 0 ) {
			$master_data->{'parent_id'} = $db->{'list'}->readLatestID() + 1;
			$db->UpdateDataset($master_data);
		}
		$child_id = $db->AddDataset(
			{
				'user'        => { 'username' => $user, },
				'path'        => cwd(),
				'summary'     => $project,
				'information' => $task,
				'send_time'   => $deadline,
			}
		);
		$db->{'list'}->add_to_list($master_data->{'parent_id'} , { 'id' => $child_id } );
		&save();
	}
	else {
		$child_id = $master_id = $db->AddDataset(
			{
				'user'        => { 'username' => $user },
				'path'        => cwd(),
				'summary'     => $project,
				'information' => $task,
				'send_time'   => $deadline
			}
		);
		&save();
	}
	print $db->show( $master_id, { map { $_ => 1 } @options } );
}
elsif ( $options[0] =~ m /^finish/ ){
	print "option finish\n" if ( $debug );
	unless ( $options[1]=~ m/^\d+$/ ) {
		warn "Sorry - if you want to finish a task please give me the id as second option!\n"
	}
	else {
	 	$db->UpdateDataset( { 'id' => $options[1], 'done' => 1, 'finalText' => $task } );
	}
	print $db->show( $master_id, { map { $_ => 1 } @options } );
}
elsif (  $options[0] =~ m /^relocate/ ){
	print "option relocate\n" if ( $debug );
	unless ( $options[1]=~ m/^\d+$/ && $options[2]=~ m/^\d+$/) {
		warn "Sorry - if you want to relocate == add to a new master id give me the child id as second option and the master id as third!\n"
	}
	else {
		($master_id, $child_id) = @options[2,1];
		my ($master_data) =
		  @{ $db->_select_all_for_DATAFIELD( $master_id, 'id' ) };
		if ( $master_data->{'parent_id'} == 0 ) {
			$master_data->{'parent_id'} = $db->{'list'}->readLatestID() + 1;
			$db->UpdateDataset($master_data);
		}
		$db->{'list'}->add_to_list( $master_id, { 'id' => $child_id } );
		&save();
	}
	print $db->show( $master_id, { map { $_ => 1 } @options } );
}
else {
	print "option $options[0]\n" if ( $debug );
	warn "I do not undestand what you want to do!\nAssume you want to see the data:\n";
	print $db->show( $master_id, { map { $_ => 1 } @options } );
}

print "\n\n";
sub save {
	open( OUT, ">.task.info" )
	  or die "I could not create the .task.info file!\n$!\n";
	print OUT join( "\n", $user, $master_id, $child_id );
	close OUT;
}
