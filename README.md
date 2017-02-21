# Stefans_Lib_Esentials
My small historical, probably superficial perl extensions consisting of a tab table interface data_table.pm, a (MySQL) database interface built up on DBI::DBD (varibale_table.pm) and a LaTeX creation lib.

This software is meant to be used by me so the documentation is far from complete. It is required by the SCexV server and therefore you got access to it ;-)

# Install

mkdir ~/Software
cd ~/Software

git clone git@github.com:stela2502/Stefans_Lib_Esentials.git

cd Stefans_Lib_Esentials/Stefans_Lib_Esentials/

make
make install

The make test will fail as the test scripts need update - I am sorry.

# Usage

Most inforamtion about the usage of the lib is hidden in the test scripts (directory t).

# Some key lib features:

## data_table

The data table is a very flexible but complicated table object. Oh and it is horribly documented - too ;-)

## stefans_libs::Latex_Document

A simple LaTeX document generation tool that allows adding of text, figures, data_table objects and of cause sections.

## variable_table

An extremely old database interface, that has a nice auto search for columns.


# Some key script features:

## The convert_R* scripts

They that helped me a lot to move my S3 R libraries to S4 status (RFclust.SGE and StefansExpressionSet).


## binCreate.pl

This script is a script creator, that creates a script that uses Getopt::Long::GetOptions to parse command line options and creates a ../t/xx_<script name>.t test script that can help in the implementation of the script.

## bib_create.pl

This script creates perl lib files and has been used for all my libs. It also creates test scripts for all lib files, but is way less developed that the binCreate.pl script.

