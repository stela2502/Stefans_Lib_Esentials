package table_script_generator;

#  Copyright (C) 2008 Stefan Lang

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

use strict;
use warnings;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A class to help in the generation of import scripts from a database structure

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class table_script_generator.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {
		'variable_information' => {},
		'surrogates'           => {},
		'columnNames'          => [],
		'XML_strings'          => {
			'type'     => '<type>#</type>',
			'label'    => '<label>#</label>',
			'htmltype' => '<htmltype>labels</htmltype>'
		}
	};

	bless $self, $class if ( $class eq "table_script_generator" );

	return $self;

}

sub VariableInformation {
	my ( $self, $hash ) = @_;
	if ( defined $hash ) {
		Carp::confess(
			ref($self)
			  . ":Add_VariableInformation -> sorry, but we definitively need a hash to add!\n"
		) unless ( ref($hash) eq "HASH" );
		foreach my $key (%$hash) {
			$self->{variable_information}->{$key} = $hash->{$key};
		}
	}
	return $self->{variable_information};
}

sub Table_Structure {
	my ( $self, $table_struct ) = @_;
	if ( defined $table_struct ) {
		Carp::confess(
			ref($self)
			  . ":Add_VariableInformation -> sorry, but we definitively need a hash to add!\n"
		) unless ( ( ref($table_struct) eq "HASH" ) );
		foreach my $key (keys %$table_struct) {
			$self->{surrogates}->{$key} = $table_struct->{$key};
		}
	}
	return $self->{surrogates};
}

sub VariableNames {
	my ( $self, $names ) = @_;
	if ( defined $names ) {
		Carp::confess(
			ref($self)
			  . ":VariableNames -> sorry, but we definitively need an array of table names to add!\n"
		) unless ( ref($names) eq "ARRAY" );
		$self->{'columnNames'} = $names;
	}
	return $self->{'columnNames'};
}

sub Get_Add_to_GET_OPTIONS_string {
	my ($self) = @_;
	my $str = '';
	foreach ( @{ $self->VariableNames() } ) {
		$str .= "         \"-$_=s\"  => \\\$$_,\n";
	}
	return $str;
}

sub Get_READ_OPTIONS_string{
	my ( $self) = @_;
	my $str = '';
	foreach ( @{ $self->VariableNames() } ) {
		
		$str .= "if ( -f \"\$resorce_path/$_.dta\" ) { \n";
		
		if ( $self->VariableInformation()->{$_} ->{'file_upload'}){
			$str .= "       \$$_ = \"\$resorce_path/$_.dta\";\n";
		}
		else {
			$str .= "       open ( IN , \"<\$resorce_path/$_.dta\" );\n";
			$str .= "       foreach ( <IN> ){\n".
					"              chomp(\$_);\n".
					"              \$$_ = \$_;\n".
					"              last;\n".
					"       }\n".
					"       close ( IN );\n";
		}
		$str .= " }\n";
	}
	return $str;
}

sub Get_Add_to_Variable_Definition_String {
	my ($self) = @_;
	my $str = '';
	foreach my $var ( @{ $self->VariableNames() } ) {
		$str .= "\$$var, ";
	}
	chop($str);
	chop($str);
	return $str;
}

sub create_sampleTableHeader {
	my ( $self, $surrogate_tag ) = @_;
	$surrogate_tag ||= 'MASTER';
	my $str = '';

	foreach my $value_tag ( @{ $self->Table_Structure()->{$surrogate_tag} } ) {
		$str .= $value_tag . ";";
		if ( defined $self->Table_Structure()->{$value_tag} ) {
			$str .= $self->create_sampleTableHeader($value_tag);
		}
	}
	return $str;
}

sub getAddDatabaseDataset {
	my ( $self, $surrogate_tag, $firstEntry ) = @_;

	my $dataset = '{ ';
	
	$surrogate_tag ||= 'MASTER';

	if ( $surrogate_tag eq "MASTER" ) {
		$dataset = "my \$dataset = { \n";
	}
	
	if ( defined $firstEntry){
		$dataset .= $firstEntry."\n";
	}
	
	my $temp = '';
	my ($other_dataset);

	foreach my $value_tag ( @{ $self->Table_Structure()->{$surrogate_tag} } ) {

#print "getAddDatabaseDataset -> we try to do something with the value_tag $value_tag\n";
		## the dataset
		if ( defined $self->Table_Structure()->{$value_tag} ) {
			## OK we need to insert THIS value into the dataset AND the values for the uniqe key
			$temp = $self->VariableInformation()->{$value_tag}->{'name'};
			$temp =~ s/_id//;

			$dataset .= "'"
			  . $self->VariableInformation()->{$value_tag}->{'name'}
			  . "' => \$$value_tag,\n";
			## after that we have to add the other dataset:
			($other_dataset) = $self->getAddDatabaseDataset($value_tag, "\n'id' => \$$value_tag,");
			$dataset .= "'$temp' => " . $other_dataset . ",\n";
		}
		else {

			$dataset .= "'"
			  . $self->VariableInformation()->{$value_tag}->{'name'}
			  . "' => \$$value_tag,\n";

		}
	}
	$dataset .= '}';
	if ( $surrogate_tag eq "MASTER" ) {
		$dataset .= ";\n";
	}
	return ($dataset);
}

sub createHelpString {
	my ( $self, $surrogate_tag, $indention_level ) = @_;
	$surrogate_tag   ||= "MASTER";
	$indention_level ||= -2;
	$indention_level += 3;
	my $TAB = "      ";

	my ( @needed, @optional, @links, $downstream, $idention, @mainStr );
	$downstream = '';
	@mainStr    = ();
	$idention   = '';
	for ( my $i = 0 ; $i < $indention_level ; $i++ ) {
		$idention .= ' ';
	}

	#print "we have an $self->Table_Structure()->{$surrogate_tag}\n";
	foreach my $table_tag ( @{ $self->Table_Structure()->{$surrogate_tag} } ) {
		if ( $surrogate_tag eq "MASTER" ) {
			if ( ref( $self->Table_Structure()->{$table_tag} ) eq "ARRAY" ) {

				#push( @needed, $table_tag );
				push(
					@links,
					[
						$table_tag,
						$self->createHelpString( $table_tag, $indention_level )
					]
				);
			}
			else {
				push( @needed, $table_tag );
			}
		}
		else {
			push( @needed, $table_tag );
		}
	}
	push( @mainStr, $idention . "NEEDED values:\n" );

	foreach (@needed) {
		push( @mainStr,
			    $idention
			  . "-$_\n$idention$TAB"
			  . $self->VariableInformation()->{$_}->{'description'}
			  . "\n" );
	}
	if ( defined $links[0] ) {
		push( @mainStr, $idention . "LINKAGE variables:\n" );
		foreach (@links) {
			push( @mainStr,
				    $idention
				  . "-@$_[0]\n$idention$TAB"
				  . $self->VariableInformation()->{ @$_[0] }->{'description'}
				  . "\n" );
			push( @mainStr,
				    $idention 
				  . $TAB
				  . "If you do not know this value you should provide the following needed values\n"
			);
			push( @mainStr, @$_[1] );

			#delete( $self->VariableInformation()->{@$_[0]} );
		}

	}
	return join( "", @mainStr );
}

sub CheckRestrictions {
	my ( $self, $dbObj ) = @_;
	return '' unless ( defined $dbObj->{'restrictions'} );
	my $data = {};
	## we could do something here - but that would be useless...
	return $data;
}
sub __add_to_array {
	my ( $self, $key, $array ) = @_;
	
foreach my $columnName ( @{ $self->Table_Structure()->{$key} } ) {
			my $hash = {};
			$hash->{'name'} = $columnName;
			$hash->{'help'} = $self->VariableInformation()->{$columnName}->{'description'};
			$hash->{'pure_name'} = $self->VariableInformation()->{$columnName}->{'name'};
			$hash->{'htmltype'} = '';
			if (
				defined $self->VariableInformation()->{$columnName}
				->{'data_handler'} )
			{
				$hash->{'type'} = 'radio';
				$hash->{'dbObj'} =
				  $self->VariableInformation()->{$columnName}->{'tableObj'};
			}
			elsif ( defined $self->VariableInformation()->{$columnName}->{'file_upload'}){
				$hash->{'type'} = 'file';
			}
			elsif ( $self->VariableInformation()->{$columnName}->{'type'} =~
				m/VARCHAR *(\d+)/ )
			{
				$hash->{'atribute'} = [ { 'label' => 'maxlength','value' => $1} ];
				if (@{$hash->{'atribute'}}[0]->{'value'} < 41 ){
					$hash->{'type'} = 'text';
				}
				else{
					$hash->{'type'} = 'textarea';
				}
			}
			elsif ( $self->VariableInformation()->{$columnName}->{'type'} eq "TIMESTAMP" ) {
				next;
			}
			elsif ( $self->VariableInformation()->{$columnName}->{'type'} =~ m/CHAR *(\d*)/ ){
				my $length = $1;
				$length ||= 1;
				unless ( $length > 0){
					$length = 1;
				}
				$hash->{'type'} = 'text';
				$hash->{'atribute'} = [ { 'label' => 'maxlength','value' => $length} ];
			}
			elsif ( $self->VariableInformation()->{$columnName}->{'type'} =~
				m/TEXT/ )
			{
				$hash->{'type'} = 'textarea';
				$hash->{'atribute'} = [ { 'label' => 'maxlength','value' => 65535 } ];
			}
			else {
				warn "we do not know how to handle ".$self->VariableInformation()->{$columnName}->{'type'}." \n";
				next;
			}
			print "we added a XML dataset into the array\n";
			push ( @$array, $hash);
		}
		return 1;
}

sub CreateXML_formdef_Array {
	my ( $self ) = @_;
	my @array;

#	foreach my $key ( keys %{ $self->Table_Structure() } ) {
#		next if $key eq "MASTER";    ## that one comes last!
#		$self->__add_to_array ( $key, \@array);
#	}
	$self->__add_to_array ( "MASTER", \@array);
	
	return \@array;
}

=head2 printXML_GUI_FormDef

Atributes: The filename to print to and an array of hashes that describes the XML contents.
Contents of the hashes:
=over 2
 
=item type => one of [SELECT, OPTION (multi), RADIO (multi), SUBMIT, HIDDEN,
	FILE ,TEXTAREA, TEXT, CHECKBOX ]

=item name => the name of the valiable

=item label => the text that describes the form entry

=item htmltype => always 'labels'

=item datasource => OPTIONAL , I expect a fully equipped database object. We will create a DB query from that

=back

=cut

sub XML_required{
	my ( $self, $string ) = @_;
	return  '<rules>
    <item textcontent="'.$string.'" ruletype="required" authtype="client"></item>
   </rules>
  ';
}
sub XML_formsettings {
	my ( $self, $form_string ) = @_;
	return ' <formsettings>' . "\n" . $form_string . '  </formsettings>' . "\n";
}

sub XML_formitem {
	my ( $self, $formitem ) = @_;
	return '  <formitem>' . "\n" . $formitem . '</formitem>' . "\n";
}

sub XML_type {
	my ( $self, $type ) = @_;
	my @types = (
		'select',   'option', 'radio', 'submit', 'hidden', 'file',
		'textarea', 'text',   'checkbox'
	);
	my $use = 0;
	foreach (@types) {
		$use = 1 if lc( $type eq $_ );
	}
	Carp::confess( ref($self) . ":XML_type MYL type $type is not supported!\n" )
	  unless ($use);
	return '        <type>' . $type . '</type>'."\n";
}

sub XML_name{
	my ( $self, $name ) = @_;
	return '        <name>' . $name . '</name>'."\n";
}

sub XML_htmltype {
	return '        <htmltype>labels</htmltype>'."\n";
}

sub XML_DB_query {
	my ( $self, $dbObj ) = @_;
	unless ( ( ref($dbObj) =~ m/\w/ ) && $dbObj->isa('variable_table') ) {
		Carp::confess(
			ref($self)
			  . ":XML_DB_query if you wnt to get info from a table, you need to provide me with a dbObj\n"
		);
	}
	my $str = '       <datasource type="DB" execq="SELECT id, '
	  . join( ", ", @{$dbObj->{'UNIQUE_KEY'}} )
	  . " FROM "
	  . $dbObj->TableName()
	  . '"  dsnselection="mysql"></datasource>
     <fetchdata valuedata="id" text="'
	  . join( ",", @{$dbObj->{'UNIQUE_KEY'}} ) . '"></fetchdata>'."\n";
     
      print "XML_DB_query :\n$str";
    return $str;
        
}

sub XML_Atribues {
	my ( $self, $atributes ) = @_;
	my $str = '        <attribs>' . "\n";
	foreach (@$atributes) {
		$str .=
		    '               <item '.$_->{'label'}.'="'.
		  $_->{'value'}.'"'
		  . '></item>' . "\n";
	}
	$str .= '          </attribs>' . "\n";
	return $str;
}

sub XML_addClickableHelp {
	my ( $self, $helpStr, $label ) = @_;
	return '' unless ( defined $helpStr );
	return
	    '        <label spanclass="navibutton" javaonclickalert="' 
	  . $helpStr
	  . '" spancontent="?">'.$label.'</label>' . "\n";
}

sub XML_value {
	my ( $self, $value ) = @_;
	return '' unless ( defined $value );
	return '        <value type="single">' . $value . '</value>' . "\n";
}

sub printXML_GUI_FormDef {
	my ( $self, $filename, $xml_description ) = @_;
	
	unless ( defined $xml_description){
		$xml_description = $self->CreateXML_formdef_Array ( );
	}
	
	my $str = '<?xml version="1.0"?>
<!-- $Id: table_script_generator.pm,v 1.19 2011/04/08 09:26:49 stefan_l Exp $ -->


<settings>

 <globalsettings>
   <version>version 1</version>
   <author>Stefan Lang</author>
   <description>No Description available</description>
   <target></target>
 </globalsettings>
 	 <formsettings>
';
	
	my $formitem_str;
	warn "we need an array of values to define the XML file!\n" & return undef
	  unless ( ref($xml_description) eq "ARRAY" );

	foreach my $hash (@$xml_description) {
		print root::get_hashEntries_as_string($hash,2,"we got an XML definition:");
		$formitem_str = '';
		$formitem_str .= $self->XML_type( $hash->{'type'} );
		$formitem_str .= $self->XML_name( $hash->{'name'} );
		$formitem_str .= $self->XML_htmltype();
		$formitem_str .= $self->XML_addClickableHelp( $hash->{'help'} , $hash->{'pure_name'}) ;
		$formitem_str .= $self->XML_required( ' ' ) unless ( $self->VariableInformation()->{$hash->{'name'}}->{'NULL'});
		
		if ( defined $hash->{'dbObj'} ) {
			$formitem_str .=   $self->XML_DB_query( $hash->{'dbObj'} )	  
		}
		if ( ref( $hash->{'atributes'} ) eq "ARRAY" ) {
			$formitem_str .=  $self->XML_Atribues( $hash->{'atributes'} );
		}
		else {
			 $formitem_str .= $self->XML_Atribues(
					[{ 'label' => "class", 'value' => "formtext" }]
				  );
		}
		$str .= $self->XML_formitem ($formitem_str);
	}
	
	$str .= $self->XML_submittButton();
	$str .= " </formsettings>\n</settings>\n";

	if ( defined $filename ) {
		open( OUT, ">$filename" )
		  or Carp::confess("I could not create the file '$filename'\n$!\n");
		print OUT $str;
		close(OUT);
	}
	else {
		print $str;
	}
	return 1;
}


sub XML_submittButton{
	return '  <formitem>
   <type>submit</type>
   <name>SENDDATA</name>
   <label>Submit</label>
   <htmltype>labels</htmltype>
   <datasource></datasource>
   <fetchdata valuedata="" text=""></fetchdata>
   <displayorder></displayorder>
   <value type="single">1</value>
   <attribs>
    <item label="class" value="formtext"></item>
   </attribs>
   <rules>
    <item></item>
   </rules>
  </formitem>';
}

1;
