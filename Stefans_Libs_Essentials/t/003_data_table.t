#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 97;
use PDL;

use FindBin;
my $plugin_path = "$FindBin::Bin";
my $outpath = $plugin_path."/data/output/";

BEGIN { use_ok 'stefans_libs::flexible_data_structures::data_table' }

my ( $value, @values, $exp, $data_table, $data_table2 );

## I have an issue with the default value!
$data_table2 = data_table->new();
$data_table2->Add_2_Header('name');
$data_table2->Add_2_Header('value');
$data_table2->AddDataset( { 'name' => 'stefan' } );
$data_table2->AddDataset( { 'name' => 'egon' } );
is_deeply(
	$data_table2->AsString(),
	"#name	value\nstefan	\negon	\n",
	"no default value"
);
$data_table2->setDefaultValue( 'value', 0 );
is_deeply(
	$data_table2->AsString(),
	"#name	value\nstefan	0\negon	0\n",
	"with default value"
);

my $test = $data_table2->copy();
$test->add_column( 'Test', [ 1, 2 ] );
is_deeply( $test->AsString(), "#name	value\tTest\nstefan\t0\t1\negon\t0\t2\n",
	"add_column" );
$test = data_table->new();
$test -> parse_from_string ( "#h1\th2\th3\ndata\tdata2\t\ndata3\tdata4\tdata5\n");
is_deeply ( $test->AsString(), "#h1\th2\th3\ndata\tdata2\t\ndata3\tdata4\tdata5\n", "parse from string with trailing empty string");

$data_table2 = data_table->new();
$data_table2->Add_2_Header('name');
$data_table2->Add_2_Header('value');
$data_table2->AddDataset( { 'name' => 'stefan' } );
$data_table2->AddDataset( { 'name' => 'egon' } );
$data_table2->setDefaultValue( 'value', 0 );
$data_table2->Rename_Column( 'value', 'new_value' );
is_deeply(
	$data_table2->AsString(),
	"#name	new_value\nstefan	0\negon	0\n",
	"with default value"
);

$data_table = data_table->new();
foreach ( 'forename', 'surename', 'university' ) {
	$data_table->Add_2_Header($_);
}
$data_table2 = data_table->new();
foreach ( 'forename', 'surename', 'gender' ) {
	$data_table2->Add_2_Header($_);
}
$data_table->AddDataset(
	{ 'forename' => 'stefan', 'surename' => 'lang', 'university' => 'none' } );
$data_table2->AddDataset(
	{ 'forename' => 'stefan', 'surename' => 'lang', 'gender' => 'male' } );
$data_table2->AddDataset(
	{ 'forename' => 'geraldin', 'surename' => 'lang', 'gender' => 'female' } );
$data_table->merge_with_data_table($data_table2);
is_deeply(
	$data_table->get_line_asHash(0),
	{
		'forename'   => 'stefan',
		'surename'   => 'lang',
		'university' => 'none',
		'gender'     => 'male'
	},
	"I could merge on two columns"
);
is_deeply(
	$data_table->get_line_asHash(1),
	{
		'forename'   => 'geraldin',
		'surename'   => 'lang',
		'university' => undef,
		'gender'     => 'female'
	},
	"I could merge on two columns (2)"
);

$data_table = data_table->new();
is_deeply( ref($data_table), 'data_table',
	'simple test of function data_table -> new()' );

my $name = data_table->new();
$name->line_separator(';');

is_deeply(
	$name->__split_line('stefan;"lang;male"'),
	[ 'stefan', '"lang', 'male"' ],
	'the new string separator noes NOT work by default'
);
$name->string_separator('none');
is_deeply(
	$name->__split_line('stefan;"lang;male"'),
	[ 'stefan', '"lang', 'male"' ],
	'the new string separator can be shut off'
);
$name->string_separator('"');
is_deeply(
	$name->__split_line(
		'"stefan";"lang;male";1;3;5;1e-08;"Here I have a string;";9'),
	[ 'stefan', 'lang;male', 1, 3, 5, 1e-08, "Here I have a string;", 9 ],
	'the new string separator - complex line'
);
is_deeply(
	$name->__split_line(
		'"lang;male";"stefan";1;3;5;1e-08;"Here I have a string;";9'),
	[ 'lang;male','stefan',  1, 3, 5, 1e-08, "Here I have a string;", 9 ],
	'the new string separator - complex line string at the beginning'
);
is_deeply(
	$name->__split_line(
		'"stefan";"lang;male";1;3;5;1e-08;9;"Here I have a string;"'),
	[ 'stefan', 'lang;male', 1, 3, 5, 1e-08, 9, "Here I have a string;" ],
	'the new string separator - complex line string at the end'
);

is_deeply(
	$name->__split_line('stefan;lang;male'),
	[ 'stefan', 'lang', 'male' ],
'the new string separator works on simple things using string_separator (") '
);
is_deeply(
	$name->__split_line('stefan;"lang;male"'),
	[ 'stefan', 'lang;male' ],
	'the new string separator with string_separator (") works on usage end '
);
is_deeply(
	$name->__split_line('"stefan;lang";male"'),
	[ 'stefan;lang', 'male' ],
	'the new string separator with string_separator (") works start'
);
is_deeply(
	$name->__split_line('stefan;"lang;hugo";male'),
	[ 'stefan', 'lang;hugo', 'male' ],
	'the new string separator with string_separator (") works center'
);

$data_table->parse_from_string(
"#first\tsecond\temail\tage\nstefan\tlang\tstefan\@nix.de\t32\neva\tlang\tnix2\@nix.de\t30\n"
);

is_deeply(
	$data_table->AsString(),
"#first\tsecond\temail\tage\nstefan\tlang\tstefan\@nix.de\t32\neva\tlang\tnix2\@nix.de\t30\n",
	"we can reas from a string and get the string back!"
);

is_deeply( ref( $data_table->createIndex('second') ),
	'HASH', "we get no error while creating an index" );

is_deeply(
	[ $data_table->define_subset( 'name', [ 'second', 'first' ] ) ],
	[ 1, 0 ],
	"it seams as if we could add an subset"
);

is_deeply(
	$data_table->AsString('name'),
	"#second\tfirst\nlang\tstefan\nlang\teva\n",
	"we can get the data for a subset"
);

is_deeply(
	$data_table->getAsHash( 'name', 'email' ),
	{ 'lang stefan' => "stefan\@nix.de", 'lang eva' => "nix2\@nix.de" },
	"the function getAsHash"
);

is_deeply( $data_table->Add_2_Header('nationality'),
	4, "we can add a new column" );

is_deeply(
	$data_table->Add_Dataset(
		{ 'first' => 'geraldin', 'second' => 'lang', 'nationality' => 'de' }
	),
	3,
	"we can add a dataset"
);

is_deeply(
	[ split( /[\t\n]/, $data_table->AsString() ) ],
	[
		split(
			/[\t\n]/,
"#first\tsecond\temail\tage\tnationality\nstefan\tlang\tstefan\@nix.de\t32\t\neva\tlang\tnix2\@nix.de\t30\t\ngeraldin\tlang\t\t\tde\n"
		)
	],
	"and we can get the updated data structure back!"
);

is_deeply(
	[
		$data_table->get_rowNumbers_4_columnName_and_Entry(
			'name', ['lang', 'geraldin'] 
		)
	],
	[2],
	"we can get the row number for one entry"
);

is_deeply(
	[ $data_table->getLines_4_columnName_and_Entry( 'second', 'lang' ) ],
	[
		[ "stefan", "lang", "stefan\@nix.de", "32" ],
		[ 'eva',    'lang', 'nix2@nix.de',    '30' ],
		[ 'geraldin', 'lang', undef, undef, 'de' ],
	],
	"we can use getLines_4_columnName_and_Entry"
);

$data_table->Add_dataset_for_entry_at_index( { 'nationality' => 'de' },
	'lang', 'second' );

#die "\$exp = " . root->print_perl_var_def( [$data_table->getLines_4_columnName_and_Entry('name', [ 'lang', 'stefan' ]) ] ) . ";\n";
is_deeply(
	[
		$data_table->getLines_4_columnName_and_Entry(
			'name', [ 'lang', 'stefan' ]
		)
	],
	[ [ 'stefan', 'lang', 'stefan@nix.de', '32', 'de' ] ],
	"we can add data to a row"
);

is_deeply(
	[ $data_table->getLines_4_columnName_and_Entry( 'second', 'lang' ) ],
	[
		[ "stefan",   "lang", "stefan\@nix.de", "32",  'de' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30',  'de' ],
		[ 'geraldin', 'lang', undef,            undef, 'de' ]
	],
"and the data is added to all rows, but not to the row the data was already present"
);

$data_table->Add_dataset_for_entry_at_index( { 'nationality' => 'se' },
	'lang', 'second' );

is_deeply(
	[ $data_table->getLines_4_columnName_and_Entry( 'second', 'lang' ) ],
	[
		[ "stefan",   "lang", "stefan\@nix.de", "32",  'se' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30',  'se' ],
		[ 'geraldin', 'lang', undef,            undef, 'se' ]
	],
	"if a new entry is added, the old data is replaced"
);

$data_table->Add_unique_key( 'name_loc', [ 'first', 'second', 'nationality' ] );
$data_table->write_file($outpath.'save.xls');
$data_table->Add_2_Header('second nationality');
$data_table->Add_dataset_for_entry_at_index( { 'second nationality' => 'de' },
	'lang', 'second' );

#die "\$exp = " . root->print_perl_var_def( [$data_table->getLines_4_columnName_and_Entry( 'second', 'lang' )]);
$exp = [
	[ 'stefan',   'lang', 'stefan@nix.de', '32',  'se', 'de' ],
	[ 'eva',      'lang', 'nix2@nix.de',   '30',  'se', 'de' ],
	[ 'geraldin', 'lang', undef,           undef, 'se', 'de' ]
];
is_deeply(
	[ $data_table->getLines_4_columnName_and_Entry( 'second', 'lang' ) ],
	$exp,
"if the new entry is an array, we create new lines for the not existing entries"
);
$data_table = data_table->new();
$data_table->read_file($outpath.'save.xls');
$data_table->{'data'} = [
	[ "stefan",   "lang", "stefan\@nix.de", "32",  'se' ],
	[ 'eva',      'lang', 'nix2@nix.de',    '30',  'se' ],
	[ 'geraldin', 'lang', undef,            undef, 'se' ],
	[ "stefan",   "lang", "stefan\@nix.de", "32",  'de' ],
	[ 'eva',      'lang', 'nix2@nix.de',    '30',  'de' ],
	[ 'geraldin', 'lang', '',               '',    'de' ]
];
$data_table->UpdateIndices_at_position(3);
$data_table->UpdateIndices_at_position(4);
$data_table->UpdateIndices_at_position(5);
## change back to the expected data!

is_deeply(
	[ $data_table->getLines_4_columnName_and_Entry( 'second', 'lang' ) ],
	[
		[ "stefan",   "lang", "stefan\@nix.de", "32",  'se' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30',  'se' ],
		[ 'geraldin', 'lang', undef,            undef, 'se' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32",  'de' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30',  'de' ],
		[ 'geraldin', 'lang', '',               '',    'de' ]
	],
	"The data is changed back - hopefully!"
);

## and finally - the import export...
$data_table->define_subset( 'name', [ 'second', 'first' ]);
$data_table->Add_dataset_for_entry_at_index( { 'email' => 'nix', 'age' => 2 },
	[ 'lang', 'geraldin' ], 'name' );
$data_table->define_subset( 'eMail Addresse', ['email'] )
  ;    ## ein Alias eingefügt
$data_table->print2file( $outpath.'temp_table.txt');
$data_table2 = data_table->new();
$data_table2->read_file($outpath.'temp_table.xls');
$data_table->{'read_filename'} = $outpath.'temp_table.xls';
#$data_table->AsString();
#$data_table2->AsString();

#print "I got a problem here - why are the two tables not the same?\n"."TableA:\n".$data_table->AsString().
#"TableB:\n".$data_table2 ->AsString();

is_deeply( [split( /\n\t/,$data_table2->AsString() ) ], [split( /\n\t/,$data_table->AsString() ) ], "import / export is ok" );


$data_table2 = $data_table->Sort_by( [ [ 'first', { 'eva' => 1, 'geraldin' => 2,'hugo' => 3, "stefan"=> 30} ] ] );

is_deeply(
	$data_table2->{'data'},
	[
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'se' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'de' ],
		[ 'geraldin', 'lang', 'nix',            '2',  'se' ],
		[ 'geraldin', 'lang', 'nix',            '2',  'de' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'se' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'de' ]
	],
	"we can sort on an external hash to numbers"
);

is_deeply(
	$data_table2->{'header'},
	$data_table->{'header'},
	'Sort does not mess up the header info'
);


$data_table2 = $data_table->Sort_by( [ [ 'age', 'numeric' ] ] );

is_deeply(
	$data_table2->{'data'},
	[
		[ 'geraldin', 'lang', 'nix',            '2',  'se' ],
		[ 'geraldin', 'lang', 'nix',            '2',  'de' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'se' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'de' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'se' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'de' ]
	],
	"we can sort 'numeric'"
);
is_deeply(
	$data_table2->{'header'},
	$data_table->{'header'},
	'Sort does not mess up the header info'
);

$data_table2 = $data_table->Sort_by( [ [ 'first', 'lexical' ] ] );

is_deeply(
	$data_table2->{'data'},
	[
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'se' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'de' ],
		[ 'geraldin', 'lang', 'nix',            '2',  'se' ],
		[ 'geraldin', 'lang', 'nix',            '2',  'de' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'se' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'de' ]
	],
	"we can sort 'lexical'"
);

$data_table2 = $data_table->Sort_by( [ [ 'age', 'antiNumeric' ] ] );

my @temp = ('stefan');
$value =
  $data_table2->select_where( 'first',
	sub { return 1 if ( $_[0] eq "stefan" ); return 0; } );

is_deeply(
	$value->{'data'},
	[
		[ "stefan", "lang", "stefan\@nix.de", "32", 'se' ],
		[ "stefan", "lang", "stefan\@nix.de", "32", 'de' ]
	],
	"we can get a column subset"
);

#print $value-> AsLatexLongtable();

is_deeply(
	$data_table2->{'data'},
	[
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'se' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'de' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'se' ],
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'de' ],
		[ 'geraldin', 'lang', 'nix',            '2',  'se' ],
		[ 'geraldin', 'lang', 'nix',            '2',  'de' ]
	],
	"we can sort 'antiNumeric'"
);

#$data_table2 = $data_table->Get_first_for_column( 'first', 1, 'lexical' );
$data_table2 = $data_table->_copy_without_data();
$data_table2->{'data'} = [
	[ 'eva',      'lang', 'nix2@nix.de',    '30', 'se' ],
	[ 'geraldin', 'lang', 'nix',            '2',  'se' ],
	[ "stefan",   "lang", "stefan\@nix.de", "32", 'se' ]
];    ## to not mess up the whole test script.

is_deeply(
	$data_table2->{'data'},
	[
		[ 'eva',      'lang', 'nix2@nix.de',    '30', 'se' ],
		[ 'geraldin', 'lang', 'nix',            '2',  'se' ],
		[ "stefan",   "lang", "stefan\@nix.de", "32", 'se' ]
	],
	"we can restrict the dataset to on per line entry"
);

$data_table2->createIndex('name');

#print $data_table2->AsTestString();
#die "\$exp = "
#  . root->print_perl_var_def( $data_table2->{'index'}->{'name'} ) . ";\n";

is_deeply( $data_table2->get_value_for( 'name',  'lang stefan' , 'email' ),
	'stefan@nix.de', "We can get one value" );

is_deeply(
	$data_table2->AsLatexLongtable(), '
\begin{longtable}{|c|c|c|c|c|}
\hline
first & second & email & age & nationality\\\\
\hline
\hline
\endhead
\hline \multicolumn{5}{|r|}{{Continued on next page}} \\\\ 
\hline
\endfoot
\hline \hline
\endlastfoot
 eva & lang & nix2@nix.de & 30 & se \\\\
 geraldin & lang & nix & 2 & se \\\\
 stefan & lang & stefan@nix.de & 32 & se \\\\
\end{longtable}

', "we can print as latex longtable"
);

$data_table2->define_subset( 'info', [ 'first', 'gender' ] );
is_deeply( $data_table2->Max_Header(),
	6, "Header is updated during the automatic column add ('gender')" );
is_deeply(
	$data_table2->{'last_warning'},
"data_table::define_subset -> sorry - we do not know a column called 'gender'\n"
	  . "but we have created that column for you!",
	"we can create a subset using previously undefined columns!"
);
is_deeply(
	$data_table2->AsLatexLongtable('info'), '
\begin{longtable}{|c|c|}
\hline
first & gender\\\\
\hline
\hline
\endhead
\hline \multicolumn{2}{|r|}{{Continued on next page}} \\\\ 
\hline
\endfoot
\hline \hline
\endlastfoot
 eva &  \\\\
 geraldin &  \\\\
 stefan &  \\\\
\end{longtable}

', "We can get a table with previously undefined columns."
);

## Now lets test the (new) description
$data_table2->Add_2_Description("Just a test file");
my $data_table3 = data_table->new();
@{ @{ $data_table2->{'data'} }[0] }[5] = 'female';
$data_table3->parse_from_string( $data_table2->AsString() );

is_deeply(
	$data_table3->{'__max_header__'},
	$data_table2->{'__max_header__'},
	'complex.....'
);
is_deeply( $data_table3->AsString, $data_table2->AsString,
	"we can add a description and create the same object from the string" );
my $other_data_table = data_table->new();
$other_data_table->Add_2_Header('some_crap');
$other_data_table->Add_2_Header('second');
$other_data_table->createIndex('second');
$other_data_table->Add_Dataset(
	{ 'some_crap' => 'nothing - really', 'second' => 'lang' } );
is_deeply(
	$other_data_table->AsString(),
	"#some_crap\tsecond\nnothing - really\tlang\n",
	"we add a simple column to the \$other_table"
);

$data_table2->Add_Dataset(
	{
		'first'  => 'hugo',
		'second' => 'Boss',
		'email'  => 'Hugo.Boss@nix.com'
	}
);

#print "the data_table3 has the index columns ".join(", ", (keys %{$data_table3->{'index'}}))."\n";

#print "\nWith the table\n".$other_data_table->AsString();
$data_table2->createIndex('second');
is_deeply( $data_table2->Max_Header(), 6, "Header is 6 before merge" );
$value = [ @{ $data_table2->{'header'} } ];    ## true copy....
push( @$value, 'some_crap' );
$data_table2->{'debug'} = 1;
$data_table2 = $data_table2->merge_with_data_table($other_data_table);

#print "Is the table merged ?\n" . $data_table2->AsTestString();

is_deeply( $data_table2->{'header'}, $value, "Header is merged" );
is_deeply( $data_table2->{'__max_header__'},
	scalar(@$value), "max_header is updated  (exp =" . scalar(@$value) . ")" );

is_deeply( $data_table2->Header_Position('some_crap'),
	6, "we get a merged table" );

#warn root::get_hashEntries_as_string ($data_table3 -> get_line_asHash ( 3 ), 3, "please see if we got a line test ");
$value = {
	'some_crap'   => undef,
	'nationality' => undef,
	'gender'      => undef,
	'age'         => undef,
	'first'       => 'hugo',
	'second'      => 'Boss',
	'email'       => 'Hugo.Boss@nix.com',
#	'___DATA___'  => 'Boss'
	,    ## new as I have allowed the usage of one column subsets as aliases
#	'eMail Addresse' => 'Hugo.Boss@nix.com',
};
#print "\$exp = ".root->print_perl_var_def($data_table2->get_line_asHash(3) ).";\n";
is_deeply( $data_table2->get_line_asHash(3),
	$value, "we do not touch a not acceptable column" );

$data_table2->define_subset( 'name', [ 'first', 'second' ] );
is_deeply(
	[ $data_table2->get_value_for( 'second', 'Boss', 'name' ) ],
	[ 'Boss', 'hugo' ],
	"we can use 'get_value_for'"
);
is_deeply(
	[ $data_table2->get_value_for( 'first', 'stefan', 'name' ) ],
	[ 'lang', 'stefan' ],
	"and we can use the function a second time"
);

is_deeply(
	[ $data_table2->get_value_for( 'second', 'Boss', 'ALL' ) ],
	[ 'hugo', 'Boss', 'Hugo.Boss@nix.com', undef, undef, undef, undef ],
	"we can search for all entries"
);

#print root::get_hashEntries_as_string ($data_table, 3, "the old data table ");
#print root::get_hashEntries_as_string ($data_table2, 3, "the new data table ");

$data_table = $data_table2->GetAsObject('name');
is_deeply(
	$data_table->AsString(),
"#Just a test file\n#second\tfirst\nlang\teva\nlang\tgeraldin\nlang\tstefan\nBoss\thugo\n",
	"we can get a table object for a subset"
);
$exp = $data_table->getAsHash( "first", 'second' );
is_deeply( $exp->{'geraldin'}, 'lang', "getAsHash" );
$data_table->set_HeaderName_4_position( "new name", 1 );
is_deeply(
	$data_table->AsString(),
"#Just a test file\n#second\tnew name\nlang\teva\nlang\tgeraldin\nlang\tstefan\nBoss\thugo\n",
	"and we can rename a column and get the right STRING back"
);
$value = $data_table->getAsHash( "new name", 'second' );
is_deeply( $value, $exp,
"after a rename of the column I can still get the same dataset using getAsHash with the new column names"
);

$data_table->set_HeaderName_4_position( 8, 1 );
$value = $data_table->getAsHash( 8, 'second' );
is_deeply( $value, $exp, "we get no problem using intergers as column titles" );

#print "we try to select all columns where 'first' eq 'geraldin'\n".$data_table2->AsString()."\n";
$value =
  $data_table2->select_where( "first", sub { return shift eq 'geraldin' } );
is_deeply( ref($value), 'data_table', 'select_where return object' );
is_deeply(
	$value->AsString(),
	"#Just a test file\n"
	  . "#first\tsecond\temail\tage\tnationality\tgender\tsome_crap\ngeraldin\tlang\tnix\t2\tse	\tnothing - really\n",
	'select_where return data'
);
$exp   = {};
$value = $data_table2->select_where(
	"second",
	sub {
		if ( !defined $exp->{ $_[0] } ) { $exp->{ $_[0] } = 1; return 1; }
		return 0;
	}
);
is_deeply(
	$value->AsString(),
	"#Just a test file\n"
	  . "#first\tsecond\temail\tage\tnationality\tgender\tsome_crap\n"
	  . "eva\tlang\tnix2\@nix.de\t30\tse\tfemale\tnothing - really\n"
	  . "hugo\tBoss\tHugo.Boss\@nix.com\t\t\t\t\n",
	'select_where return data #2'
);

## check the calculate function on table2 that looks like
## print $data_table2->AsString();
# #first   second  email               age  nationality  gender  some_crap
# eva      lang    nix2@nix.de         30   se                   nothing - really
# geraldin lang    nix                 2    se                   nothing - really
# stefan   lang    stefan@nix.de       32   se                   nothing - really
# hugo     Boss    Hugo.Boss@nix.com

## so now add the gender!
$data_table2->calculate_on_columns(
	{
		'function' => sub {
			$! = undef;
			return 'male' if ( $_[0] eq "stefan" );
			return 'male' if ( $_[0] eq "hugo" );
			return 'female';
		},
		'data_column'   => 'first',
		'target_column' => 'gender',
		'function_as_string' =>
		  ' return \'male\' if ( "stefan hugo" =~ /$_[0]/ ); return \'female\''
	}
);
is_deeply(
	$data_table2->AsString(),
"#Just a test file\n#first\tsecond\temail\tage\tnationality\tgender\tsome_crap\n"
	  . "eva\tlang\tnix2\@nix.de\t30\tse\tfemale\tnothing - really\n"
	  . "geraldin\tlang\tnix\t2\tse\tfemale\tnothing - really\n"
	  . "stefan\tlang\tstefan\@nix.de\t32\tse\tmale\tnothing - really\n"
	  . "hugo\tBoss\tHugo.Boss\@nix.com\t\t\tmale\t\n",
	'calculate_on_columns no column creation'
);

$data_table2 = data_table->new();
$data_table2->string_separator('"');
$data_table2->line_separator(",");
$data_table2->parse_from_string(
'"Probe Set ID",Affy SNP ID,"dbSNP RS ID",Chromosome,"Physical Position","Strand",ChrX pseudo-autosomal region 1,Cytoband,"Flank","Allele A","Allele B","Associated Gene","Genetic Map","Microsatellite","Fragment Enzyme Type Length Start Stop","Allele Frequencies","Heterozygous Allele Frequencies","Number of individuals/Number of chromosomes","In Hapmap","Strand Versus dbSNP","Copy Number Variation","Probe Count","ChrX pseudo-autosomal region 2","In Final List","Minor Allele","Minor Allele Frequency","% GC"
"SNP_A-1780619",10004759,"rs17106009","1","50433725","-",0,"p33","ggatattgtgtgagga[A/G]taagcccacctgtggt","A","G","ENST00000371827 // intron // 0 // Hs.213050 // ELAVL4 // 1996 // ELAV (embryonic lethal, abnormal vision, Drosophila)-like 4 (Hu antigen D) /// ENST00000371821 // intron // 0 // Hs.213050 // ELAVL4 // 1996 // ELAV (embryonic lethal, abnormal vision, Drosophila)-like 4 (Hu antigen D) /// ENST00000371819 // intron // 0 // Hs.213050 // ELAVL4 // 1996 // ELAV (embryonic lethal, abnormal vision, Drosophila)-like 4 (Hu antigen D) /// ENST00000323186 // intron // 0 // --- // --- // --- // ELAV-like protein 4 (Paraneoplastic encephalomyelitis antigen HuD) (Hu-antigen D). [Source:Uniprot/SWISSPROT;Acc:P26378] /// NM_021952 // intron // 0 // Hs.213050 // ELAVL4 // 1996 // ELAV (embryonic lethal, abnormal vision, Drosophila)-like 4 (Hu antigen D) /// ENST00000357083 // intron // 0 // Hs.213050 // ELAVL4 // 1996 // ELAV (embryonic lethal, abnormal vision, Drosophila)-like 4 (Hu antigen D) /// ENST00000361667 // intron // 0 // --- // --- // --- // ELAV-like protein 4 (Paraneoplastic encephalomyelitis antigen HuD) (Hu-antigen D). [Source:Uniprot/SWISSPROT;Acc:P26378] /// ENST00000371823 // intron // 0 // Hs.213050 // ELAVL4 // 1996 // ELAV (embryonic lethal, abnormal vision, Drosophila)-like 4 (Hu antigen D) /// ENST00000371824 // intron // 0 // Hs.213050 // ELAVL4 // 1996 // ELAV (embryonic lethal, abnormal vision, Drosophila)-like 4 (Hu antigen D)","72.030224900657 // D1S2824 // D1S197 // --- // --- /// 76.2778636775225 // D1S2706 // D1S2661 // --- // --- /// 68.1611616801535 // --- // --- // TSC59969 // TSC770243","D1S1559 // downstream // 52144 /// D1S2299E // upstream // 6915","StyI // --- // 817 // 50433297 // 50434113 /// NspI // --- // 574 // 50433477 // 50434050","0.010204 // 0.989796 // CEPH /// 0.0 // 1.0 // Han Chinese /// 0.0 // 1.0 // Japanese /// 0.022222 // 0.977778 // Yoruba","0.0202 // CEPH /// 0.0 // Han Chinese /// 0.0 // Japanese /// 0.043457 // Yoruba","49.0 // CEPH /// 45.0 // Han Chinese /// 45.0 // Japanese /// 45.0 // Yoruba","YES","reverse","---","12","0","YES","--- // CEPH /// --- // Han Chinese /// --- // Japanese /// --- // Yoruba","0.010204 // CEPH /// 0.0 // Han Chinese /// 0.0 // Japanese /// 0.022222 // Yoruba","0.415785"
"SNP_A-1780618",10004754,"rs233978","4","104894961","+",0,"q24","ggatattgtccctggg[A/G]atggccttatttatct","A","G","ENST00000305749 // downstream // 714054 // Hs.12248 // CXXC4 // 80319 // CXXC finger 4 /// NM_001059 // upstream // 34539 // Hs.942 // TACR3 // 6870 // Tachykinin receptor 3 /// NM_025212 // downstream // 714054 // Hs.12248 // CXXC4 // 80319 // CXXC finger 4 /// ENST00000304883 // upstream // 34539 // Hs.942 // TACR3 // 6870 // Tachykinin receptor 3","108.086324698038 // D4S1572 // D4S2913 // --- // --- /// 107.781224080953 // D4S1591 // D4S2907 // --- // --- /// 105.84222066207 // --- // --- // TSC571244 // TSC798293","D4S2650 // downstream // 90282 /// D4S1344 // upstream // 103722","StyI // --- // 221 // 104894854 // 104895074 /// NspI // --- // 700 // 104894812 // 104895511","0.38 // 0.62 // CEPH /// 0.366667 // 0.633333 // Han Chinese /// 0.322222 // 0.677778 // Japanese /// 0.2 // 0.8 // Yoruba","0.4712 // CEPH /// 0.5111 // Han Chinese /// 0.4667 // Japanese /// 0.32 // Yoruba","50.0 // CEPH /// 45.0 // Han Chinese /// 45.0 // Japanese /// 50.0 // Yoruba","YES","reverse","---","12","0","YES","--- // CEPH /// --- // Han Chinese /// --- // Japanese /// --- // Yoruba","0.38 // CEPH /// 0.366667 // Han Chinese /// 0.322222 // Japanese /// 0.2 // Yoruba","0.358613"'
);

#print "\$exp = " . root->print_perl_var_def( $data_table2->{'col_format'} ) . ";\n";
$exp = {
  '0' => '1',
  '10' => '1',
  '11' => '1',
  '12' => '1',
  '13' => '1',
  '14' => '1',
  '15' => '1',
  '16' => '1',
  '17' => '1',
  '18' => '1',
  '19' => '1',
  '1' => '0',
  '2' => '1',
  '20' => '1',
  '21' => '1',
  '22' => '1',
  '23' => '1',
  '24' => '1',
  '25' => '1',
  '26' => '1',
  '3' => '1',
  '4' => '1',
  '5' => '1',
  '6' => '0',
  '7' => '1',
  '8' => '1',
  '9' => '1'
};


is_deeply(
	$data_table2->{'col_format'},$exp,	"col_format storage");
	
#print $data_table2->AsString();
is_deeply( $data_table2->Header_Position('Probe Set ID'),
	0, "the column header was identified in the right way!" );
is_deeply( $data_table2->Header_Position('Affy SNP ID'),
	1, "the second column header was identified in the right way!" );
is_deeply( $data_table2->Header_Position('% GC'),
	26, "the last column header was identified in the right way!" );

is_deeply(
	$data_table2->getAsArray('Probe Set ID'),
	[ 'SNP_A-1780619', 'SNP_A-1780618' ],
	"data import first column"
);
is_deeply(
	$data_table2->getAsArray('% GC'),
	[ 0.415785, 0.358613 ],
	"data import last column"
);

$data_table2 = data_table->new();
$data_table2->parse_from_string(
	"#name	payment	sex\nA	10	m\nB	6	m\nC	40	w\nD	30	w\n");
$value = $data_table2->pivot_table(
	{
		'grouping_column'    => 'sex',
		'Sum_data_column'    => 'payment',
		'Sum_target_columns' => ['mean_payment'],
		'Suming_function'    => sub {
			my $sum = 0;
			foreach (@_) { $sum += $_; }
			return $sum / scalar(@_);
		  }
	}
);
$exp = "#sex	mean_payment\nm	8\nw	35\n";
is_deeply( $value->AsString(), $exp, 'simple pivot_table' );
$data_table2->define_subset( 'data', [ 'payment', 'name' ] );
$value = $data_table2->pivot_table(
	{
		'grouping_column'    => 'sex',
		'Sum_data_column'    => 'data',
		'Sum_target_columns' => [ 'mean_payment', 'names', 'subjects' ],
		'Suming_function'    => sub {
			my $sum  = 0;
			my $name = '';
			for ( my $i = 0 ; $i < @_ ; $i += 2 ) {
				$sum += $_[$i];
				$name .= $_[ $i + 1 ] . " ";
			}
			chop($name);
			return ( $sum / scalar(@_) * 2, $name, scalar(@_) / 2 );
		  }
	}
);
$exp = "#sex	mean_payment	names	subjects\nm	8	A B	2\nw	35	C D	2\n";
is_deeply( $value->AsString(), $exp, 'complex pivot_table' );

my $temp = data_table->new();
$temp->read_file( $plugin_path . "/data/data_table_pivot_test.xls" );
$temp->define_subset( 'hyper_data', [ 'Gene_Symbol', 'pathway_name' ] );

my $return = $temp->pivot_table(
	{
		'grouping_column' => 'kegg_pathway.id',
		'Sum_data_column' => 'hyper_data',
		'Sum_target_columns' =>
		  [ 'matched genes', 'pathway_name', 'Gene Symbols' ],
		'Suming_function' => sub {
			my $count        = 0;
			my $genes        = '';
			my $already_used = {};
			for ( my $i = 0 ; $i < @_ ; $i += 2 ) {
				next if ( defined $already_used->{ $_[$i] } );
				$already_used->{ $_[$i] } = 1;
				$count++;
				$genes .= $_[$i] . " ";
			}
			chop($genes);
			return $count, $_[1], $genes;
		  }
	}
);
$exp = [
	'#kegg_pathway.id', 'matched genes', 'pathway_name', 'Gene Symbols
104', '6', 'Bladder cancer', 'FIGF MDM2 MMP1 RPS6KA5 VEGFA VEGFC
105', '23', 'Cytokine-cytokine receptor interaction',
'BMPR2 CD70 CSF2RA CX3CL1 CXCL14 CXCL16 FIGF IL10RB IL1A IL1RAP IL24 IL9 IL9R KIT LTB PDGFB PDGFRB TGFB2 TNFRSF14 TNFRSF25 TNFSF4 VEGFA VEGFC
110', '10', 'Chemokine signaling pathway',
	'ADCY1 CX3CL1 CXCL14 CXCL16 GNAI1 GNG7 PRKCZ PRKX TIAM2 WASL
116', '9', 'Tight junction', 'CLDN23 EPB41 GNAI1 INADL MYL9 PRKCZ RRAS TJP3 YES1
122', '5', 'Small cell lung cancer', 'CDKN1B LAMA4 LAMB2 LAMB3 RARB
.
.
.
78', '18', 'MAPK signaling pathway',
'CACNA1H CACNG6 DUSP8 IL1A MAP2K5 MAP3K12 MAP4K1 MAPK8IP1 MKNK1 PDGFB PDGFRB PPM1B PRKX RASA1 RPS6KA5 RRAS STMN1 TGFB2
84', '18', 'Axon guidance',
'ABLIM2 EFNA1 EFNB3 EPHB6 GNAI1 NCK2 NRP1 NTN3 PLXNB1 PLXNC1 RASA1 RGS3 SEMA3F SEMA5B SEMA6A SEMA6B UNC5A UNC5B
90', '9', 'Purine metabolism',
	'ADCY1 AK5 AMPD3 PDE1B PDE6A PDE7A PDE9A PNPT1 PRUNE
91', '5', 'Adherens junction', 'IQGAP1 SNAI2 TCF7L1 WASL YES1
95', '8', 'Endocytosis',       'DNAJC6 F2R KIT MDM2 PRKCZ PSD PSD3 PSD4
#subsets=
#subset_headers=
#index=
#uniques=
#defaults=
'
];

#print "\$exp = " . root->print_perl_var_def([ split( "\t", $return->AsTestString() ) ] )  . ";\n";
is_deeply( [ split( "\t", $return->AsTestString() ) ],
	$exp, "Pathway summary Pivot Table" );
$temp->define_subset( 'hyper_data', [ 'Gene_Symbol', 'pathway_name' ] );

$return = $temp->pivot_table(
	{
		'grouping_column' => 'kegg_pathway.id',
		'Sum_data_column' => 'hyper_data',
		'Sum_target_columns' =>
		  [ 'matched genes', 'pathway_name', 'Gene Symbols' ],
		'Suming_function' => sub {
			my $count        = 0;
			my $genes        = '';
			my $already_used = {};
			for ( my $i = 0 ; $i < @_ ; $i += 2 ) {
				next if ( defined $already_used->{ $_[$i] } );
				$already_used->{ $_[$i] } = 1;
				$count++;
				$genes .= $_[$i] . " ";
			}
			chop($genes);
			return $count, $_[1], $genes;
		  }
	}
);

#print "\$exp = " . root->print_perl_var_def([ split( "\t", $return->AsTestString() ) ] )  . ";\n";
$exp = [
	'#kegg_pathway.id', 'matched genes', 'pathway_name', 'Gene Symbols
104', '6', 'Bladder cancer', 'FIGF MDM2 MMP1 RPS6KA5 VEGFA VEGFC
105', '23', 'Cytokine-cytokine receptor interaction',
'BMPR2 CD70 CSF2RA CX3CL1 CXCL14 CXCL16 FIGF IL10RB IL1A IL1RAP IL24 IL9 IL9R KIT LTB PDGFB PDGFRB TGFB2 TNFRSF14 TNFRSF25 TNFSF4 VEGFA VEGFC
110', '10', 'Chemokine signaling pathway',
	'ADCY1 CX3CL1 CXCL14 CXCL16 GNAI1 GNG7 PRKCZ PRKX TIAM2 WASL
116', '9', 'Tight junction', 'CLDN23 EPB41 GNAI1 INADL MYL9 PRKCZ RRAS TJP3 YES1
122', '5', 'Small cell lung cancer', 'CDKN1B LAMA4 LAMB2 LAMB3 RARB
.
.
.
78', '18', 'MAPK signaling pathway',
'CACNA1H CACNG6 DUSP8 IL1A MAP2K5 MAP3K12 MAP4K1 MAPK8IP1 MKNK1 PDGFB PDGFRB PPM1B PRKX RASA1 RPS6KA5 RRAS STMN1 TGFB2
84', '18', 'Axon guidance',
'ABLIM2 EFNA1 EFNB3 EPHB6 GNAI1 NCK2 NRP1 NTN3 PLXNB1 PLXNC1 RASA1 RGS3 SEMA3F SEMA5B SEMA6A SEMA6B UNC5A UNC5B
90', '9', 'Purine metabolism',
	'ADCY1 AK5 AMPD3 PDE1B PDE6A PDE7A PDE9A PNPT1 PRUNE
91', '5', 'Adherens junction', 'IQGAP1 SNAI2 TCF7L1 WASL YES1
95', '8', 'Endocytosis',       'DNAJC6 F2R KIT MDM2 PRKCZ PSD PSD3 PSD4
#subsets=
#subset_headers=
#index=
#uniques=
#defaults=
'
];
is_deeply( [ split( "\t", $return->AsTestString() ) ],
	$exp, "Pathway summary Pivot Table repeate without rinse" );

#die $return -> AsString();write string format (front)

$value->plot_as_bar_graph(
	{
		'outfile'             => $plugin_path . "/data/output/test_figure",
		'title'               => "only a test",
		'y_title'             => "mean payment",
		'data_name_column'    => 'sex',
		'data_values_columns' => [ 'mean_payment', 'subjects' ],
		'x_res'               => 800,
		'y_res'               => 500,
		'x_border'            => 70,
		'y_border'            => 50
	}
);

$value = $data_table2->make_column_LaTeX_p_type( 'payment', '5cm' );
is_deeply( $value, '5cm', 'set a LaTeX p value' );
$value = $data_table2->AsLatexLongtable();
is_deeply(
	$value, '
\begin{longtable}{|c|p{5cm}|c|}
\hline
name & payment & sex\\\\
\hline
\hline
\endhead
\hline \multicolumn{3}{|r|}{{Continued on next page}} \\\\ 
\hline
\endfoot
\hline \hline
\endlastfoot
 A & 10 & m \\\\
 B & 6 & m \\\\
 C & 40 & w \\\\
 D & 30 & w \\\\
\end{longtable}

', 'And the p mode is printed right'
);

$value = $data_table2->LaTeX_modification_for_column(
	{
		'column_name' => 'payment',
		'before'      => 'before',
		'after'       => 'after'
	}
);
is_deeply(
	$value,
	{ 'before' => 'before', 'after' => 'after' },
	"LaTeX_modification_for_column"
);

$value = $data_table2->AsLatexLongtable();

is_deeply(
	$value, '
\begin{longtable}{|c|p{5cm}|c|}
\hline
name & payment & sex\\\\
\hline
\hline
\endhead
\hline \multicolumn{3}{|r|}{{Continued on next page}} \\\\ 
\hline
\endfoot
\hline \hline
\endlastfoot
 A & before10after & m \\\\
 B & before6after & m \\\\
 C & before40after & w \\\\
 D & before30after & w \\\\
\end{longtable}

', 'AsLatexLongtable after LaTeX_modification_for_column'
);

$name = data_table->new();
$name->parse_from_string(
	[ "#forename\tlastname\tgender", "stefan\tlang\tmale" ] );
my $mail = data_table->new();
$mail->parse_from_string(
	[
		"#forename\tlastname\temail", "stefan\tlang\tst.t.lang\@gmx.de",
		"stefan\tlang\tst.t.lang\@gmx.com"
	]
);
$name->merge_with_data_table($mail);
#print "\$exp = ".root->print_perl_var_def( [split( /[\t\n]/, $name->AsString())] ) .";\n";

$exp = [ '#forename', 'lastname', 'gender', 'email', 'stefan', 'lang', 'male', 'st.t.lang@gmx.de', 'stefan', 'lang', 'male', 'st.t.lang@gmx.com' ];

is_deeply(
	[split( /[\t\n]/, $name->AsString())],$exp,	"Merge two tables multiple lines #1"
);

$name = data_table->new();
$name->parse_from_string(
	[ "#forename\tlastname\tgender", "stefan\tlang\tmale", "\t\tmale" ] );
$mail = data_table->new();
$mail->parse_from_string(
	[
		"#forename\tlastname\temail",       "stefan\tlang\tst.t.lang\@gmx.de",
		"stefan\tlang\tst.t.lang\@gmx.com", "\t\ttest\@test.de",
		"\t\ttest\@fun.com"
	]
);
$name->merge_with_data_table($mail);
$name = $name -> Sort_by( [['email','lexical']] );
#print "\$exp = ".root->print_perl_var_def( [split( /[\t\n]/, $name->AsString())] ) .";\n";

$exp = [ 
'#forename', 	'lastname', 	'gender', 	'email', 
'stefan', 		'lang', 		'male', 	'st.t.lang@gmx.com', 
'stefan', 		'lang', 		'male', 	'st.t.lang@gmx.de', 
'', 			'', 			'male', 	'test@fun.com' ,
'', 			'', 			'male', 	'test@test.de', 
];

is_deeply(
	[ split( /[\n\t]/,$name->AsString() ) ],$exp,
	"Merge two tables multiple lines #2"
);
$name = data_table->new();
$name->string_separator('"');
$name->parse_from_string(
	[ "#forename\tlastname\tgender", "\"stefan\tlang\"\tlang\tmale" ] );

#print "\$exp = ".root->print_perl_var_def($name->{col_format} ).";\n";

ok( @{@{$name->{'data'}}[0]}[0] eq "stefan\tlang", "internal col sep in column 0" );

ok($name->__col_format_is_string(0), 'col format is string (0)' );

ok($name->string_separator() eq '"', "string separator is a \"");
is_deeply(
	$name->AsString(),
	"#forename\tlastname\tgender\n\"stefan\tlang\"\tlang\tmale\n",
	"write string format (front)"
);


$name = data_table->new(1);
$name->string_separator('"');
$name->parse_from_string(
	[
		"#some descirption", "#forename\tlastname\tgender",
		"stefan\t\"stefan\tlang\"\tmale"
	]
);
is_deeply(
	$name->AsString(),
"#some descirption\n#forename\tlastname\tgender\nstefan\t\"stefan\tlang\"\tmale\n",
	"write string format (middle)"
);

$mail = data_table->new();
$mail->string_separator('"');
$mail->parse_from_string(
	[
		"#some other description\n",
		"#forename\tlastname\tsex",
		"stefan\t\"stefan\tlang\"\t\"real\tsomething\""
	]
);
is_deeply(
	$mail->AsString(),
"#some other description\n#forename\tlastname\tsex\nstefan\t\"stefan\tlang\"\t\"real\tsomething\"\n",
	"write string format (rear)"
);
$name->merge_with_data_table($mail);
is_deeply(
	$name->AsString(),
"#some descirption\n#some other description\n#forename\tlastname\tgender\tsex\nstefan\t\"stefan\tlang\"\tmale\t\"real\tsomething\"\n",
	"Merge two tables multiple lines #3"
);
$name->define_subset( 'export', [ 'lastname', 'gender', 'sex' ] );
$mail = $name->GetAsObject('export');
is_deeply(
	$mail->AsString(),
"#some descirption\n#some other description\n#lastname\tgender\tsex\n\"stefan\tlang\"\tmale\t\"real\tsomething\"\n",
	"GetAsObject with string separator"
);

my $subset_text = data_table->new();
foreach ( 'A', 'B', 'C', ) {
	$subset_text->Add_2_Header("Column $_");
	$subset_text->define_subset( "column " . lc($_), ["Column $_"] );
}
$subset_text->AddDataset(
	{ "Column A" => 'A', 'Column B' => 'B', 'Column C' => 'C' } );
$subset_text->AddDataset(
	{ "column a" => 'a', 'column b' => 'b', 'column c' => 'c' } );
$subset_text->define_subset( 'AA AB', [ 'Column A', 'column b' ] );
#print "\$exp = "  . root->print_perl_var_def( [ split( "\t", $subset_text->AsTestString() ) ] )  . ";\n";
  
$exp = [ '1
#Column A', 'Column B', 'Column C
A', 'B', 'C
a', 'b', 'c
#subsets=AA AB;0;1', 'column a;0', 'column b;1', 'column c;2
#subset_headers=AA AB;Column A;column b', 'column a;Column A', 'column b;Column B', 'column c;Column C
#index=
#uniques=
#defaults=
' ];


is_deeply( [ split( "\t", $subset_text->AsTestString() ) ],
	$exp, 'Subset OK to add data' );
$subset_text->write_file($outpath.'Test_subsets.xls');
$subset_text->read_file($outpath.'Test_subsets.xls');
is_deeply( [ split( "\t", $subset_text->AsTestString() ) ],
	$exp, 'Subset after write/read cycle' );
## seams that the select_where function creates a problem here!
$subset_text =
  $subset_text->select_where( 'column a',
	sub { return 1 if ( $_[0] eq 'A' ); return 1; } )
  ;    ## does not change anything!
is_deeply( [ split( "\t", $subset_text->AsTestString() ) ],
	$exp, 'Subset after select_where selecting all lines' );

is_deeply(
	[ $subset_text->Header_Position(['Column A', 'Column B']) ],
	[ 0, 1 ],
	'get the location for a subset'
);

is_deeply(
	[ $subset_text->Header_Position(['Column A', 'column b']) ],
	[ 0, 1 ],
	'get the location for a alias column'
);
print $subset_text->AsTestString();
$subset_text = $subset_text->GetAsObject('AA AB');
print $subset_text->AsTestString();
$exp         = [
	'1',
	'#Column A', 'column b',
'A',         'B',
'a',         'b',
'#subsets=',
'#subset_headers=',
'#index=',
'#uniques=',
'#defaults=',
];
is_deeply( [ split( "[\t\n]", $subset_text->AsTestString() ) ],
	$exp, 'GetAsObject' );

$data_table2 = data_table->new();
$data_table2->Add_2_Header('position');
$data_table2->Add_2_Header('value');
$data_table2->{'data'} = [
	[ 50,   0.65 ],
	[ 100,  0.7645 ],
	[ 150,  3.867 ],
	[ 200,  3.9877 ],
	[ 250,  0.765 ],
	[ 300,  0.6543 ],
	[ 350,  2.9867 ],
	[ 900,  0.8675 ],
	[ 950,  0.543 ],
	[ 1000, 0.65223 ],
	[ 1050, 1.765 ],
	[ 1100, 4.873 ]
];

#print $data_table2->AsString();
$value = pdl(
	[ 50, 100, 150, 200, 250, 300, 350, 900, 950, 1000, 1050, 1100 ],
	[
		0.65,   0.7645, 3.867, 3.9877,  0.765, 0.6543,
		2.9867, 0.8675, 0.543, 0.65223, 1.765, 4.873
	]
);

print 'got:' . $data_table2->GetAsPDL(), print 'expected:' . $value;
print
"Sorry this is a visual test for you - do you see thesame information twice? - great!\n"

#print "\$exp = " . root->print_perl_var_def( $obj->GetAsArray('fold change') ) . ";\n";
