
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved.
###
###  test.pl - test harness for Config::Objective
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test;

# change 'tests => 1' to 'tests => last_test_to_print';
BEGIN { plan tests => 5 };

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


###############################################################################
###  Test 1: Module Initialization
###############################################################################

use Config::Objective;
ok(1);


###############################################################################
###  Test 2: Config Parsing
###############################################################################

$conf = Config::Objective->new('test.conf',
	{
		'null'		=> Config::Objective::Scalar->new(),
		'scalar'	=> Config::Objective::Scalar->new(),
		'scalar2'	=> Config::Objective::Scalar->new(),
		'qstring'	=> Config::Objective::Scalar->new(),
		'no_value'	=> Config::Objective::Scalar->new(
						'value_optional' => 1
					),
		'boolean'	=> Config::Objective::Boolean->new(),
		'empty_list'	=> Config::Objective::List->new(),
		'list'		=> Config::Objective::List->new(),
		'one_list'	=> Config::Objective::List->new(),
		'empty_hash'	=> Config::Objective::Hash->new(),
		'hash'		=> Config::Objective::Hash->new(),
		'hash2'		=> Config::Objective::Hash->new(),
		'key_only'	=> Config::Objective::Hash->new(
						'value_optional' => 1
					),
		'complex'	=> Config::Objective::List->new(),
		'hash_ol'	=> Config::Objective::Hash->new(
						'value_type' => 'ARRAY'
					),
		'hash_ul'	=> Config::Objective::Hash->new(
						'value_type' => 'HASH'
					),
		'sudo'		=> Config::Objective::Hash->new(
						'value_type' => 'HASH'
					),
		'var'		=> Config::Objective::List->new(),
		'keys_only'	=> Config::Objective::Hash->new(
						'value_optional' => 1
					)
	});
ok (defined($conf));

#use Data::Dumper;
#print Dumper($conf->values);


###############################################################################
###  Test 3: Data Retrieval
###############################################################################

$href = $conf->hash;
ok ($href->{'key'} eq 'value'
    && keys(%$href) == 1);


###############################################################################
###  Test 4: Specific Data Type Tests
###############################################################################

$hash_ul = $conf->hash_ul;
ok (ref($hash_ul->{'ul1'}) eq 'HASH'
    && exists($hash_ul->{'ul1'}->{'item1'})
    && exists($hash_ul->{'ul1'}->{'item2'})
    && exists($hash_ul->{'ul1'}->{'item3'})
    && exists($hash_ul->{'ul1'}->{'foo'})
    && exists($hash_ul->{'ul1'}->{'bar'})
    && exists($hash_ul->{'ul1'}->{'baz'}));


###############################################################################
###  Test 5: Conditional Evaluation Tests
###############################################################################

$key_only = $conf->key_only;
ok (ref($key_only) eq 'HASH'
    && scalar(keys %$key_only) == 1
    && exists($key_only->{'key'}));

