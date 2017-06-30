package stefans_libs::Version;

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;

use stefans_libs::flexible_data_structures::data_table;

=head1 LICENCE

  Copyright (C) 2017-03-16 Stefan Lang

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

stefans_libs::Version

=head1 DESCRIPTION

A new lib named stefans_libs::Version.

=head2 depends on


=cut


=head1 METHODS

=head2 new ( $hash )

new returns a new object reference of the class stefans_libs::Version.
All entries of the hash will be copied into the objects hash - be careful t use that right!

=cut

sub new{

	my ( $class, $hash ) = @_;

	my ( $self );

	$self = {
  	};
  	foreach ( keys %{$hash} ) {
  		$self-> {$_} = $hash->{$_};
  	}

  	bless $self, $class  if ( $class eq "stefans_libs::Version" );

  	return $self;

}

sub _lib_path {
	my ( $self ) = @_;
	my $n= ref($self).".pm";
	$n =~s/::/\//g;
	my $h = \%INC;
	$n = $h->{$n};
	$n =~ s/Version.pm//;
	return $n;
}
sub table_file {
	my $self = shift;
	$self->{fname} ||= $self->_lib_path()."Versions.xls";
	warn "I am using the version file '$self->{fname}'\n";
	return $self->{fname};
}

sub file {
	my ( $self ) = @_;
	if ( ref($self->{'data_table'}) eq "data_table"){
		return $self->{'data_table'};
	}
	unless ( -f $self->table_file() ) {
		$self->{'data_table'} = data_table->new();
		$self->{'data_table'} ->Add_2_Header ( ['package','origin', 'version'] );
		return $self->{'data_table'};
	}else {
		$self->{'data_table'} = data_table->new({'filename' => $self->table_file() } );
		unless ( defined $self->{'data_table'}->Header_Position('package')) {
			$self->{'data_table'} ->Add_2_Header ( ['package','origin', 'version'] );
		}
		return $self->{'data_table'};
	}
}

sub save {
	my ( $self ) =@_;
	$self->{'data_table'} ->write_file( $self->table_file() );
}

sub record{
	my ( $self, $package, $path) = @_;
	open ( REF, "git -C $path rev-parse HEAD |" ) or Carp::confess("I could not recieve the git reference\n$!\n");
	my $ID = join("", <REF>);
	$ID =~ s/\n//g;
	close ( REF );
	my $orig;
	my $table = $self->file();
	my $id = $table->get_rowNumbers_4_columnName_and_Entry( 'package', $package) ;
	if ( defined $id ){
		$table->set_value_for('package', $package, 'version', $ID );
		return $self;
	}
	eval {
		warn "cd $path && git remote get-url --push $package \n";
		open ( REF, "cd $path && git remote get-url --push $package |") or Carp::confess("I could not recieve the git origin\n$!\n");
		$orig = join("", <REF>);
		$orig =~ s/\n//g;
		close ( REF );
		$table->AddDataset( {'package' => $package, 'version' => $ID , 'origin' => $orig} ) if ($orig =~ m/\w/ );
	};
	unless (defined $table->get_rowNumbers_4_columnName_and_Entry( 'package', $package) ) {
		eval {
			warn "cd $path && git remote get-url origin\n"; 
			open ( REF, "cd $path && git remote get-url origin |") or Carp::confess("I could not recieve the git origin\n$!\n");
			$orig = join("", <REF>);
			$orig =~ s/\n//g;
			close ( REF );
			$table->AddDataset( {'package' => $package, 'version' => $ID , 'origin' => $orig} ) if ($orig =~ m/\w/ );
		};
	}
	return $self;
}

sub version {
	my ( $self, $package ) = @_;
	my ($ret) = $self->file()->get_value_for( 'package', $package, 'version');
	return $ret;
}

sub origin {
	my ( $self, $package ) = @_;
	my ($ret) = $self->file()->get_value_for( 'package', $package, 'origin');
	return $ret;
}

1;
