% DPATH(5) gtransfer 0.2.0 | File formats
% Frank Scheiner
% Aug 19, 2013


# NAME #

data path (dpath) - defines possible paths between source and destination of a
gtransfer data transfer


# SYNOPSIS #

_$HOME/.gtransfer/dpaths/*_  
_[...]/dpaths/*_


# DESCRIPTION #

A data path (dpath) describes possible paths from a specific source to a
specific destination. There exists only one dpath (file) for each source
destination combination. However each dpath (file) can contain multiple distinct
paths that each route data from source to destination. These paths are
differentiated by an attribute called _metric_. The metric attribute of a path
is an indicator for the possible data transfer performance of a path (somewhat
similar to metrics in routing). Therefore, the fastest path should use the
metric `0`. Slower paths should use a metric of `0 + n`.

Dpaths can be created either manually or via the `dpath(1)` tool. Please see
`dpath(1)` for more information.

Dpaths are named after the SHA1 hash of the corresponding source and
destination (separated by a `;`) used during creation. E.g. a dpath with
`gsiftp://host1.domain.tld:2811` as source and `gsiftp://host3.domain.tld:2811`
as destination will be named `799f02cde51576d5f620b8450a37e65d48883801`. This
way gt can select the correct dpath for a transfer by calculating the SHA1 hash
of the source and destination. The `dpath(1)` tool also links the dpath file
with an alias symlink that makes it easier to inspect specific dpaths.


# PURPOSE #

When transferring data from source to destination, gtransfer will by default
use the path with metric 0 from the corresponding dpath. You can change the
used metric with the gtransfer option `--metric|-m`. By providing dpaths
gtransfer can bridge different network domains _transparently_.

# EXAMPLES #

    <source>
    gsiftp://host1.domain.tld:2811
    </source>
    <destination>
    gsiftp://host3.domain.tld:2811
    </destination>
    <path metric="0">
    gsiftp://host1.domain.tld:2811;gsiftp://host3.domain.tld:2811
    </path>
    <path metric="1">
    gsiftp://host1.domain.tld:2811;gsiftp://host2.domain.tld:2811/tmp/
    gsiftp://host2.domain.tld:2811/tmp/;gsiftp://host3.domain.tld:2811
    </path>


# DPATH SYNTAX #

A dpath file consists of XML like tags, attributes and values. As gt does not
make use of a real XML parser, (start and end) tags and values have to be
written on a single line each as shown in the example.


# PATH SYNTAX #

A path is a table with two columns separated by `;`. Each line of the table
describes one step of a transfer and consists of the source (1st col.) and the
destination (2nd col.) of a transfer step.

## Single step or direct transfers ##

The one and only line starts with a string identical to the source of the data
path. The destination is identical to the destination of the data path. This
means that for direct transfers there are not paths added to these strings.

## Multistep or indirect transfers ##

**A.** The first line either starts with a string identical to the source of the
data path or a `file://` URL part, if a local transfer is needed first (for
example a transfer from a local scratch filesystem to another locally mounted
remote filesystem). The destination (the _transit site_) is either a
`gsiftp://FQDN[:PORT]` URL with a default path (temporary storage space for
files on transit sites) added, or a `file://` URL part with a default path
added.

**B.** All following lines start with either the destination string of the previous
line or a `gsiftp://FQDN[:PORT]` URL with a path added, that points to the same
directory as the path used by the previous destination. They end either with a
string which is identical to the destination of the data path (last step without
a path), or a destination as described in A (transit step).


# WARNING #

Paths with identical metric are not allowed currently!


# SEE ALSO #

`gtransfer(1)`, `dpath(1)`, `sha1sum(1)`

