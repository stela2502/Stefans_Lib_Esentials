#!/user/bin/perl -w

use stefans_libs::Version;
my $v = stefans_libs::Version->new();


my $dir = $v->table_file();
print "chmod +w $dir\n";
system("chmod +w $dir" );