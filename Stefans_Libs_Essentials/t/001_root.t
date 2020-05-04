#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::root' }

use File::Spec::Functions;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $fn = catfile( $plugin_path, 'data', 'test.cef' );

my $fm = root->filemap($fn);

#print "\$exp = ".root->print_perl_var_def($fm ).";\n";
my $exp = {
  'filename' => 'test.cef',
  'filename_base' => 'test',
  'filename_core' => 'test',
  'filename_ext' => 'cef',
  'path' => "$plugin_path/data",
  'total' => $plugin_path.'/data/test.cef'
};

is_deeply( $exp, $fm, "filemap");

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
