
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved.
###
###  Makefile.PL - configuration rules for Config::Objective
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


use ExtUtils::MakeMaker;


sub MY::postamble
{
	return '
lib/Config/Objective/Parser.pm: grammar.yp
	yapp -m Config::Objective::Parser grammar.yp && mv Parser.pm lib/Config/Objective/Parser.pm

';
}


WriteMakefile(
	'NAME'		=> 'Config::Objective',
	'DISTNAME'	=> 'Config-Objective',
	'VERSION_FROM'	=> 'lib/Config/Objective.pm',
	'PREREQ_PM'	=> {
				Parse::Lex		=> 2.15,
				Parse::Yapp::Driver	=> 1.05
			   },
	'PM'		=> {
				'lib/Config/Objective.pm'
					=> '$(INST_LIB)/Config/Objective.pm',
				'lib/Config/Objective/DataType.pm'
					=> '$(INST_LIB)/Config/Objective/DataType.pm',
				'lib/Config/Objective/Parser.pm'
					=> '$(INST_LIB)/Config/Objective/Parser.pm'
			   },
	'clean'		=> {
				FILES => 'lib/Config/Objective/Parser.pm'
			   },
	'MAN3PODS'	=> {
				'lib/Config/Objective.pm'
					=> '$(INST_MAN3DIR)/Config::Objective.3'
			   },
	## Add these new keywords supported since 5.005
	($] >= 5.005 ? (
	'ABSTRACT_FROM'	=> 'lib/Config/Objective.pm',
	'AUTHOR'	=> 'Mark D. Roth <roth@uiuc.edu>')
	: ()),
);

