#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'Stefans_Libs_Essentials';
all_from 'lib/Stefans_Libs_Essentials.pm';


requires_external_bin('make');
requires_external_bin( "pdflatex");

requires 'DBI';
requires 'DateTime::Format::MySQL';
requires 'Statistics::Descriptive';
requires 'Date::Simple';
requires 'Number::Format';
requires 'GD::SVG';

catalyst;

install_script glob('bin/*.pl');
auto_install;
WriteAll;
