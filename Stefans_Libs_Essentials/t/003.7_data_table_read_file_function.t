#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
use PDL;

use FindBin;
my $plugin_path = "$FindBin::Bin";
my $outpath = $plugin_path."/data/output/";

BEGIN { use_ok 'stefans_libs::flexible_data_structures::data_table' }

my ( $value, @values, $exp, $data_table, $data_table2 );

## I have an issue with the default value!


my $infile = $plugin_path."/data/processed_gtf_file.xls";

ok ( -f $infile, "infile present" );
my $chr = 'chr1';
my $filter = sub {
	my ( $self, $array, $i ) = @_;
	#print "I got the line:".join(" ", @$array)."\n";
	return @$array[0] eq $self->{'chr'};
};

$data_table = data_table->new();

$data_table->read_file($infile, 10 ); ## read the first 10 lines

$exp = [qw(chr1	HAVANA	transcript	161513176	161605099)];
is_deeply( $data_table->Lines() , 10 ,"The right line count (10 ==". $data_table->Lines().")" );
is_deeply( [@{@{$data_table->{'data'}}[9]}[0..4] ], $exp, "the old number of lines");

$data_table = data_table->new();
$data_table->{'chr'} = $chr;
$data_table->read_file($infile, $filter ); ## read the first 10 lines

$exp = [qw(chr1	MANUAL	gene	248873854	248873961)];
ok( $data_table->Lines() == 15, "chr1 == 15 lines (".$data_table->Lines().")" );
is_deeply( [@{@{$data_table->{'data'}}[14]}[0..4] ], $exp, "the right chr1 data");




