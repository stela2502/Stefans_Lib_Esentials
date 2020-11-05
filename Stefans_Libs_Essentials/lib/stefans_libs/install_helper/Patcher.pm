package stefans_libs::install_helper::Patcher;

#  Copyright (C) 2014-08-20 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::file_readers::Patcher

=head1 DESCRIPTION

This object helps to patch files - extremely simple

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs::file_readers::Patcher.

=cut

sub new {

	my ( $class, $filename ) = @_;
	$class = ref($class) if ( ref($class) );
	my ($self);

	$self = {
		'str_rep'  => '',
		'data'     => [],
		'filename' => '',
		'backtick' => [],
	};

	bless $self, $class if ( $class eq "stefans_libs::install_helper::Patcher" );
	$self->read_file($filename) if ( -f $filename );
	return $self;

}

sub print {
	my $self = shift;
	print $self->{'filename'}.":\n".$self->{'str_rep'};
	return $self;
}

sub revert {
	my ( $self, $drop ) = @_;
	$drop ||= 0;
	my $replacements = 0;
	my $d = pop( @{ $self->{'backtick'} } );
	return -1 unless ( ref($d) eq "ARRAY" );
	return $d if ($drop);
	if ( @$d[0] eq 'replace_string' && @$d > 2 ) {
		$replacements = $self->{'str_rep'} =~ s/@$d[1]/@$d[2]/g;
		if ($replacements) {
			$self->{'data'} = [ split( "\n", $self->{'str_rep'} ) ];
		}
	}
	elsif ( @$d[0] eq 'replace_inLine' ) {
		for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
			$replacements +=
			  @{ $self->{'data'} }[$i] =~ s/@$d[1]/@$d[2]/g;
		}
	}
	if ( $replacements ){
		$self->{'data'} = [ split( "\n", $self->{'str_rep'} ) ] if ( @$d[0] eq 'replace_string' );
		$self->{'str_rep'} = join( "\n", @{ $self->{'data'} } ) if ( @$d[0] eq 'replace_inLine' );
	}
	return $replacements;
}

sub replace_string {
	my ( $self, $target, $replacement ) = @_;
	my $replacements;
	if ( ref($replacement) eq "ARRAY" ) {
		push( @{ $self->{'backtick'} }, [ 'replace_string', 'not possible' ] );
		$replacements =
		  $self->{'str_rep'} =~ s/$target/@$replacement[0]$1@$replacement[1]/g;
	}
	else {
		push(
			@{ $self->{'backtick'} },
			[ 'replace_string', $replacement, $target ]
		);
		$replacements = $self->{'str_rep'} =~ s/$target/$replacement/g;
	}

	if ($replacements) {
		$self->{'data'} = [ split( "\n", $self->{'str_rep'} ) ];
	}
	else {
		$self->revert(1);
	}
	return $replacements;
}

sub replace_inLine {
	my ( $self, $target, $replacement ) = @_;
	my $replacements = 0;
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$replacements += @{ $self->{'data'} }[$i] =~ s/$target/$replacement/g;
	}

	if ($replacements) {
		push(
			@{ $self->{'backtick'} },
			[ 'replace_inLine', $replacement, $target ]
		);
		$self->{'str_rep'} = join( "\n", @{ $self->{'data'} } );
	}
	return $replacements;
}

sub read_file {
	my ( $self, $filename ) = @_;
	if ( -f $filename ) {
		open( IN, "<$filename" );
		while (<IN>) {
			$self->{'str_rep'} .= $_;
			chomp($_);
			push( @{ $self->{'data'} }, $_ );
		}
		close(IN);
		$self->{'filename'} = $filename;
	}
}

sub write_file {
	my ($self) = @_;
	$self->check_obj();
	open( OUT, ">$self->{'filename'}" ) or die $!;
	print OUT $self->{'str_rep'};
	close(OUT);
	return 1;
}

sub check_obj {
	my ($self) = @_;
	unless ( defined $self->{'filename'} ) {
		Carp::confess(
"Sorry I can not write to a undefined file - please read in a file before you patch and write one!"
		);
	}
}

1;
