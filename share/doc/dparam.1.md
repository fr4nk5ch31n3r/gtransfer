% DPARAM(1) gtransfer 0.2.0 | User Commands
% Frank Scheiner
% Aug 22, 2013


# NAME #

**dparam** - The dparam helper script


# SYNOPSIS #

**dparam \--create|-c _[/path/to/files]_ 
\--source|-s _gsiftpSourceUrl_ 
\--destination|-d _gsiftpDestinationUrl_
\--alias|-a _alias_ 
[\--configfile _configurationFile_]**

**dparam \--list|-l _[/path/to/files]_
[\--verbose|-v]
[\--configfile _configurationFile_]**

**dparam \--retrieve|-r _[/path/to/files]_
[\--quiet|-q]
[\--configfile _configurationFile_]**


# DESCRIPTION #

**dparam** is a helper script for **gtransfer(1)** to support users in creating
dparams, listing available dparams and retrieve the latest dparams from a
preconfigured repository.


# MODES #

**dparam** has several modes of operation:

## **CREATE** ##
Creates a dparam file and a link to it named after the alias that is specified
by the user.

## **LIST** ##
Lists all available dparams files.

## **RETRIEVE** ##
Retrieve the latest dparams available. In this mode **dparam** updates the local
dparams with data available from a preconfigured repository.


# OPTIONS #

The options are as follows:

**CREATE Mode:**


## **-c, \--create _[/path/to/files]_** ##

Create a new dparam either in the user-provided path or - if no additional path
is given - in the user dpaths directory in:

_$HOME/.gtransfer/dpaths_


## **-s, \--source _gsiftpSourceUrl_** ##

Set the source URL for the dparam without any path portion at the end.

Example:

gsiftp://saturn.milkyway.universe:2811


## **-d, \--destination|-d _gsiftpDestinationUrl_** ##

Set the destination URL for the dparam without any path portion at the end.

Example:

gsiftp://pluto.milkyway.universe:2811


## **-a, \--alias _alias_** ##

Set the alias for the created dparam. **dparam** will create a link named
_alias_ to the dparam file which name is the SHA1 hash of the source destination
combination.

**NOTICE:** Naming of the aliases is not restricted, but it is recommended to
use something like the following:

"{{site|organization}\_{resource|hostName|FQDN}|Local}--to--{site|organization}\_{resource|hostName|FQDN}"


**LIST Mode:**


## **-l, \--list _[/path/to/files]_ [-v, \--verbose]** ##

List all dparams available in the user-provided path or - if no additional path
is given - in the user and system dparams directories.


**RETRIEVE Mode:**


## **-r, \--retrieve _[/path/to/files]_ [-q, \--quiet]** ##

Retrieve the latest dparams available on the preconfigured repository and store
them in the user-provided path or - if no additional path is given - in the user
dparams directory. If a "--quiet|-q" is provided, then output is omitted and
success/failure is only reported by the exit value.


General options:

## **[\--configfile _configurationFile_]** ##

Set the name of the configuration file for dparam. If not set, this defaults to:

1. "/etc/gtransfer/dparam.conf" or
2. "<GTRANSFER_BASE_PATH>/etc/dparam.conf" or
3. "/etc/opt/gtransfer/dparam.conf" or
4. "$HOME/.gtransfer/dparam.conf" or
5. "$( dirname $BASH_SOURCE )/../etc" in this order.


## **[\--help]** ##

Prints out a help message.


## **[-V, \--version]** ##

Prints out version information.


# FILES #
       
       
## _[...]/dparam.conf_ ##

The dpath configuration file.


## _[...]/dparams/_ ##

This dir contains the system dpaths usable by gtransfer and is configurable. Can
be created with **dparam**.


## _$HOME/.gtransfer/dparams/_ ##

This dir contains the user dpaths usable by gtransfer. Can be created with
**dparam**.


# SEE ALSO #

**dparam(5)**, **sha1sum(1)**, **gtransfer(1)**



