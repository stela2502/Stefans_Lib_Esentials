package stefans_libs::flexible_data_structures::optionsFile;

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
#created by bib_create.pl from  commit 
use strict;
use warnings;

=head1 LICENCE

  Copyright (C) 2017-06-26 Stefan Lang

  This program is free software; you can redistribute it 
  and/or modify it under the terms of the GNU General Public License 
  as published by the Free Software Foundation; 
  either version 3 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License 
  along with this program; if not, see <http://www.gnu.org/licenses/>.


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::flexible_data_structures::optionsFile

=head1 DESCRIPTION

A SIMPLE hash -> value file with a set of required and optional keys initially used in my SLURM.pm library

=head2 depends on


=cut


=head1 METHODS

=head2 new ( {
	'default_file' => <file string>,
	'required' => [ required keys ], 
	'optional => [ optional keys]' 
} )

new returns a new object reference of the class stefans_libs::flexible_data_structures::optionsFile.
All entries of the hash will be copied into the objects hash - be careful t use that right!

=cut

sub new{

	my ( $class, $hash ) = @_;

	my ( $self );

	$self = {
		'default_file' => undef,
  	};
  	foreach ( keys %{$hash} ) {
  		$self-> {$_} = $hash->{$_};
  	}

  	bless $self, $class  if ( $class eq "stefans_libs::flexible_data_structures::optionsFile" );
	$self->{error} = '';
	foreach ( 'default_file', 'required', 'optional' ){
		$self->{error} .= "key $_ is missing in ".ref($self)."->new( \$hash )\n" unless ( defined $self->{$_});
	}
	Carp::confess ( $self->{'error'} ) if ( $self->{'error'} =~ m/\w/ );

  	return $self;

}

sub add{
	my ( $self, $key, $value, $force ) = @_;
	return $self unless ( defined $key );
	$force ||= 1;
	$self->{'data'}  ||= {};
	return $self if ( defined $self->{'data'}->{$key} and ! $force );
	$self->{'data'}->{$key} = $value;
	return $self;
}

sub drop{
	my ( $self, $key ) =@_;
	delete( $self->{'data'}->{$key}) if ( defined $self->{'data'}->{$key});
	return $self;
}

sub value{
	my ( $self, $key) = @_;
	return $self->{data}->{$key};
}


=head3 load(fname)
This function checks a default file containing the options:
that contains a simple table with
<key>\t<value> combinations
You can give this function an other fname if you want to read from an other file.
=cut
sub load{
	my ( $self, $fname, $die ) = @_;
	unless ( defined $die ) {
		$die = 1;
	}
	unless (defined $fname ) {
		$fname = $self->{'default_file'};
	}else {
		$self->{'default_file'} = $fname;
	}
	unless ( -f $fname ) {
		$self->{'data'} = {};
		$self->save($fname);
		Carp::confess ( "Please fill in the default options file '$fname'\n") if ( $die );
	}
	open ( IN, "<$fname" ) or die $!;
	$self->{'data'} = {};
	my @tmp;
	my $i = 0;
	while( <IN> ) {
		$i ++;
		next if ( $_ =~m/^#/ );
		chomp;
		@tmp = split("\t",$_);
		if ( $self->{'data'}->{$tmp[0]} ){
			warn "replacing the double option '$tmp[0]' on line $i ('$self->{'data'}->{$tmp[0]}' -> '$tmp[1]')\n";
		}
		$self->{'data'}->{$tmp[0]} = $tmp[1];
	}
	close ( IN );
	return $self;
}

sub AsString{
	my ($self) = @_;
	my $str = "## required:\n";
	foreach ( @{$self->{'required'}} ) {
		if ( $self->{'data'}->{$_}) {
			$str .=  "$_\t$self->{'data'}->{$_}\n";
		}else {
			$str .=  "$_\tchange me\n";
		}
	}
	$str .=  "## optional:\n";
	foreach ( @{$self->{'optional'}} ) {
		if ( $self->{'data'}->{$_}) {
			$str .= "$_\t$self->{'data'}->{$_}\n";
		}else {
			$str .=  "#$_\tchange me or comment me out\n";
		}
	}
	return $str;
}

sub save{
	my ( $self, $fname ) = @_;
	$fname = $self->{'default_file'} unless ( defined $fname );
	open (OUT , ">$fname") or die "I could not create the SLURM opts store '$fname'\n$!\n";
	print OUT  $self->AsString();
	close ( OUT );
	return $self;
}

sub options {
	my ( $self ) = @_;
	unless ( defined $self->{'data'} ) {
		$self->load();
	}
	return $self->{'data'};
}

=head3 check ( array )

Checks whether a set of keys are in the internal data.
Dies if any of them is missing!

=head3 OK ( array )

If array is length(0) it uses the required set of keys.

Checks whether a set of keys are in the internal data.
Returns 0 if any of them are missing ($self->{error} contains the error message)

=cut

sub OK {
	my ( $self, @require ) = @_;
	$self->{error} = '';
	@require = @{$self->{'required'}} if ( @require == 0);
	map {
		unless ( defined $self->{'data'}->{$_} ) { $self->{error} .= "MISSING option $_\n" }
	} @require;
	return $self->{error} eq '';
}

sub check {
	my ( $self, @require ) = @_;
	unless ($self->OK( @require )){
		Carp::confess($self->{error});
	}
}

1;
