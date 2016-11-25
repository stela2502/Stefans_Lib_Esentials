#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 10;
use PDL;

use FindBin;
my $plugin_path = "$FindBin::Bin";

BEGIN { use_ok 'stefans_libs::flexible_data_structures::data_table' }

my ( $value, @values, $exp, $data_table );

$data_table = data_table->new();
is_deeply( ref($data_table), 'data_table', 'new' );

$data_table->Add_2_Header( [ 'Name', 'Number' ] );
$data_table->{'data'} = [
	[ 'Mustermann',    45 ],
	[ 'Musterfrau',    35 ],
	[ 'Mustertochter', 12 ],
	[ 'Mustersohn',    10 ]
];

$value = $data_table->AsHTML();

#print "\$exp = " . root->print_perl_var_def( [split(/\n/, $value)] ) . ";\n";
$exp = [
	'<table border="1">',
	'<thead>	<tr ><th >Name</th><th >Number</th></tr>',
	'</thead><tbody>	<tr ><td >Mustermann</td><td >45</td></tr>',
	'	<tr ><td >Musterfrau</td><td >35</td></tr>',
	'	<tr ><td >Mustertochter</td><td >12</td></tr>',
	'	<tr ><td >Mustersohn</td><td >10</td></tr>',
	'</tbody></table>'
];

is_deeply( [ split( /[\n]/, $value ) ], $exp, "html export simple" );

$data_table->HTML_id('sortable');
$value = $data_table->AsHTML();
@$exp[0] = '<table border="1", id=\'sortable\'>';

#print "\$exp = " . root->print_perl_var_def( [split(/[\n]/, $value)] ) . ";\n";
is_deeply( [ split( /\n/, $value ) ], $exp, "html export using id='sortable'" );

$value = $data_table->HTML_modification_for_column(
	{ 'column_name' => 'Number', 'th' => 'class="numeric"' } );

is_deeply(
	$value,
	{
		'tr'     => '',
		'th'     => 'class="numeric"',
		'after'  => '',
		'td'     => '',
		'before' => '',
		'colsub' => '',
	},
	"set the HTML modification per row"
);
is_deeply( $data_table->HTML_modification_for_column('Number'),
	$value, "set and get the HTML modification per row" );

#print "\$exp = " . root->print_perl_var_def( $value ) . ";\n";

$value = $data_table->AsHTML();
@$exp[1] = '<thead>	<tr ><th >Name</th><th class="numeric">Number</th></tr>';
is_deeply( [ split( /\n/, $value ) ], $exp, "html export using column class" );

$data_table->HTML_line_mod("id='forgettMe'");
$exp = [
	'<table border="1", id=\'sortable\'>',
	'<thead>	<tr ><th >Name</th><th class="numeric">Number</th></tr>',
'</thead><tbody>	<tr id=\'forgettMe\'><td >Mustermann</td><td >45</td></tr>',
	'	<tr id=\'forgettMe\'><td >Musterfrau</td><td >35</td></tr>',
	'	<tr id=\'forgettMe\'><td >Mustertochter</td><td >12</td></tr>',
	'	<tr id=\'forgettMe\'><td >Mustersohn</td><td >10</td></tr>',
	'</tbody></table>'
];
$value = $data_table->AsHTML();
is_deeply( [ split( /\n/, $value ) ],
	$exp, "html export onClick for column row (simple id='xy')" );
  
$data_table->HTML_line_mod(
	sub {
		my ( $self, $array ) = @_;
		return
"onClick='showimage(\"mygallery\", \"pictures\", \"/some/path/to/nowhere/@$array[0]\" )'";
	}
);

$value = $data_table->AsHTML();
$exp   = [
	'<table border="1", id=\'sortable\'>',
	'<thead>	<tr ><th >Name</th><th class="numeric">Number</th></tr>',
'</thead><tbody>	<tr onClick=\'showimage("mygallery", "pictures", "/some/path/to/nowhere/Mustermann" )\'><td >Mustermann</td><td >45</td></tr>',
'	<tr onClick=\'showimage("mygallery", "pictures", "/some/path/to/nowhere/Musterfrau" )\'><td >Musterfrau</td><td >35</td></tr>',
'	<tr onClick=\'showimage("mygallery", "pictures", "/some/path/to/nowhere/Mustertochter" )\'><td >Mustertochter</td><td >12</td></tr>',
'	<tr onClick=\'showimage("mygallery", "pictures", "/some/path/to/nowhere/Mustersohn" )\'><td >Mustersohn</td><td >10</td></tr>',
	'</tbody></table>'
];
is_deeply( [ split( /\n/, $value ) ],
	$exp, "html export onClick for column row (function)" );

$data_table->{'some_path'} = '/some/path/to/nowhere/';
$data_table->HTML_line_mod(
	sub {
		my ( $self, $array ) = @_;
		return
"onClick='showimage(\"mygallery\", \"pictures\", \"$self->{'some_path'}@$array[0]\" )'";
	}
);
$value = $data_table->AsHTML();
is_deeply( [ split( /\n/, $value ) ],
	$exp, "html export onClick for column row (more complex function)" );

#print "\$exp = " . root->print_perl_var_def([ split( /\n/, $value ) ] ) . ";\n";

#print "\$exp = " . root->print_perl_var_def( $obj->GetAsArray('fold change') ) . ";\n";
