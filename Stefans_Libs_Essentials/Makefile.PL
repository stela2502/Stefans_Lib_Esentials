#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.

use strict;
use warnings;

use lib 'lib';
use inc::Module::Install;

#use inc::Module::Install;
use Module::Install::Share;

name "Stefans_Libs_Essentials";
version_from "lib/Stefans_Libs_Essentials.pm";
perl_version '5.006';
author 'Stefan Lang <Stefan.Lang@med.lu.se>';

requires 'ExtUtils::MakeMaker' => '6.11';
requires 'Module::Install::Share' => 0;
requires 'HTML::TableExtract' => 0;
requires 'File::ShareDir' => 0;
requires 'File::HomeDir' => 0;
requires 'Date::Simple' => 0;
requires 'DBI'                     => 0;
requires 'Pod::Usage'			  => 0;
requires 'DateTime::Format::MySQL' => 0;
requires 'Digest::MD5'		  => 0;
requires 'Statistics::Descriptive' => 0;
requires 'Date::Simple'            => 0;
requires 'Number::Format'          => 0;
requires 'GD'                      => 0;
requires 'SVG'                     => 0;
requires 'GD::SVG'                 => '0.33';
requires 'Inline::C' => 0.62;
requires 'File::Copy::Recursive' => 0;
requires 'File::HomeDir' => 0;
requires 'PDL' => 0;
requires 'XML::Simple' => 0;
requires 'Spreadsheet::ParseExcel' => 0;

opendir( DIR, "bin/" ) or die "I could not open the bin folder\n$!\n";
map { install_script "bin/$_" } grep !/^\./,  grep '*.pl', readdir(DIR);
close ( DIR );

requires_external_bin('sqlite3');


install_share 'share';
#auto_install();

WriteAll();


