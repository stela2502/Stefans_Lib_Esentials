#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok 'stefans_libs::plot::color' }
use GD;
use stefans_libs::root;
use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value,@values,$tmp,$exp);

my $color = color->new(GD::Image->new(10,10));

#print "\$exp = ".root->print_perl_var_def( {%$color} ).";\n";
$exp = {
  'pastel_blue' => '18',
  'yellow' => '26',
  'dark_purple' => '8',
  'light_green' => '13',
  'light_orange' => '14',
  'rosa' => '22',
  'yellowgreen' => '27',
  'tuerkies1' => '23',
  'red' => '21',
  'uniqueColor' => '1',
  'maxColorIndex' => '27',
  'dark_green' => '6',
  'dark_grey' => '7',
  'light_purple' => '15',
  'pastel_yellow' => '19',
  'blau2' => '2',
  'im' => 'hidden',
  'ultra_pastel_yellow' => '25',
  'dark_yellow' => '9',
  'grey' => '11',
  'ultra_pastel_blue' => '24',
  'black' => '1',
  'dark_blue' => '5',
  'light_blue' => '12',
  'order' =>  [ 'black', 'blau2', 'blue', 'brown', 'dark_blue', 'dark_green', 'dark_grey', 'dark_purple', 'dark_yellow', 'green', 'grey', 'light_blue', 'light_green', 'light_orange', 'light_purple', 'light_yelow', 'orange', 'pastel_blue', 'pastel_yellow', 'purple', 'red', 'rosa', 'tuerkies1', 'ultra_pastel_blue', 'ultra_pastel_yellow', 'white', 'yellow', 'yellowgreen' ],
  'brown' => '4',
  'white' => '0',
  'IL7_difference' => '1',
  'purple' => '20',
  'light_yelow' => '16',
  'green' => '10',
  'nextColor' => '-1',
  'orange' => '17',
  'blue' => '3'
};
$value = {%$color};
$value->{im} = 'hidden';
is_deeply ( $value, $exp, "color object as expected" );

$color = color->new(GD::Image->new(10,10), 'white', $plugin_path."/data/rainbow_4.cols" );
#print "\$exp = ".root->print_perl_var_def( {%$color} ).";\n";
$exp = {
  'order' => [ '#FF0000FF', '#80FF00FF', '#00FFFFFF', '#8000FFFF', 'white', 'black' ],
  'white' => '0',
  '#80FF00FF' => '2',
  '#8000FFFF' => '4',
  'IL7_difference' => '1',
  'nextColor' => '-1',
  'black' => '5',
  'maxColorIndex' => '5',
  'uniqueColor' => '1',
  'im' => 'hidden',
  '#00FFFFFF' => '3',
  '#FF0000FF' => '1'
};
$value = {%$color};
$value->{im} = 'hidden';
is_deeply ( $value, $exp, "color object as expected" );
@values = ();
for ( my $i = 0; $i < 6; $i ++ ){
	$values[$i] = $color->getNextColor();
}
$exp = [ 1,2,3,4,0,5 ];
is_deeply ( \@values, $exp, "The colors are returned in the expected order");

#print "\$exp = ".root->print_perl_var_def( [$value->GetAsHash( 'groupID', 'cellName' )] ).";\n";