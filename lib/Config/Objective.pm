
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved. 
###
###  Config::Objective - Perl module for parsing object-oriented config files
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


package Config::Objective;

use 5.006;
use strict;
use warnings;
#use overload;

use Parse::Lex;

use Config::Objective::DataType;
use Config::Objective::Parser;


our $VERSION = '0.5';
our $AUTOLOAD;


###############################################################################
###  internal functions for use by parser
###############################################################################

sub _lexer
{
	my ($parser) = @_;
	my ($token, $lexer);

	$lexer = $parser->YYData->{'lexer'};
#	print "lexer = $lexer\n";

	while (1)
	{
		$token = $lexer->next;

		if ($lexer->eoi)
		{
#			print "lexer returning EOI\n";
			return ('', undef);
		}

		next
			if ($token->name eq 'COMMENT');

#		print "lexer returning (" . $token->name . ", \"" . $token->text . "\")\n";
		return ($token->name, $token->text);
	}
}


sub _error
{
	my ($parser) = @_;
	my ($config, $lexer, $file, $line);

	$config = $parser->YYData->{'config'};
	$file = $config->{'file_stack'}->[-1];

	$lexer = $parser->YYData->{'lexer'};
	$line = $lexer->line;

	die("$file:$line: parse error\n");
}


sub _call_obj_method
{
	my ($self, $obj, $method, @args) = @_;
	my ($retval, $line, $msg);

	die "$obj: unknown config object"
		if (!exists($self->{'objs'}->{$obj}));

	$method = 'default'
		if (!defined($method));

	$retval = eval { $self->{'objs'}->{$obj}->$method(@args); };
	if ($@)
	{
		if (@{$self->{'lexer_stack'}})
		{
			$line = $self->{'lexer_stack'}->[-1]->line;
			$msg = "$self->{'file_stack'}->[-1]:$line: ";
		}
		$msg .= "$obj";
		die "$msg: $@";
	}

	return $retval;
}


###############################################################################
###  constructor
###############################################################################

sub new
{
	my ($class, $file, $objs, %opts) = @_;
	my ($self);

	$self = \%opts;
	bless($self, $class);

	$self->{'objs'} = $objs;
	$self->{'objs'} = {}
		if (!defined($self->{'objs'}));

	$self->{'include_dir'} = '.'
		if (!defined($self->{'include_dir'}));

	$self->{'file_stack'} = [];
	$self->{'cond_stack'} = [];
	$self->{'list_stack'} = [];
	$self->{'hash_stack'} = [];

	$self->parse($file);

	return $self;
}


###############################################################################
###  config parser
###############################################################################

sub parse
{
	my ($self, $file) = @_;
	my ($fh, $lexer, $parser);

#	print "==> parse('$file')\n";

	open($fh, $file)
		|| die "open($file): $!\n";
	push(@{$self->{'file_stack'}}, $file);

	$lexer = Parse::Lex->new(
		'AND',		'&&',
		'COMMA',	',',
		'COMMENT',	'(?<!\\$)#.*$',
		'ELIF',		'^\%[ \t]*elif',
		'ELSE',		'^\%[ \t]*else',
		'ENDIF',	'^\%[ \t]*endif',
		'EOS',		';',
		'EXPR_START',	'\(',
		'EXPR_END',	'\)',
		'HASH_ARROW',	'=>',
		'HASH_START',	'{',
		'HASH_END',	'}',
		'IF',		'^\%[ \t]*if',
		'INCLUDE',	'^\%[ \t]*include',
		'LIST_START',	'\[',
		'LIST_END',	'\]',
		'METHOD_ARROW',	'->',
		'OR',		'\|\|',
		'WORD',		'\w+',
		'QSTRING',	[ '"', '[^"]*', '"' ],
				sub {
					my ($token, $string) = @_;

					$string =~ s/^\"//;
					$string =~ s/\"$//;

					return $string;
				},
		'ERROR',	'(?s:.*)',
				sub {
					my $line = $_[0]->line;

					die "line $line: syntax error: \"$_[1]\"\n";
				}
	);
	$lexer->from(\*$fh);
	$lexer->configure('Skip' => '\s+');
	push(@{$self->{'lexer_stack'}}, $lexer);

	$parser = Config::Objective::Parser->new();
	$parser->YYData->{'lexer'} = $lexer;
	$parser->YYData->{'config'} = $self;

	$parser->YYParse(yylex => \&_lexer,
#			 yydebug => 0x1F,
			 yyerror => \&_error);

	pop(@{$self->{'file_stack'}});
	pop(@{$self->{'lexer_stack'}});
	close($fh);

#	print "<== parse('$file')\n";

	return 1;
}


###############################################################################
###  allow direct access to object values
###############################################################################

sub AUTOLOAD
{
	my ($self) = @_;
	my ($method);

	$method = $AUTOLOAD;
	$method =~ s/.*:://;

	return 
		if ($method eq 'DESTROY');

#	return (overload::Overloaded($self->{'objs'}->{$method})
#		? $self->{'objs'}->{$method}
#		: $self->{'objs'}->{$method}->get());

	return $self->{'objs'}->{$method}->get();
}


###############################################################################
###  return a config object
###############################################################################

sub get_obj
{
	my ($self, $obj) = @_;

	return $self->{'objs'}->{$obj};
}


###############################################################################
###  get a list of config object names
###############################################################################

sub obj_names
{
	my ($self) = @_;

	return keys %{$self->{'objs'}};
}


###############################################################################
###  get a hash of object names and values
###############################################################################

sub get_hash
{
	my ($self) = @_;
	my ($href);

	$href = {};
	map { $href->{$_} = $self->$_; } $self->obj_names();

	return $href;
}


###############################################################################
###  cleanup and documentation
###############################################################################

1;

__END__

=head1 NAME

Config::Objective - Perl module for parsing object-oriented config files

=head1 SYNOPSIS

  use Config::Objective;

  my $conf = Config::Objective->new('filename',
  		{
			'var1' => Config::Objective::Scalar->new(),
			'var2' => Config::Objective::List->new(),
			...
		},
		'include_dir'	=> '/usr/local/share/appname');

  print "var1 = \"" . $conf->var1 . "\"\n";

=head1 DESCRIPTION

The B<Config::Objective> module provides a mechanism for parsing
config files to manipulate configuration data.  Unlike most other
config file modules, which represent config data as simple variables,
B<Config::Objective> represents config data as perl objects.  This allows
for a much more flexible configuration language, since new classes can
be easily written to add methods to the config syntax.

The B<Config::Objective> class supports the following methods:

=over 4

=item new()

The constructor.  The first argument is the filename of the config file
to parse.  The second argument is a reference to a hash that maps names 
to configuration objects.

The remaining arguments are interpretted as a hash of attributes for
the object.  Currently, the only supported attribute is I<include_dir>,
which specifies the directory to search for include files (see L<File
Inclusion>).  If not specified, I<include_dir> defaults to ".".

=item I<object_name>

Once the constructor parses the config file, you can call the get()
method of any of the objects by using the object name as an autoloaded
method (see L<Recommended Methods>).

=item get_obj()

Returns a reference to the object of the specified object name.  The
object name is the first argument.

=item obj_names()

Returns a list of known object names.

=item get_hash()

Returns a hash where the keys are the known object names and the values
are the result of calling the get() method on the corresponding object.

=back

=head1 CONFIG FILE SYNTAX

The config file format supported by B<Config::Objective> is described
here.

=head2 Configuration Statements

Each statement in the config file results in calling a method on a
configuration object.  The syntax is:

  object[->method] [arg];

In this syntax, "object" is the name of the object.  The object must
be created and passed to the B<Config::Objective> constructor, as
described above.

The "->method" portion is optional.  If specified, it indicates which
method should be called on the object.  If not specified, a method called
default() will be used.

The "arg" portion is also optional.  It specifies an argument to pass to
the method.  It can be a simple scalar, list, hash, or a complex, nested
list or hash structure.  For example:

  all_word_characters
  "use quotes for non-word characters"
  [ this, is, a, list ]
  { this => 1, is => 2, a => 3, hash => 4 }
  { hash, values => are, optional }
  [ this, is, a, [ nested, list ] ]
  [ this, is, a, { hash, within, a, list } ]
  { "this is a" => [ list, within, a, hash ] }

So, putting this all together, here are some example configuration
statements:

  object_default_method_no_args;
  object_no_args->some_method;
  object_default_method scalar_arg;
  object [ list, for, args ];
  object_method_and_args->another_method { hash, for, args };

=head2 Conditional Evaluation

The config syntax also provides some rudementary support for conditional
evaluation.  A conditional directive is signalled by the use of a "%"
character at the beginning of a line (i.e., no leading whitespace).
There can be space between the "%" and the conditional directive,
however, which can improve readability when using nested conditional
blocks.

The conditional directives are I<%if>, I<%else>, I<%elif>, and I<%endif>.
They can be used to enclose other config statements, which are evaluated
or skipped based on whether the conditional expression evaluates to true.
For example:

  %if expression
    ... other config directives ...
  %endif

The most basic I<expression> is simply a method call that returns
a true or false value.  The syntax for this is the same as a normal
config statement, except without the trailing semicolon.  For example:

  %if object[->method] [arg]

If no method is specified, the equals() method will be called by
default.

Multiple expressions can be combined using the "&&" and "||" operators.
Parentheses can also be used for grouping.  For example:

  %if ( object1 foo && object2 bar ) || object3 baz

=head2 File Inclusion

File inclusion is another type of conditional evaluation.  It allows you
to include another file in the config file that is currently being
parsed, similar to the C preprocessor's "#include" directive.  The
syntax is:

  %include "filename"

If the specified filename is not an absolute path, B<Config::Objective>
will look for it in the directory specified by the I<include_dir>
attribute when the B<Config::Objective> object was created.

Note that the "%include" directive will be ignored within an "%if" block
whose condition is false.  This means that you cannot start an "%if"
block in one file, add a "%include" directive, and provide the "%endif"
directive in the included file.  All "%if" blocks must be fully
contained within the same file.

=head2 Comments

Any text between a "#" character and the next newline is considered a
comment.  The "#" character loses this special meaning if it is enclosed
in a quoted string or immediately preceded by a "\".

=head1 CONFIGURATION OBJECTS

This section explains the details of how configuration objects are
used.

=head2 Recommended Methods

There are no strict requirements for how a class must be designed in
order to be used for a configuration object.  The following methods are
recommended in that they will be used by B<Config::Objective> in certain
circumstances, but they do not need to be present if they are
not actually going to be used.

=over 4

=item get()

Return the value encapsulated by the object.  This is used when you use
call the variable name as a method of the B<Config::Objective> object.
For example:

  print "var1 = '" . $conf->var1 . "'\n";

This will implicitly call the get() method of the object named I<var1>.

=item default()

This is the default method used when a configuration file references an
object with no method.

=item equals()

This is the default method used when a configuration file references an
object with no method as part of an expression.  (See L<"Conditional
Evaluation"> above.)

=back

=head2 Supplied Object Classes

B<Config::Objective> supplies several classes that can be used for
encapsulating common configuration data.

=over 4

=item B<Config::Objective::DataType>

This is the base class for the rest of the supplied config object classes.
It should not be used directly, but does support the following methods
for use in subclasses:

=over 4

=item new()

The constructor.  It can be passed a hash to set the object's
attributes.  The object will be created as a reference to this hash.

=item get()

Returns the value encapsulated by the object.

=item set()

Sets the value encapsulated by the object to its argument.

=item default()

Calls the set() method.

=item equals()

Returns true if the argument equals the object's value (as determined by
the I<eq> operator; see the L<perlop> man page for details).

=item unset()

Sets the object's value to I<undef>.

=back

=item B<Config::Objective::Scalar>

This object encapsulates a scalar value.  It supports the following
methods:

=over 4

=item set()

Sets the object's value to its argument.  The value must be a scalar.

If the object was created with the I<value_abspath> attribute enabled,
the value must be an absolute path string.

If the object was created with the I<value_optional> attribute enabled,
the argument is optional; if missing, an empty string will be used
instead.

=item append()

Appends its argument to the object's value using string concatenation.

=back

=item B<Config::Objective::Boolean>

This object encapsulates a boolean value.  It supports the following
methods:

=over 4

=item set()

Sets the object's value to its argument.  The value must be one of the
following: "yes", "no", "on", "off", "true", "false", 1, or 0.

=back

=item B<Config::Objective::List>

This object encapsulates a list value.  It supports the following
methods:

=over 4

=item unset()

Sets the object's value to a reference to an empty list.

=item set()

Sets the object's value to its argument, which must be a reference to
a list.

=item add()

Appends its argument to the list.  The argument can be a scalar or a
reference to a list, in which case the referenced list's content is
added to the object's list.

=item default()

Calls the add() method.

=item add_top()

Same as add(), but adds to the front of the list instead of the end.

=item delete()

Deletes elements from the list that match its argument.  Matching is
performed by using the argument as a regular expression.  The argument
can be a scalar or a reference to a list, in which case each item of the
referenced list is used to check the values in the object's list.

=back

=item B<Config::Objective::Table>

This object encapsulates a table, which is represented as a list of lists.
Both rows and columns are indexed starting at 0.  It is derived from
the B<Config::Objective::List> class, but it supports the following
additional methods:

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

=item B<Config::Objective::Hash>

This object encapsulates a hash.  It supports the following methods:

=over 4

=item insert()

Inserts the specified values into the object's hash.  The argument must
be a reference to a hash, whose keys and values are copied into the
object's hash.

If the object was created with the I<value_optional> attribute enabled,
keys may be inserted with no defined values.

If the object was created with the I<value_type> attribute set to
either "ARRAY" or "HASH", then the hash values must be references to
the corresponding structure type.  If the values are lists, inserting a
new list with the same key will append the new list to the existing list.
If the values are hashes, inserting a new hash with the same key will
insert the new key/value pairs into the existing value hash.

If the object was created with the I<value_abspath> attribute enabled,
the hash values must be absolute path strings.

If the object was created with the I<key_abspath> attribute enabled, the
hash keys must be absolute path strings.

=item set()

The same as insert(), except that the existing hash is emptied before
inserting the new data.

=item unset()

Sets the object's value to an empty hash.

=item delete()

Deletes a specific hash key.  The argument can be a scalar or a
reference to a list, in which case all of the keys in the list are
deleted.

=back

=back

=head1 AUTHOR

Mark D. Roth E<lt>roth@uiuc.eduE<gt>

=head1 SEE ALSO

L<perl>.

=cut

