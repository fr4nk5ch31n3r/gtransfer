% HALIAS(1) gtransfer 0.2.0 | User Commands
% Frank Scheiner
% Aug 22, 2013


# NAME #

halias - host alias helper utility


# SYNOPSIS #

**halias [OPTION] _STRING_**


# DESCRIPTION #

**halias** (host alias) is a small helper utility providing an interface to the
alias bashlib. It can be used to list or expand host aliases and also to check
if a given string is an alias. You can define system aliases and user aliases.
When dealiasing strings, user aliases take precedence over system aliases.


# OPTIONS #

The options are as follows:


## **-l, --list** ##

List all available host aliases. If a system alias and a user alias are
identical, only one of both is shown.
			

## **-d, --dealias _STRING_** ##

Expand a given string. If _STRING_ is not a host alias, then _STRING_ is just
printed to STDOUT.
		
			
## **-i, --is-alias _STRING_** ##

Check if a given string is a host alias. Returns 0 if yes, 1 otherwise.


General options:


## **[\--help]** ##

Prints out a help message.


## **[-V, \--version]** ##

Prints out version information.


# FILES #
       
       
## _[...]/halias.conf_ ##

The halias configuration file. The paths to system and user aliases directories
can be configured there.


## _[...]/aliases[/]_ ##

This file can be a directory or a regular file and contains the system aliases.


## _$HOME/.gtransfer/aliases[/]_ ##

This file can be a directory or a regular file and contains the user aliases.


# SEE ALSO #

**gtransfer(1)**

