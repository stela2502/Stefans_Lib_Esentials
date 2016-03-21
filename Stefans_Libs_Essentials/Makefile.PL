#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.

use ExtUtils::MakeMaker;

opendir( DIR, "bin/" ) or die "I could not open the bin folder\n$!\n";

WriteMakefile(
	NAME         => "Stefans_Libs_Essentials",
	VERSION_FROM => "lib/Stefans_Libs_Essentials.pm",
	EXE_FILES    => [ map {"bin/$_" } grep !/^\./,  grep '*.pl', readdir(DIR) ],
	PREREQ_PM    => {
		'DBI'                     => 0,
		'DateTime::Format::MySQL' => 0,
		'Statistics::Descriptive' => 0,
		'Date::Simple'            => 0,
		'Number::Format'          => 0,
		'GD'                      => 0,
		'SVG'                     => 0,
		'GD::SVG'                 => '0.33',
		'PDL' => 0,
	  }

);
closedir(DIR);
