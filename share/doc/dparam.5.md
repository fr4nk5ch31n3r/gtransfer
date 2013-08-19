% DPARAM(5) gtransfer 0.2.0 | Configuration files
% Frank Scheiner
% Aug 19, 2013


# NAME #

default param (dparam) - defines optimized data transfer parameters between
source and destination of a gtransfer data transfer


# SYNOPSIS #

_$HOME/.gtransfer/dparams/*_  
_[...]/dparams/*_


# DESCRIPTION #

Default parameters (dparams) can be defined for specific source destination
combinations, given the fact, they describe _direct_ connections. A _direct_
connection is defined as having no transit site between source and destination.
The default parameters are usually consisting of the best performing parameter
configurations for the `globus-url-copy(1)`/`tgftp(1)` tool for the
corresponding connection. These can be determined by executing data transfer
tests between the specific source and destination.

Dparams can be created either manually or via the `dparam(1)` tool. Please see
`dparam(1)` for more information.

Dparams are named after the SHA1 hash of the corresponding source and
destination (separated by a `;`) used during creation. E.g. a dparam with
`gsiftp://host1.domain.tld:2811` as source and `gsiftp://host3.domain.tld:2811`
as destination will be named `799f02cde51576d5f620b8450a37e65d48883801`. This
way gt can select the correct dparam for a transfer by calculating the SHA1 hash
of the source and destination. The `dparam(1)` tool also links the dparam file
with an alias symlink that makes it easier to inspect specific dparams.


# PURPOSE #

When transferring data from source to destination, gtransfer will automatically
use the corresponding dparam for the specific transfer providing optimized data
transfer performance without user intervention.


# EXAMPLES #

    <source>
    gsiftp://host1.domain.tld:2811
    </source>
    <destination>
    gsiftp://host3.domain.tld:2811
    </destination>
    <gsiftp_params>
    -p 4 -tcp-bs 16M -cc 8 -stripe -cd
    </gsiftp_params>


# DPARAM SYNTAX #

A dparam file consists of XML like tags, attributes and values. As gt does not
make use of a real XML parser, (start and end) tags and values have to be
written on a single line each as shown in the example.


# SEE ALSO #

`gtransfer(1)`, `dparam(1)`, `sha1sum(1)`, `tgftp(1)`, `globus-url-copy(1)`

