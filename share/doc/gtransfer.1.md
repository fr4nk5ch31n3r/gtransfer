% GTRANSFER(1) gtransfer 0.2.0 | User Commands
% Frank Scheiner
% Aug 22, 2013


# NAME #

gtransfer - The GridFTP transfer script


# SYNOPSIS #

**{gtransfer|gt} [\--source|-s _sourceUrl_] 
[\--destination|-d _destinationUrl_] 
[\--transfer-list|-f _transferList_] 
[\--auto-optimize|-o _transferMode_] 
[\--guc-max-retries _gucMaxRetries_] 
[\--gt-max-retries _gtMaxRetries_] 
[\--gt-progress-indicator _indicatorCharacter_] 
[\--verbose|-v] 
[\--metric|-m _dataPathMetric_] 
[\--logfile|-l _logfile_] 
[\--auto-clean|-a] 
[\--configfile _configurationFile_] 
[\-- _gucParameters_]**


# DESCRIPTION #
**gtransfer** is a wrapper script for the **tgftp(1)** tool and provides an
advanced command line interface for performing GridFTP transfers.

**gtransfer** has the following features:

## Multi-step data transfers ##
It can transfer files along predefined paths by using transit sites and can
therefore bridge different network domains.

## Optimized data transfer performance ##
It supports usage of pre-optimized data transfer parameters for specific
connections. Therefore this tool is also helpful for single step transfers. In
addition **gtransfer** can also automatically optimize a data transfer depending
on the size of the files.

## Data transfer interruption and continuation ##
It supports interruption and continuation of transfers. You can interrupt a
transfer by hitting `CTRL+C`. To continue an interrupted transfer simply issue
the very same command, **gtransfer** will then continue the transfer where it
was interrupted. The same procedure works for a failed transfer.

## Data transfer reliability ##
It supports automatic retries of failed transfer steps. The number of retries is
configurable.

## Bash completion ##
It makes use of bash completion to ease usage. This supports completion of
options and URLs. URL completion also expands (remote) paths. Just hit the `TAB`
key to see what's possible.

# OPTIONS #

The options are as follows:


## **[-s, \--source _sourceUrl_]** ##

Set the source URL for the transfer.

Possible URL examples:

* {[gsi]ftp|http[s]}://FQDN[:PORT]/path/to/file
* [file://]/path/to/file

"FQDN" is the fully qualified domain name.


## **[-d, \--destination _destinationUrl_]** ##

Set the destination URL for the transfer.

Possible URL examples:

* [gsi]ftp://FQDN[:PORT]/path/to/file
* [file://]/path/to/file

"FQDN" is the fully qualified domain name.


## **[-f, \--transfer-list _transferList_]** ##

As alternative to providing source and destination URLs on the command line,
one can also provide a list of source and destination URLs in a transfer
list; **gtransfer** will then perform a _list transfer_ instead of an _URL 
transfer_ when using source and destination URLs.

The format of each line of the transfer list file is as follows (including
the double quotes!):

"\<PROTOCOL\>://\<FQDN1\>:\<PORT\>/path/to/file" 
"\<PROTOCOL\>://\<FQDN2\>:\<PORT\>/path/to/file[s/]"

Throughout all lines the source URL host part (e.g.
"\<PROTOCOL\>://\<FQDN1\>:\<PORT\>") has to be identical. This is also
required for the destination URL host part.


## **[-o, \--auto-optimize _transferMode_]** ##

This option activates an automatic optimization of transfers depending on the
size of files to be transferred. If less than 100 files are  going to be
transferred, gtransfer will fall back to URL or list transfer depending on
command line options. The _transferMode_ controls how files of different size
classes are transferred. Currently "seq[uential]" (different size classes are
transferred sequentially) is possible. To define different file size classes use
the file _[...]/chunkConfig_. See **FILES** section below for more details.


## **[\--guc-max-retries _gucMaxRetries_]** ##

This option sets the maximum number of retries globus-url-copy (guc) will do for
a transfer of a single file. By default this is set to 1, which means that guc
will tolerate at max. one transfer error per file and retry the transfer once.
Alternatively this option can also be set through the environment variable
**GUC_MAX_RETRIES**.


## **[\--gt-max-retries _gtMaxRetries_]** ##

This  option sets the maximum number of retries gt will do for a single transfer
step. By default this is set to 3, which means that gt will try to finish a
single transfer step three times or fail. Alternatively  this option can also be
set through the environment variable **GT_MAX_RETRIES**.


## **[-v, \--verbose]** ##

Be verbose.


## **[-m, \--metric _dataPathMetric_]** ##

Set the metric to select the corresponding path of a data path.


## **[-l, \--logfile _logfile_]** ##

Set the name for the logfile, tgftp will generate for each transfer. If
specified with ".log" as extension, gtransfer will insert a "\_\_step_#" string to
the name of the logfile ("#" is the number of the transfer step performed). If
omitted gtransfer will automatically generate a name for the logfile(s).


## **[-a, \--auto-clean]** ##

Remove logfiles automatically after the transfer completed.


## **[\--configfile _configurationFile_]** ##

Set the name of the configuration file for gtransfer. If not set, this defaults
to:

1. _/etc/gtransfer/gtransfer.conf_ or
2. _\<GTRANSFER_BASE_PATH\>/etc/gtransfer.conf_ or
3. _/etc/opt/gtransfer/gtransfer.conf_ or
4. _$HOME/.gtransfer/gtransfer.conf_ in this order.


## **[\-- _gucParameters_]** ##

Set the **globus-url-copy(1)** parameters that should be used for all transfer
steps. Notice the space between "--" and the actual parameters. This overwrites
any available default parameters and is not recommended for regular usage. There
exists one exception for the `-len|-partial-length X` option. If this is
provided, it will only be added to the default parameters for a connection or -
if no default parameters are availble - to the builtin default parameters.

**NOTICE:** If specified, this option must be the last one in a gtransfer
command line.


General options:


## **[\--help]** ##

Prints out a help message.


## **[-V, \--version]** ##

Prints out version information.


# FILES #
       
## _[...]/gtransfer.conf_ ##

The gtransfer configuration file.


## _[...]/chunkConfig_ ##

The chunk configuration file. In this file you can define the different file
size classes for the auto-optimization. Practically the file is a table with
three columns: **MIN_SIZE_IN_MB**, **MAX_SIZE_IN_MB** and **GUC_PARAMETERS**
separated by a semicolon.

Each line defines a size class. The value for MIN_SIZE_IN_MB is not included in
the class. The value for **MAX_SIZE_IN_MB** is included in the class. Use the
keyword "min" in the column **MIN_SIZE_IN_MB** to default to the size of the
smallest file available in a transfer list. Files of this size will be included
in this class then. Use the keyword "max" in the column **MAX_SIZE_IN_MB** to
default to the size of the biggest file available in a transfer list. The third
column **GUC_PARAMETERS** defines the transfer parameters to use for the
specific file size class.

Example:

    #  MIN_SIZE_IN_MB;MAX_SIZE_IN_MB;GUC_PARAMETERS
    min;50;-cc 16 -tcp-bs 4M -stripe -sbs 4M -cd
    50;250;-cc 8 -tcp-bs 8M -stripe -sbs 4M -cd
    250;max;-cc 6 -p 4 -tcp-bs 8M -stripe -sbs 8M -g2 -cd


## _[...]/dpaths/_ ##

This directory contains the system dpaths usable by gtransfer and is
configurable.


## _[...]/dparams/_ ##

This directory contains the system dparams usable by gtransfer and is
configurable.


## _$HOME/.gtransfer/dpaths/_ ##

This directory contains the user dpaths usable by gtransfer. Can be created with
dpath. If existing, dpaths in this directory have precedence.


## _$HOME/.gtransfer/dparams/_ ##

This directory contains the user dparams usable by gtransfer. Can be created
with dparam. If existing, dparams in this directory have precedence.


# SEE ALSO #

**dpath(5)** , **dparam(5)**, **tgftp(1)**, **uberftp(1C)**

