% GTRANSFER(1) gtransfer 0.2.0 | User Commands
% Frank Scheiner
% Aug 19, 2013


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

###Optimized data transfer performance ###
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

**[-s, \--source _sourceUrl_]**
:   Set the source URL for the transfer.

    Possible URL examples:

    {[gsi]ftp|http[s]}://FQDN[:PORT]/path/to/file

    [file://]/path/to/file

    "FQDN" is the fully qualified domain name.

**[-d, \--destination _destinationUrl_]**
:   Set the destination URL for the transfer.

    Possible URL examples:

    [gsi]ftp://FQDN[:PORT]/path/to/file

    [file://]/path/to/file

    "FQDN" is the fully qualified domain name.

**[-f, \--transfer-list _transferList_]**
:   As alternative to providing source and destination URLs on the command line,
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

