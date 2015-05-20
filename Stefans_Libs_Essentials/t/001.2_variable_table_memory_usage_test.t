#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests =>6;

BEGIN {
	use_ok 'stefans_libs::database::variable_table';
}

BEGIN {
	use_ok 'stefans_libs::database::lists::list_using_table';
}

BEGIN {
	use_ok 'stefans_libs::database::lists::basic_list';
}

my ( $table1, $table2, $table_3, $list_link, $value, $temp, $exp, $dbh );
my $st = time();
	
sub get_memory_imprint {
	my ( $rv );
	system ("ps -p $$ -v > log" );
	open (IN, "<log" );
	my ( $line1, $line2, @temp );
	@temp = <IN>;
	close ( IN );
	unlink ('log');
	($line1, $line2 ) =@temp;
	chomp($line1);
	chomp($line2);
	$line1 =~s/^\s+//;
	$line2 =~s/^\s+//;
	#print "Line1:$line1\nLine2:$line2\n";
	@temp = split(/\s\s*/, $line2 );
	my $i = 0;
	foreach ( split(/\s\s*/,$line1 ) ){
		next unless ( $_ =~m/\w/);
		#print "The key= '$_' -> $temp[$i]\n";
		$rv->{$_} = $temp[$i++];
	}
	return $rv->{'DRS'};
	#print "The value from ps = ".root::print_hashEntries( $rv , 3, "TEXT")."\n";
}

my $start_memory = &get_memory_imprint();
is_deeply ( $start_memory, 150931, "Start memory usage is 151115 -> 150983 -> 150931 ($start_memory)");

my $table_simple = variable_table->new();
$table_simple->{'dbh'}              = variable_table->getDBH();
$table_simple->{'_tableName'}       = 'only_one_column';
$table_simple->{'table_definition'} = {
	'table_name' => 'test_organism',
	'variables'  => [
		{
			'name'        => 'userrole',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '1',
			'description' => '',
		}
	]
};
$table_simple->{'UNIQUE_KEY'} = ['userrole'];
$table_simple->{'INDICES'}    = ['userrole'];
$table_simple->create();

my $variable = &get_memory_imprint() - $start_memory;
is_deeply ($variable, 91048, "Cost per table is 91096 -> 91116 -> 91112 -> 91088 -> 91048 ($variable)");

$variable = &get_memory_imprint();
is_deeply ( $variable , 241979, "the total allocated memory ($variable)");



