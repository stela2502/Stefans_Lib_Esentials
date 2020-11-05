package stefans_libs::database::userTable::CatalystUser;

use strict;
use warnings;

use base qw/Catalyst::Authentication::User Class::Accessor::Fast/;

#  Copyright (C) 2011-04-12 Stefan Lang

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

BEGIN { __PACKAGE__->mk_accessors(qw/user/) }

use overload '""' => sub { shift->id }, fallback => 1;

sub new {
        my ( $class, $user ) = @_;

        return unless $user;

        bless { user => $user }, $class;
}

sub id {
    my $self = shift;
    return $self->user;
}

sub for_session {
    my $self = shift;
    return $self->id;
}


1;
