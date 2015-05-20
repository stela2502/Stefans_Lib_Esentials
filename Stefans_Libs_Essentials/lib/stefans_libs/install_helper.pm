package stefans_libs::install_helper;
#  Copyright (C) 2015-02-13 Stefan Lang

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
use File::Copy;
use stefans_libs::install_helper::Patcher;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::install_helper

=head1 DESCRIPTION

A summary of some install helper scripts like a recursive copy with check of changes etc...

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs::install_helper.

=cut

sub new{

	my ( $class ) = @_;

	my ( $self );

	$self = {
		'patcher' => stefans_libs::install_helper::Patcher->new(),
  	};

  	bless $self, $class  if ( $class eq "stefans_libs::install_helper" );

  	return $self;

}

=head2 copy_files( $source_path, $target_path, $subpath, $do_not_update );

Copy files from one path to another if they do differ.
The hash $do_not_update = { 'file_to_ignore' => 1, 'path_to_ignred_file' => { 'file_to_ignore2' => 1} }
would keep the files $source_path/file_to_ignore and $source_path/path_to_ignred_file/file_to_ignore2 from being copied.

=cut

sub copy_files {
	my ($self, $source_path, $target_path, $subpath, $do_not_update) = @_;
	$do_not_update ||= {};
	$subpath ||= '';
	my (@return);
	$source_path = "$source_path/" unless ( $source_path =~m/\/$/ );
	$target_path = "$target_path/" unless ( $target_path =~m/\/$/ );

	opendir( DIR, "$source_path/$subpath" )
	  or Carp::confess( "could not open path '$source_path/$subpath'\n$!\n");
	my @contents = readdir(DIR);
	closedir(DIR);
	foreach my $file (@contents) {
		next if ( $file =~ m/^\./);
		if ( defined $do_not_update->{$file} ){
			unless ( ref($do_not_update->{$file}) eq "HASH"){
				next if ( -f $target_path . $subpath . "/$file" );
			}
		}
		if ( -d $source_path . $subpath . "/$file" ) {
			push(
				@return,
				$self -> copy_files(
					$source_path.$subpath, $target_path.$subpath,
					 "/$file", $do_not_update->{$file}
				)
			);
		}
		else { ## source is a file
			unless ( -d $target_path . $subpath ) {
				system( "mkdir -p " . $target_path . $subpath );
			}
			if ( -f $target_path . $subpath . "/$file" ){
				if ( ! $self->files_equal($source_path . $subpath . "/$file", $target_path . $subpath . "/$file" ) ){
					unlink ( $target_path . $subpath . "/$file" );
					copy(
				$source_path . $subpath . "/$file",
				$target_path . $subpath . "/$file"
			);
				}
				# else  do not update this file!
			}
			else { ## copy file
				copy(
				$source_path . $subpath . "/$file",
				$target_path . $subpath . "/$file"
			);
			}
			push( @return, $subpath . "/$file" );
		}
	}
	return @return;
}

sub files_equal {
	my ( $self, $file1, $file2 ) = @_;
	return ($self->file2md5str( $file1 ) eq $self->file2md5str( $file2 ));
}

sub file2md5str{
	my ($self, $filename ) = @_;
	my $md5_sum = 0;
	if ( -f $filename ){
		open ( FILE, "<$filename" );
		binmode FILE;
		my $ctx = Digest::MD5->new;
		$ctx->addfile (*FILE);
		$md5_sum = $ctx->b64digest;
		close (FILE);
	}else { 
		Carp::confess ( "Not a file '$filename'\n");
	}
	return $md5_sum;
}

1;
