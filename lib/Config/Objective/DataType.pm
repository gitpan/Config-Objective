
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved. 
###
###  Config::Objective::DataType - data types for Config::Objective
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


###############################################################################
###  base class for data types
###############################################################################

package Config::Objective::DataType;

use strict;

our $AUTOLOAD;


sub new
{
	my ($class, %opts) = @_;
	my ($self);

	$self = \%opts;

	$self->{'default_method'} = 'set'
		if (!exists($self->{'default_method'}));

	bless($self, $class);

	$self->unset();

	return $self;
}


sub get
{
	my ($self) = @_;

#	print "==> get(" . ref($self) . ")\n";

	return $self->{'value'};
}


sub set
{
	my ($self, $value) = @_;

#	print "==> set(\"$value\")\n";

	$self->{'value'} = $value;
	return 1;
}


sub equals
{
	my ($self, $value) = @_;

#	print "==> equals(" . ref($self) . ", '$value')\n";

	return ($self->{'value'} eq $value);
}


sub unset
{
	my ($self) = @_;

	$self->{'value'} = undef;
	return 1;
}


sub AUTOLOAD
{
	my ($self, @args) = @_;
	my ($method);

#	print "==> AUTOLOAD(" . ref($self) . "): ";

	$method = $AUTOLOAD;
	$method =~ s/.*:://;

#	print "$method(\"" . join('", "', @args) . "\")\n";

	return 
		if ($method eq 'DESTROY');

	$method = $self->{'default_method'}
		if ($method eq 'default');

#	print "can($method)\n"
#		if ($self->can($method));

	die "unknown method '$method'\n"
		if (! $self->can($method));

	return $self->$method(@args);
}


sub _scalar_or_list
{
	my ($self, $value) = @_;

	$value = [ $value ]
		if (! ref($value));

	die "method requires scalar or list argument\n"
		if (ref($value) ne 'ARRAY');

	return $value;
}


1;


###############################################################################
###  scalar data type
###############################################################################

package Config::Objective::Scalar;

use strict;

#use overload
#	'""'		=> 'get',
##	'0+'		=> 'get',
#	'+'		=> 'numeric_add',
#	'='		=> 'set',
#	'eq'		=> 'equals',
##	'fallback'	=> 1
#	;

our @ISA = qw(Config::Objective::DataType);


sub set
{
	my ($self, $value) = @_;

#	print "==> Scalar::set($value)\n";

	if (defined($value))
	{
		die "non-scalar value specified for scalar variable\n"
			if (ref($value));

		die "value must be absolute path\n"
			if ($self->{'value_abspath'}
			    && $value !~ m|^/|);
	}
	else
	{
		die "value required\n"
			if (! $self->{'value_optional'});
		$value = '';
	}

	return $self->SUPER::set($value);
}


sub append
{
	my ($self, $value) = @_;

	die "non-scalar value specified for scalar variable\n"
		if (defined($value) && ref($value));

	$self->{'value'} .= $value;

	return 1;
}


#sub numeric_add
#{
#	my ($self, $arg, $reversed) = @_;
#
##	print "==> numeric_add(" . ref($self) . ", '$arg', "
##	      . (defined($reversed)
##		 ? ($reversed
##		    ? 'TRUE'
##		    : 'FALSE')
##		 : 'undef') . ")\n";
#
#	return $arg + $self->{'value'};
##	return ($reversed
##		? $arg + $self->{'value'}
##		: $arg);
#}


1;


###############################################################################
###  boolean data type
###############################################################################

package Config::Objective::Boolean;

use strict;

#use overload
#	'bool'	=> \&get
#	;

our @ISA = qw(Config::Objective::DataType);


sub set
{
	my ($self, $value) = @_;

#	print "==> Boolean::set($value)\n";

	if (!defined($value)
	    || $value =~ m/^(yes|on|true|1)$/i)
	{
		$value = 1;
	}
	elsif ($value =~ m/^(no|off|false|0)$/i)
	{
		$value = 0;
	}
	else
	{
		die "non-boolean value '$value' specified for boolean variable\n";
	}

	return $self->SUPER::set($value);
}


1;


###############################################################################
###  list data type
###############################################################################

package Config::Objective::List;

use strict;

our @ISA = qw(Config::Objective::DataType);


sub new
{
	my ($class, %opts) = @_;
	my ($self);

	$opts{'default_method'} = 'add'
		if (!exists($opts{'default_method'}));

	return Config::Objective::DataType::new($class, %opts);
}


sub unset
{
	my ($self) = @_;

	$self->{'value'} = [];
	return 1;
}


sub set
{
	my ($self, $value) = @_;

#	print "==> List::set($value)\n";

	$self->unset();
	return $self->add($value);
}


sub add
{
	my ($self, $value) = @_;

	$value = $self->_scalar_or_list($value);
	$self->{'value'} = []
		if (!defined($self->{'value'}));
	push(@{$self->{'value'}}, @$value);

	return 1;
}


sub add_top
{
	my ($self, $value) = @_;

	$value = $self->_scalar_or_list($value);
	$self->{'value'} = []
		if (!defined($self->{'value'}));
	unshift(@{$self->{'value'}}, @$value);

	return 1;
}


sub delete
{
	my ($self, $value) = @_;
	my ($val);

	$value = $self->_scalar_or_list($value);
	$self->{'value'} = []
		if (!defined($self->{'value'}));
	foreach $val (@$value)
	{
		$self->{'value'} = grep !/$val/, @{$self->{'value'}};
	}

	return 1;
}


1;


###############################################################################
###  table data type
###############################################################################

package Config::Objective::Table;

use strict;

our @ISA = qw(Config::Objective::List);


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


1;


###############################################################################
###  hash data type
###############################################################################

package Config::Objective::Hash;

use strict;

our @ISA = qw(Config::Objective::DataType);


sub new
{
	my ($class, %opts) = @_;

	$opts{'default_method'} = 'insert'
		if (!exists($opts{'default_method'}));

	return Config::Objective::DataType::new($class, %opts);
}


sub unset
{
	my ($self) = @_;

	$self->{'value'} = {};
	return 1;
}


sub set
{
	my ($self, $value) = @_;

#	print "==> Hash::set($value)\n";

	$self->unset();
	return $self->insert($value);
}


sub insert
{
	my ($self, $value) = @_;
	my ($key1, $key2);

#	print "==> Hash::insert($value)\n";

	die "insert: method requires hash argument\n"
		if (ref($value) ne 'HASH');

	$self->{'value'} = {}
		if (!defined($self->{'value'}));

	foreach $key1 (keys %$value)
	{
		print "\t'$key1' => '$value->{$key1}'\n"
			if ($self->{'debug'});

		die "hash value missing\n"
			if (!$self->{'value_optional'}
			    && !defined($value->{$key1}));

		die "hash value is not a $self->{'value_type'}\n"
			if ($self->{'value_type'} ne ref($value->{$key1}));

		die "value must be an absolute path\n"
			if ($self->{'value_abspath'}
			    && $value->{$key1} !~ m|^/|);

		die "key must be an absolute path\n"
			if ($self->{'key_abspath'}
			    && $key1 !~ m|^/|);

		if (exists($self->{'value'}->{$key1}))
		{
#			print "key1='$key1'\n";
			if ($self->{'value_type'} eq 'HASH')
			{
#				print "key1={" . join(',', sort keys %{$self->{'value'}->{$key1}}) . "}\n";
				foreach $key2 (keys %{$value->{$key1}})
				{
#					print "\tkey2='$key2'\n";
					$self->{'value'}->{$key1}->{$key2} = $value->{$key1}->{$key2};
				}

#				print "'$key1' => { " . join(', ', sort keys %{$self->{'value'}->{$key1}}) . " }\n";
				next;
			}
			elsif ($self->{'value_type'} eq 'ARRAY')
			{
				push(@{$self->{'value'}->{$key1}}, @{$value->{$key1}});
				next;
			}
		}

		### overwrite the existing entry
		### or create a new one
		print "OVERRIDE: $value->{$key1}\n"
			if ($self->{'debug'});
		$self->{'value'}->{$key1} = $value->{$key1};
	}

	return 1;
}


sub delete
{
	my ($self, $value) = @_;
	my ($val);

	$value = $self->_scalar_or_list($value);
	foreach $val (@$value)
	{
		delete $self->{'value'}->{$val};
	}

	return 1;
}


1;


