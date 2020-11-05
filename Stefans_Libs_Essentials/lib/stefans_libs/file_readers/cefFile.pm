package stefans_libs::file_readers::cefFile;
#  Copyright (C) 2015-10-16 Stefan Lang

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

use stefans_libs::flexible_data_structures::data_table;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::file_readers::cefFile

=head1 DESCRIPTION

Read and manipulate the cef file format for single cell data https://github.com/linnarsson-lab/ceftools

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs::file_readers::cefFile.

=cut

sub new{

	my ( $class, $debug ) = @_;

	my ( $self );
	
	$self = {
		'debug' => $debug,
		'samples' => data_table->new( {'no_doubble_cross' => 1}),
		'annotation' => data_table->new({'no_doubble_cross' => 1}),
		'data' => data_table->new({'no_doubble_cross' => 1}),
		'headers' => [],
		'header_hash' => {},
  	};
  	
	if ( ref($debug) eq "HASH") {
		$self->{'config'} = $debug;
		$self->{'debug'} = $debug->{'debug'};
	}

  	bless $self, $class  if ( $class eq "stefans_libs::file_readers::cefFile" );

  	return $self;

}

sub __add{
	my ( $self, $file, $where ) = @_;
	if ( -f $file ) {
		$self->{$where}->read_file($file);
	}elsif ( ref($file) eq "data_table" ){
		$file->{'no_doubble_cross'} = 1;
		$self->{$where} = $file;
	}
	return $self;
}
sub compose {
	my ( $self, $samples, $annotation, $data ) = @_;
	$self->__add( $samples, 'samples');
	$self->__add( $annotation, 'annotation');
	$self->__add( $data, 'data');
	
	## do the colnames of the data match exactly to one sample annoatation column?
	my $match_to = join(" ", @{$self->{data}->{'header'}}[1..(@{$self->{data}->{'header'}}-1)] );
	my $match = 0;
	my $err = '';
	print "samples\n" if ( $self->{'debug'});
	foreach ( @{$self->{samples}->{'header'}}) {
		print "cmp $match_to\n to ".join(" ", @{$self->{samples}->GetAsArray($_)} )."\n\n" if ( $self->{'debug'});
		$match = 1 if (join(" ", @{$self->{samples}->GetAsArray($_)} ) eq $match_to );
	}
	$err .= "ERROR: data colnames could not be matched to the samples data!\n" unless ( $match );
	$match_to = join(" ", @{$self->{data}->GetAsArray(@{$self->{data}->{'header'}}[0])} );
	$match = 0;
	if ( $self->{annotation}->Columns == 0 ){
		$self->{annotation}->add_column (@{$self->{data}->{'header'}}[0], @{$self->{samples}->GetAsArray($_)});
	}else {
		print "Annotation\n" if ( $self->{'debug'});
		foreach ( @{$self->{annotation}->{'header'}}) {
			print "cmp $match_to\n to ".join(" ", @{$self->{annotation}->GetAsArray($_)})."\n'$_'\n\n" if ( $self->{'debug'});
			$match = 1 if (join(" ", @{$self->{annotation}->GetAsArray($_)} ) eq $match_to );
		}
		$err .= "ERROR: data names could not be matched aginast an annotation column!\n" unless ( $match );
	}
	die $err if( $err =~ m/\w/ );
	
	$self->{'data'} = $self->{'data'}->drop_column( @{$self->{'data'}->{'header'}}[0] );
	$err = $self->{'data'}->{'header'};
	for ( my $i = 0; $i < $self->{'data'}->Columns(); $i ++ ){
		$self->{'data'}->rename_column( @$err[$i], 'Col_'.($i+1) );
	} 
	return $self;
}

sub add_2_header {
	my ( $self, $key, $value ) = @_;
	unless ( defined $self->{'header_hash'}->{$key} ){
		$self->{'header_hash'}->{$key} = $value;
		push ( @{$self->{'headers'}}, [ $key, $value] );
	}
	return $self;
}

sub read_file{
	my ( $self, $infile, $samplesCol ) = @_;
	Carp::confess ( "This object can only contain one file\n") if ( $self->{'data'}->Rows() > 0  );
	Carp::confess ( 'Lib error: file $infile not found' ) unless ( -f $infile );
	$samplesCol ||= 'Samples';
	open (IN, "<$infile" ) or Carp::confess( "$!\n" );
	sub rline {my $self = shift; my $line = <IN>; Carp::confess ( "Premature end of file". $self->AsString() ) unless( defined $line);return  map{ chomp(); split("\t",$_) } $line; };
	my ( $fid, $headers, $nrow_atr, $ncol_atr, $nrow, $ncol, $unused ) = &rline();
	my (@line, $last_col);
	$last_col = $nrow_atr+$ncol;
	for ( my $i = 0; $i < $headers; $i++){
		@line= $self->rline();
		push(@{$self->{'headers'}}, [@line]);
		$self->{'header_hash'} -> {$line[0]} = $line[1];
	}
	$self->{'samples'}->init_rows($ncol);
	for ( my $i = 0; $i < $ncol_atr; $i++){
		@line = $self->rline();
		$self->{'samples'}->add_column( @line[$nrow_atr..$last_col]);	
	}
	Carp::confess ( "Read failed - the samples column '$samplesCol' could not be identified in the data(!):\n".join("\n", @{$self->{'samples'}->{'header'}})."\n") unless ( defined $self->{'samples'}->Header_Position( $samplesCol ));
	## the gene level annotation headers
	@line= $self->rline();
	$self->{'annotation'}->Add_2_Header( [@line[0..$nrow_atr-1]] );
	$self->{'data'}->Add_2_Header( [ map{ "Col_$_" } 1..$ncol ]);

	for ( my $i = 0; $i < $nrow; $i++){
		@line= $self->rline();
		push(@{$self->{annotation}->{'data'}},  [@line[0..$nrow_atr-1]] );
		push(@{$self->{data}->{'data'}},  [@line[$nrow_atr+1..$last_col]] );
	}
	#die "\$exp = ".root->print_perl_var_def( $self->{'header_hash'} ).";\n";
	return $self;
}

sub AsString {
	my ( $self ) = @_;
	unless ( @{$self->{'headers'}} > 0 ){
		Carp::confess ( "Header values are not defined" );
	}
	my ( $headers, $nrow_atr, $ncol_atr, $nrow, $ncol ) = (  scalar(@{$self->{'headers'}}), $self->{'annotation'}->Columns(), $self->{'samples'}->Columns(), $self->{'data'}->Rows(),
		$self->{'data'}->Columns() );
	my $str = join( "\t",
		"CEF",$headers , $nrow_atr, $ncol_atr, $nrow, $ncol, 0 )."\n";
	foreach ( @{$self->{'headers'}} ) {
		$str .= join("\t",@$_)."\n";
	}
	my $tabs = join("", map { "\t" } 1..$nrow_atr );
	for ( my $i = 0; $i < $ncol_atr; $i ++ ){
		$str .= $tabs.@{$self->{'samples'}->{'header'}}[$i]."\t".join("\t", @{$self->{'samples'}->GetAsArray(@{$self->{'samples'}->{'header'}}[$i])})."\n";
	}
	my @annotation = split("\n", $self->{'annotation'}->AsString() );
	my @data = split("\n", $self->{'data'}->AsString() );
	$str .= $annotation[0]."\n";
	for( my $i = 1; $i < @annotation; $i ++ ){
		$str .= $annotation[$i]."\t\t".$data[$i]."\n";
	}
	return $str;
}

sub write_file{
	my ( $self, $fname ) = @_;
	
	open ( OUT, ">$fname" ) or die $!;
	print OUT $self->AsString();
	close ( OUT );
	return $self;
}

sub export {
	my ( $self, $data, $options ) = @_;
	Carp::confess ( "Lib error: data table '$data' not existing") unless ( ref($self->{$data}) eq "data_table" );
	my $error = '';
	my $str ='';
	if ( $data eq "data" ) {
		$error .= "I need a column name option('colnames') for the data table that is part of the samples table" unless ( defined $self->{'samples'}->Header_Position($options->{'colnames'}));
		$error .= "I need a row name option('rownames') for the data table that is part of the samples table" unless ( defined $self->{'annotation'}->Header_Position($options->{'rownames'}));
		Carp::confess ( $error ) if ( $error =~ m/\w/ );
		#my @str = split("\n", $self->{'data'}->AsString() );
		$options->{'rownames_id'} =  $self->{'annotation'}->Header_Position($options->{'rownames'});
		$str.=join("\t",$options->{'rownames'}, @{$self->{'samples'}->GetAsArray($options->{'colnames'}) } )."\n";
		for ( my $i = 0; $i < $self->{'data'}->Lines(); $i ++ ){
			$str.= join("\t",@{@{$self->{'annotation'}->{'data'}}[$i]}[$options->{'rownames_id'}], @{@{$self->{'data'}->{'data'}}[$i]} ) ."\n";
		}
		
	}else {
		$str = $self->{$data}->AsString();
	}
	if ( defined $options->{'fname'} ) {
		open (OUT, ">$options->{'fname'}" ) or die $!;
		print OUT $str;
		close ( OUT );
	}
	return $str;
}

1;
