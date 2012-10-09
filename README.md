# Gtransfer - The GridFTP data transfer script #

## Contents ##

1. Synopsis  
    1.1	Data paths  
    1.2	Default parameters
2. Creating data paths
3. Providing data paths
4. Creating default params
5. Providing default params
6. gtransfer usage examples

***

## (1) Synopsis ##

The _gtransfer_ - or short _gt_ - tool is a wrapper for _tgftp_, enabling
(GridFTP) transfers along predefined paths by using transit sites. Additionally
it supports usage of default parameters for specific connections.

Detailed help is provided by the help output of the script and its man page.

There's bash completion available for gtransfer. This supports completion of
options and URLs. URL completion also expands (remote) paths.

### (1.1) Data paths ###

A data path - or short _dpath_ - describes possible paths from a specific source
to a specific destination. There exists only one data path (file) for each
source destination combination. However each data path (file) can contain
multiple paths that each route data from source to destination.
These paths are differentiated by an attribute called _metric_. The metric
attribute of a path is an indicator for the performance of a path (somewhat
similar to routing). Therefore, the fastest path should use the metric `0`.
Slower paths should use a metric of `0 + n`. By default gt uses the path with
metric `0` for a transfer (change with `--metric|-m`). More details on this are
described in (2).

WARNING:
Paths with identical metric are not allowed currently!

### (1.2) Default parameters ###

Default parameters - or short _dparams_ - can be defined for specific source
destination combinations, given the fact, they describe _direct_ connections. A
_direct_ connection is defined as having no transit site between source and
destination. The default parameters are usually consisting of the best
performing parameter configurations for the _globus-url-copy_/_tgftp_ tool for
the corresponding connection. These can be determined by the data services group
or by an advanced user itself using manual testing or tgftp autotuning.

***

## (2) Creating data paths ##

For data path creation the tool _dpath_ can be used. Data paths are by default
created in `$HOME/.gtransfer/dpaths`. This can be done for example with the
following command:

```
$ dpath --create \  
        --source file:// \  
        --destination gsiftp://gridftp-host.domain:2811 \  
        --alias Local--to--Domain_gridftp-host
```

`source` and `destination` have to be URLs (without any path additions) like the
following examples:

`file://`

`gsiftp://gridftp-host.domain:2811`

If the environment variable `EDITOR` is set, dpath will open the already created
data path file for editing with the executable set in `EDITOR`. See the
documentation on data path files below. For a detailed overview of all features
of dpath, please check the help with `--help` or the man page.

EXAMPLE:

The source and destination combination...

`
gsiftp://gridftp-host.site-a:2811;gsiftp://gridftp-host.site-b:2811
`

...will be internally transformed to the following string (actually the SHA1
hash of the input)...

`
26883acd4225482d26e588e97df3d1d1c3740d02
`

...which is used as filename for the specific data path from
`gridftp-host.site-a` to `gridftp-host.site-b`.

NOTICE:

As the SHA1 hash value is not very meaningful, a link to a specific data path,
naming the source and destination could be helpful for manual human interaction. 
Therefore dpath automatically creates one with a user provided alias as name.

EXAMPLE:

```
$HOME/.gtransfer/dpaths
|-- 26883acd4225482d26e588e97df3d1d1c3740d02
|-- ee2824fdccfb55c359b4d40b0370da7b66360026
|-- Site-b_gridftp-host--to--Site-c_gridftp-host -> ee2824fdccfb55c359b4d40b0370da7b66360026
`-- Site-a_gridftp-host--to--Site-b_gridftp-host -> 26883acd4225482d26e588e97df3d1d1c3740d02

/etc/gtransfer/dpaths
|-- 18b0cc9961ad47e7cb2021aa158f86e561e07683
`-- Local--to--Domain_gridftp-host -> 18b0cc9961ad47e7cb2021aa158f86e561e07683
```

Naming of the aliases is not restricted, but it is encouraged to use something
like the following:

`
{{site|organization}_{resource|hostName|FQDN}|Local}--to--{site|organization}_{resource|hostName|FQDN}
`

Example file contents of a data path:

`
Local--to--Domain_gridftp-host -> 18b0cc9961ad47e7cb2021aa158f86e561e07683:
`
```
<source>
file://
</source>
<destination>
gsiftp://gridftp-host.domain:2811
</destination>
<path metric="0">
file://;gsiftp://gridftp-host.domain:2811
</path>
<path metric="1">
file://;gsiftp://gridftp-host.transit:2811/tmp/
gsiftp://gridftp-host.transit:2811/tmp/;gsiftp://gridftp-host.domain:2811
</path>
```

This data path file defines two paths from the local machine (indicated by the
`file://` URL part) to the GridFTP host `gridftp-host.domain`. The path with
metric `0` will use a direct connection to transfer data from the local machine
to the remote machine and therefore is (usually) the fastest path. The second
path uses another GridFTP host as transit site. Therefore, if this path is used
(e.g. by using `--metric|-m 1` as option for gtransfer) the data is first
transferred to `gridftp-host.transit` and as second step, from there to the
final destination `gridftp-host.domain`.

NOTICE:

### The syntax of a path is as follows ###

A path is a table with two columns separated by `;`. Each line of the table
describes one step of a transfer and consists of the source (1st col.) and the
destination (2nd col.) of a transfer step.

### Single step or direct transfers ###

The one and only line starts with a string identical to the source of the data
path. The destination is identical to the destination of the data path. This
means that there are not paths added to these strings for direct transfers.

### Multistep or indirect transfers ###

**A.** The first line either starts with a string identical to the source of the
data path or a `file://` URL part, if a local transfer is needed first (for
example a transfer from a local scratch filesystem to another locally mounted
remote filesystem). The destination is either a `gsiftp://FQDN[:PORT]` URL with
a default world-writable* path added, or a `file://` URL part with a default
world-writable* path added.
__________
*)_Do I really need a world-writable path?_

_If a world-writable path is not desirable, it will also work with a_
_group-writable path, given the fact, that all GridFTP users (that should be able_
_to use this service) are included in this group. Please dont forget to set the_
_sticky bit on this directory!_

**B.** All following lines start with either the destination string of the previous
line or a `gsiftp://FQDN[:PORT]` URL with a path added, that points to the same
directory as the path used by the previous destination. They end either with a
string which is identical to the destination of the data path (last step without
a path), or a destination as described in A (transit step).
__________
FQDN Fully Qualified Domain Name
[...] values in brackets are optional

***

## (3) Providing data paths ##

Data paths can be maintained in any repository, but preferably one with version
control enabled (e.g. with git, svn, etc.). To make these data paths useful for
users, they should be hosted on a web server. The dpath tool can retrieve the
latest data path distribution from there (currently only http is supported).
Dpath expects a gzip compressed tar file containing the data paths. All files in
this tar file must be stored without paths; symbolic links should be preserved
(default for GNU tar on Ubuntu 10.04). The location and name of the tar file
must be defined in the dpath configuration file. A user can then retrieve the
data paths with the following command:

```
$ dpath --retrieve
```

To spare the user the manual retrieval, it is also possible to preload data
paths and place them in a convenient location (the location must be defined in
the gtransfer configuration file). Please notice, that data paths located in
the home directory of a user (in `$HOME/.gtransfer/dpaths`) take precedence over
preloaded data paths.

***

## (4) Creating default params ##

For creating default params the tool _dparam_ can be used. A default params
filename is constructed like a data path filename (see above!). This can be done
for example with the following command:

```
$ dparam --create \
         --source file:// \
         --destination gsiftp://gridftp-host.domain:2811 \
         --alias Local--to--Domain_gridftp-host
```

`source` and `destination` have to be URLs (without any path additions) like the
following examples:

`file://`

`gsiftp://gridftp-host.domain:2811`

If the environment variable `EDITOR` is set, dparam will open the already created
default params file for editing with the binary set in `EDITOR`. See the
documentation on default params files below. For a detailed overview of all
features of dparam, please check the help with `--help`.

Example file contents:

```
<source>
gsiftp://gridftp-host.site-a:2811
</source>
<destination>
gsiftp://gridftp-host.site-b:2813
</destination>
<gsiftp_params>
-vb -p 16 -tcp-bs 16M -pp -cc 8 -cd
</gsiftp_params>
```

***

## (5) Providing default params ##

Default params can be maintained in any repository, but preferably one with
version control enabled (e.g. with git, svn, etc.). To make these default params
useful for users, they should be hosted on a web server. The dparams tool can
retrieve the latest default params distribution from there (currently only http
is supported). Dparam expects a gzip compressed tar file containing the default
params. All files in this tar file must be stored without paths; symbolic links
should be preserved (default for GNU tar on Ubuntu 10.04). The location and name
of the tar file must be defined in the dparam configuration file. A user can
then retrieve the default params with the following command:

```
$ dparam --retrieve
```

To spare the user the manual retrieval, it is also possible to preload default
params and place them in a convenient location (the location must be defined in
the gtransfer configuration file). Please notice, that default params located in
the home directory of a user (in `$HOME/.gtransfer/dparams`) take precedence
over preloaded default params.

***

## (6) gtransfer usage examples ##

Help and usage output is provided by issuing:

```
$ gtransfer [--help]
```

or

```
$ gt [--help]
```

There are also man pages available for gt(ransfer), dpath and dparam.

EXAMPLES:

#1
This example transfers files from Site-a to Site-b using verbose output (`-v`)
and the path with metric `1`. This path _reroutes_ data between Site-a and Site-b
through Site-c.
After the last step (Site-c to Site-b) has completed, the temporary data at
Site-c is removed with a tgftp post command
(`tgftp [...] --post-command "[...]"`):

```
$ gt -s gsiftp://gridftp-host.site-a:2811/scratch/32x128MB/ -d gsiftp://gridftp-host.site-b:2812/scratch/32x128MB/ -v -m 1
Data path used:
/home/user/.gtransfer/dpaths/26883acd4225482d26e588e97df3d1d1c3740d02
Transfer step: 0
Default params used:
/home/user/.gtransfer/dparams/d86466c97a4eb60f73cbe63bdfca9f65779a915b
tgftp --source "gsiftp://gridftp-host.site-a:2811/scratch/32x128MB/" --target "gsiftp://gridftp-host.site-c:2813/transit/transitSiteTempDir.AXcwS7T9/" --log-filename "tgftp_transfer_14733__step_0.log" -- "-vb -p 32 -tcp-bs 8M -cc 8 -cd"
........
Transfer step: 1
Default params used:
/home/user/.gtransfer/dparams/ac684a72756fb8be0dae39c22811dd98da7775e2
tgftp --source "gsiftp://gridftp-host.site-c:2813/transit/transitSiteTempDir.AXcwS7T9/" --target "gsiftp://gridftp-host.site-b:2812/scratch/32x128MB/" --log-filename "tgftp_transfer_14733__step_1.log" --post-command "uberftp -rm -r gsiftp://gridftp-host.site-c:2813/transit/transitSiteTempDir.AXcwS7T9/ &" -- "-vb -p 32 -tcp-bs 8M -cc 8 -cd"
.....
INFO: The transfer succeeded!
```

#2
This example does the same as #1 but uses the path with the default metric
(which is `0`) and default output. This performs a single-step (direct) transfer
between Site-a and Site-b:

```
$ gt -s gsiftp://gridftp-host.site-a:2811/scratch/32x128MB/ -d gsiftp://gridftp-host.site-b:2812/scratch/32x128MB/
...........
```

