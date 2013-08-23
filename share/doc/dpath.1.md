% DPATH(1) gtransfer 0.2.0 | User Commands
% Frank Scheiner
% Aug 22, 2013


# NAME #

**dpath** - The dpath helper script


# SYNOPSIS #

**dpath \--create|-c _[/path/to/files]_
\--source|-s  _gsiftpSourceUrl_
\--destination|-d _gsiftpDestinationUrl_
\--alias|-a _alias_
\[--dpath-template _dpathTemplate_]
\[--configfile _configurationFile_]**

**dpath \--batch-create|-b _[/path/to/files]_
\--hosts|-h _hostsFile_
[\--dpath-template _dpathTemplate_]
[\--configfile _configurationFile_]**

**dpath \--list|-l _[/path/to/files]_
[\--verbose|-v]
[\--configfile _configurationFile_]**

**dpath \--retrieve|-r _[/path/to/files]_
[\--verbose|-v]
[\--configfile _configurationFile_]**

**dpath \--reindex _[/path/to/files]_
[\--verbose|-v]
[\--configfile _configurationFile_]**


# DESCRIPTION #

**dpath** is a helper script for **gtransfer(1)** to support users in creating
dpaths, listing available dpaths and retrieve the latest dpaths from a
preconfigured repository.


# MODES #

**dpath** has several modes of operation:

## **CREATE** ##
Creates a dpath file and a link to it named after the alias that is
specified by the user.

## **BATCH CREATE** ##
Creates all possible dpaths between host addresses given in a
file.  Corresponding aliases are created automatically.

## **LIST** ##
Lists all available dpaths. Additionally only sources and destinations
of dpaths can be listed, too.

## **RETRIEVE** ##
Retrieve the latest dpaths available. In this mode dpath updates
the local dpaths with data available from a preconfigured repository.

## **REINDEX** ##
Reindex all dpaths. In this mode dpath updates the sources and
destinations index files.


# OPTIONS #

The options are as follows:

**CREATE Mode:**


## **-c, \--create _[/path/to/files]_** ##

Create a new dpath either in the user-provided path or - if no additional path
is given - in the user dpaths directory in:

_$HOME/.gtransfer/dpaths_


## **-s, \--source _gsiftpSourceUrl_** ##

Set the source URL for the dpath without any path portion at the end.

Example:

gsiftp://saturn.milkyway.universe:2811


## **-d, \--destination|-d _gsiftpDestinationUrl_** ##

Set the destination URL for the dpath without any path portion at the end.

Example:

gsiftp://pluto.milkyway.universe:2811


## **-a, \--alias _alias_** ##

Set the alias for the created dpath. **dpath** will create a link named _alias_
to the dpath file which name is the SHA1 hash of the source destination
combination.

**NOTICE:** Naming of the aliases is not restricted, but it is recommended to
use something like the following:

"{{site|organization}\_{resource|hostName|FQDN}|Local}--to--{site|organization}\_{resource|hostName|FQDN}"


## **[\--dpath-template _dpathTemplate_]** ##

When provided, dpath will use the given template for dpath creation. The
following variables are expanded during dpath creation:

$sourceWithoutPath => gsiftpSourceUrl => the host address of the source site

$destinationWithoutPath => gsiftpDestinationUrl => the host address of the
destination site


**BATCH CREATE Mode:**


## **-b, \--batch-create _[/path/to/files]_** ##

Create dpaths in batch mode either in the user-provided path or - if no
additional path is given - in the user dpaths directory in:

$HOME/.gtransfer/dpaths

When used dpath will create dpaths for all possible connections between the
hosts given in the hostsFile and omit connections between the same hosts.


## **-h, --hosts _hostsFile_** ##

Set the file name for the file containing the host addresses for which dpaths
should be created. The format of each line in this file is as follows:

<PROTOCOL>://hostname.domain.tld:<PORT>

Example contents:

    gsiftp://gridftp.omicron.mercury:2811
    gsiftp://gridftp.gamma.mars:2812
    [...]


## **[\--dpath-template _dpathTemplate_]** ##

When provided, dpath will use the given template for dpath creation. The
following variables are expanded during dpath creation:

$sourceWithoutPath => gsiftpSourceUrl => the host address of the source site

$destinationWithoutPath => gsiftpDestinationUrl => the host address of the
destination site


**LIST Mode:**


## **-l, \--list _[/path/to/files]_ [-v, \--verbose]** ##

List all dpaths available in the user-provided path or - if no additional path
is given - in the user and system dpaths directories.


## **\--list-sources _[/path/to/dataPaths]_** ##

List all sources from the dpaths in the user provided path or - if no additional
path is given - in the user and system dpaths directories.


## **\--list-destinations _[/path/to/dataPaths]_** ##

List all destinations from the dpaths in the user provided path or - if no
additional path is given - in the user and system dpaths directories.


**RETRIEVE Mode:**


## **-r, \--retrieve _[/path/to/files]_ [-q, \--quiet]** ##

Retrieve the latest dpaths available on the preconfigured repository and store
them in the user-provided path or - if no additional path is given - in the user
dpaths directory. If a "--quiet|-q" is provided, then output is omitted and
success/failure is only reported by the exit value.


**REINDEX Mode:**


## **\--reindex _[/path/to/files]_** ##

Reindex all dpaths in the user provided path or - if no additional path is given
- in the user dpaths directory.


General options:

## **[\--configfile _configurationFile_]** ##

Set the name of the configuration file for dpath. If not set, this defaults to:

1. "/etc/gtransfer/dpath.conf" or
2. "<GTRANSFER_BASE_PATH>/etc/dpath.conf" or
3. "/etc/opt/gtransfer/dpath.conf" or
4. "$HOME/.gtransfer/dpath.conf" or
5. "$( dirname $BASH_SOURCE )/../etc" in this order.


## **[\--help]** ##

Prints out a help message.


## **[-V, \--version]** ##

Prints out version information.


# FILES #
       
       
## _[...]/dpath.conf_ ##

The dpath configuration file.


## _[...]/dpaths/_ ##

This dir contains the system dpaths usable by gtransfer and is configurable. Can
be created with **dpath**.


## _$HOME/.gtransfer/dpaths/_ ##

This dir contains the user dpaths usable by gtransfer. Can be created with
**dpath**.


## _[...]/dpaths/sources.index_ ##

These files (there can be a system one and a user one!) contain all source host
addresses available in the respective dpaths directories.


## _[...]/dpaths/destinations.index_ ##

These files (there can be a system one and a user one!) contain all destination
host addresses available in the respective dpaths directories.

The index files enable for faster lookup when used by gtransfer's bash
completion. Index files are automatically created and extended when creating
dpaths. The format of each line in these files is as follows:

\<PROTOCOL\>://hostname.domain.tld:\<PORT\>


# SEE ALSO #

**dpath(5)**, **sha1sum(1)**, **gtransfer(1)**

