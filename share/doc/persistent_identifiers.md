# Persistent identifiers #

* [Introduction](#introduction)
* [Support for PIDs in gtransfer](#support-for-pids-in-gtransfer)
    * [Examples](#examples)
        * [Single PID](#single-pid)
        * [Multiple PIDs with a PID file](#multiple-pids-with-a-pid-file)
        * [PID file](#pid-file)
* [Internals](#internals)
    * [Example mapping file](#example-mapping-file)
    * [Resolving a PID file](#resolving-a-pid-file)
* [Requirements](#requirements)
* [Limitations](#limitations)

## Introduction ##

Files located on a service (for example on a GridFTP service) can be accessed
via a URL. The URL could be:

`gsiftp://gridftp.domain1.tld1:2811/path/to/files/*`

Imagine the data in one of that files - let's call it `file1` - is used by
scientists around the world. The URL of that specific file is:

`gsiftp://gridftp.domain1.tld1:2811/path/to/files/file1`

Now for some reason that file is moved to a different service with a different
FQDN and in addition also a different access protocol (e.g. HTTPS). So the old
URL is no longer valid to access this specific file. The new URL is:

`https://www.domain2.tld2:443/different/path/to/file1`

Due to this change all scientists would have to be informed about the new
location and URL of the file they are working with. And if they are working with
scripts and tools that include the old URL hard-coded somewhere they will also
have to change these, too.

A better approach would be to use a _persistent_ URL, which will stay the same
even if the file that it is pointing to moves to a different location or is 
duplicated to a second storage system. 
And this is what persistent identifiers (PIDs) are there for. They
add an additional level of abstraction which allows the file(s) they are
pointing to, to move to a different location and still be found with the same
PID.

> NOTICE: On Linux systems you have a very similar entity, it is called symbolic
link.

A PID is "linked" to a URL (or even multiple ones) and the URL(s) can be changed
without affecting the PID itself. To access the file(s) behind a PID it is
resolved by some service. A PID looks like this:

`847/e4ac5caa-f556-11e2-82f1-0024e845a970`

where '847' is the so called prefix, a unique number referring to a given community.  

Coming back to the scientists in the example above: Assume they had used PIDs
from the start. Now every time the location of the file mentioned above changes,
it is sufficient to just change the URL that is linked to the corresponding PID.

For a more in-depth introduction please have a look at [1] and also visit [2].

[1]: https://www.surfsara.nl/sites/default/files/20110404_EPIC_Flyer_201010.pdf
[2]: http://www.pidconsortium.eu/

## Support for PIDs in gtransfer ##

PIDs and files containing PIDs can be used as source URLs in gtransfer since
v0.2.0. To allow gtransfer to detect a source URL as either PID or PID file, you
have to provide pseudo protocol identifiers in front of the actual PID or path
to a PID file. For a single PID provide `pid://` and for a file containing PIDs
provide `pidfile://`.

### Examples ###

#### Single PID ####

```shell
$ gt -s pid://847/fc158422-d9c0-11e2-82d6-0024e845a970 -d plx-ext:/~/tmp/file/
[...]
```

#### Multiple PIDs within a PID file ####

```shell
$ gt -s pidfile:///path/to/pidFile -d plx-ext:/~/tmp/files/
[...]
```

#### PID file ####

Each line contains exactly one PID.

```shell
$ cat /path/to/pidFile
847/e4ac5caa-f556-11e2-82f1-0024e845a970
847/e14940d2-f556-11e2-8f06-0024e845a970
847/e6ff0a20-f556-11e2-8036-0024e845a970
847/eacf7572-f556-11e2-b299-0024e845a970
847/ed2a585a-f556-11e2-ad84-0024e845a970
847/f097b85c-f556-11e2-80c1-0024e845a970
847/f304d642-f556-11e2-80bf-0024e845a970
847/f64dd114-f556-11e2-8535-0024e845a970
847/f89ca77e-f556-11e2-a110-0024e845a970
```

## Internals ##

Gtransfer makes use of the same [iRODS] micro-services, that are also in use by
the [EUDAT] _datastager script_. To call and to provide input to such a
micro-service, a _rule_ is executed by the `irule` tool which is part of the
iRODS client tools. A typical resolve call looks like this:

[iRODS]: http://www.irods.org/
[EUDAT]: http://www.eudat.eu/

```shell
$ irule -F URLselecter.r '*pid="847/91a9c16c-f5bc-11e2-a88b-0024e845a970"'
Output: irods://host.domain.tld:1247/ZONE/home/user/testPID/test1
```

As you can see, the result is an iRODS URL, which could be used by iRODS client
tools, but not by gtransfer. Therefore the protocol, host and port need to be
mapped to a GridFTP URL (`gsiftp://`) which gtransfer can use as source of a
transfer. Usually the iRODS installations in EUDAT have an integrated GridFTP
server ( _iRODS DSI_ module for the _globus-gridftp-server_) available that 
operates on the same directory tree. This means an iRODS URL can be mapped 
to a GridFTP URL by simply exchanging the protocol and the port of a URL, 
e.g. `irods://host.domain.tld:1247/[...]` could be mapped to 
`gsiftp://host.domain.tld:2811/[...]`. 

Gtransfer ships with some default mappings valid for EUDAT hosts, which can be
easily extended by adding a mapping between iRODS and GridFTP URL to the
`[...]/pids/irodsMicroService_mappingFile`.

### Example mapping file ###

```shell
$ cat .gtransfer/pids/irodsMicroService_mappingFile
irods://host.domain.tld:1247;gsiftp://host.domain.tld:2811
```

### Resolving a PID file ###

To speed up the resolving process for a PID file, the contained PIDs are not
resolved sequentially but in parallel with _N_ processes at the same time. _N_
is automatically chosen and defaults to the number of CPU cores available
(`/sys/devices/system/cpu/cpu*`) + 1 on Linux driven systems. After resolving
and mapping, gtransfer builds a transfer list containing the resolved URLs and
the destination URL and performs a list transfer with this transfer list as
input.


## Requirements ##

For this to work you need to have access to a site that provides access to the
[EPIC] PID service. You also need a configured `irule` client that executes the
iRODS micro-service that performs the resolving of a given PID.

[EPIC]: http://www.pidconsortium.eu/

#### Exemplary iRODS client configuration ####

This configuration uses GSI for authentication.

```shell
$ cat $HOME/.irods/.irodsEnv
irodsHost host.domain.tld
irodsPort 1247
irodsUserName user
irodsZone ZONE
irodsAuthScheme GSI
```

## Limitations ##

Gtransfer uses globus-url-copy and hence could in principle retrieve files via
various protocols (e.g. `gsiftp://`, `http://`, `https://` and `ftp://`). But
in the current implementation of the PID support it is assumed that files behind
a PID are located in an iRODS zone which offers access via GridFTP. This is a
usual configuration in EUDAT.

