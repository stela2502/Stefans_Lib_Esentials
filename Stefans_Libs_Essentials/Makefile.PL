#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.

use inc::Module::Install;

name "Stefans_Libs_Essentials";
version_from "lib/Stefans_Libs_Essentials.pm";
author 'Stefan Lang <Stefan.Lang@med.lu.se>';

requires	'DBI'                     => 0;
requires		'Pod::Usage'			  => 0;
requires		'DateTime::Format::MySQL' => 0;
requires		'Digest::MD5'		  => 0;
requires		'Statistics::Descriptive' => 0;
requires		'Date::Simple'            => 0;
requires		'Number::Format'          => 0;
requires		'GD'                      => 0;
requires		'SVG'                     => 0;
requires	'GD::SVG'                 => '0.33';
requires		'PDL' => 0;

opendir( DIR, "bin/" ) or die "I could not open the bin folder\n$!\n";
map { install_script "bin/$_" } grep !/^\./,  grep '*.pl', readdir(DIR);
close ( DIR );


auto_install();
WriteAll;