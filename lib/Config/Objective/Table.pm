
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved. 
###
###  Config::Objective::Table - table data type for Config::Objective
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


package Config::Objective::Table;

use strict;

use Config::Objective::List;

our @ISA = qw(Config::Objective::List);


###############################################################################
###  add_before method
###############################################################################

sub add_before
{
	my ($self, $value) = @_;
	my ($ct, $lref);

	die "add_before: method requires list argument\n"
		if (ref($value) ne 'ARRAY');

	die "add_before: invalid argument(s)\n"
		if (@{$value} != 3
		    || ref($value->[2]) ne 'ARRAY');

	for ($ct = 0; $ct < @{$self->{'value'}}; $ct++)
	{
		$lref = $self->{'value'}->[$ct];
		if ($lref->[$value->[0]] =~ m/$value->[1]/)
		{
			splice(@{$self->{'value'}}, $ct, 0, $value->[2]);
			return;
		}
	}
}


###############################################################################
###  find method
###############################################################################

sub find
{
	my ($self, $value) = @_;
	my ($row);

	die "find: method requires list argument\n"
		if (ref($value) ne 'ARRAY');

	die "find: invalid argument(s)\n"
		if (@{$value} != 2);

	foreach $row (@{$self->{'value'}})
	{
		if ($row->[$value->[0]] =~ m/\b$value->[1]\b/)
		{
			return $row;
		}
	}

	return undef;
}


###############################################################################
###  replace method
###############################################################################

sub replace
{
	my ($self, $value) = @_;
	my ($row);

	die "replace: method requires list argument\n"
		if (ref($value) ne 'ARRAY');

	die "replace: invalid argument(s)\n"
		if (@{$value} != 4);

	foreach $row (@{$self->{'value'}})
	{
		if ($row->[$value->[0]] =~ m/$value->[1]/)
		{
			$row->[$value->[2]] = $value->[3];
			return;
		}
	}
}


###############################################################################
###  modify method
###############################################################################

sub modify
{
	my ($self, $value) = @_;
	my ($row);

	die "modify: method requires list argument\n"
		if (ref($value) ne 'ARRAY');

	die "modify: invalid argument(s)\n"
		if (@{$value} != 4);

	foreach $row (@{$self->{'value'}})
	{
		if ($row->[$value->[0]] =~ m/$value->[1]/)
		{
			$row->[$value->[2]] .= ' '
				if ($row->[$value->[2]] ne '');
			$row->[$value->[2]] .= $value->[3];
			return;
		}
	}
}


###############################################################################
###  cleanup and documentation
###############################################################################

1;

__END__

=head1 NAME

Config::Objective::Table - table data type class for Config::Objective

=head1 SYNOPSIS

  use Config::Objective;
  use Config::Objective::Table;

  my $conf = Config::Objective->new('filename', {
			'tableobj'	=> Config::Objective::Table->new()
		});

=head1 DESCRIPTION

The B<Config::Objective::Table> module provides a class that represents a
table value in an object so that it can be used with B<Config::Objective>.
Its methods can be used to manipulate the encapsulated table value from
the config file.

The table data is represented as a list of lists.  Both rows
and columns are indexed starting at 0.  It is derived from the
B<Config::Objective::List> class, but it supports the following additional
methods:

=over 4

=item add_before()

Inserts a new row into the table before a specified row.  The argument
must be a reference to a list containing three elements: a number
indicating what column to search on, a string which is used as a regular
expression match to find a matching row in the table, and a reference
to the new list to be inserted before the matching row.

=item find()

Finds a row with a specified word in a specified column.  The column
number is the first argument, and the word to match on is the second.
It returns a reference to the matching row, or I<undef> if no matches
were found.

This function is not very useful for calling from a config file, but
it's sometimes useful to call it from perl once the config file has been
read.

=item replace()

Finds a row in the same manner as find(), and then replaces that row's
value in a specified column with a new value.  The arguments are the
column number to search on, the word to search for, the column number to
replace, and the text to replace it with.

=item modify()

Similar to replace(), but appends to the existing value instead of
replacing it.  A space character is appended before the new value.

=back

=head1 AUTHOR

Mark D. Roth E<lt>roth@uiuc.eduE<gt>

=head1 SEE ALSO

L<perl>

L<Config::Objective>

L<Config::Objective::List>

=cut

