#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 19;
BEGIN { use_ok 'stefans_libs::plot::simpleBarGraph' }

use FindBin;
my $plugin_path = "$FindBin::Bin";


&test_4_type('svg');
&test_4_type('png');


sub test_4_type {
	my ($type) = @_;
	my $exp_class;
	if ( $type eq "png" ) {
		$exp_class = "GD";
	}
	if ( $type eq "svg" ) {
		$exp_class = "GD::SVG";
	}
	my $barGraph = simpleBarGraph->new();
	is_deeply( ref($barGraph), 'simpleBarGraph', 'could get the object' );
	my $im = $barGraph->_createPicture(
		{ 'x_res' => 600, 'y_res' => 400, 'type' => $type } );
	is_deeply( ref($im), $exp_class . "::Image", "we get an Image object" );
	is_deeply( ref( $barGraph->{color} ),
		"color", "and the color object was created correctly" );
	is_deeply( ref( $barGraph->{font} ),"Font", "and the color object was created correctly" );
#	is_deeply(ref( $barGraph->{font}->{largeFont} ),$exp_class . '::Font',"The right font object");
	warn  "In the test script check which ttf file is used!\n". $barGraph->{font}->{fontName} ;
	my $test_data = {
		'name' => 'NHD',
		'data' => {
			'A/A' => { 'y' => 2,   'std' => 0.3 },
			'A/B' => { 'y' => 2.3, 'std' => 0.2 },
			'B/B' => { 'y' => 1.9, 'std' => 0.2 },
		},
		'order_array'  => [ 'A/A', 'A/B', 'B/B' ],
		'color'        => $barGraph->{color}->{'green'},
		'border_color' => $barGraph->{color}->{'green'}
	};
	is_deeply( $barGraph->AddDataset($test_data),
		1, "it seams as if we could add a dataset" );
	$test_data = {
		'name' => 'T2D',
		'data' => {
			'A/A' => { 'y' => 1.9, 'std' => 0.2 },
			'A/B' => { 'y' => 1.4, 'std' => 0.4 },
			'B/B' => { 'y' => 2.4, 'std' => 0.5 }
		},
		'order_array'  => [ 'A/A', 'A/B', 'B/B' ],
		'color'        => $barGraph->{color}->{'blue'},
		'border_color' => $barGraph->{color}->{'blue'}
	};

	is_deeply( $barGraph->AddDataset($test_data),
		1, "it seams as if we could add a dataset (2)" );
	is_deeply(
		$barGraph->Ytitle('mean test expression'),
		'mean test expression',
		'we have set the Y title'
	);
	is_deeply(
		$barGraph->Xtitle('genotype of rs1234567'),
		'genotype of rs1234567',
		'we have set the X title'
	);
	my $ofile = $plugin_path . '/data/output/test_bar_graph.' . $type;
	unlink($ofile) if ( -f $ofile );

	$barGraph->plot(
		{
			'x_res'   => 600,
			'y_res'   => 400,
			'outfile' => $plugin_path . '/data/output/test_bar_graph',
			'x_min'   => 50,
			'x_max'   => 550,
			'y_min'   => 20,                                             # oben
			'y_max'   => 340,                                            # unten
			'mode'    => 'landscape',
		}
	);
	
	ok ( -f  $ofile ,"Figure file '$ofile' created");
	
}

