# Gtransfer - The GridFTP data transfer script #

* [Description](#description)
* [Features](#features)
    * [Multi-step data transfers](#multi-step-data-transfers)
    * [Data transfer using multipathing](#data-transfer-using-multipathing)
    * [Optimized data transfer performance](#optimized-data-transfer-performance)
    * [Data transfer interruption and continuation](#data-transfer-interruption-and-continuation)
    * [Data transfer reliability](#data-transfer-reliability)
    * [Bash completion](#bash-completion)
    * [Host aliases](#host-aliases)
    * [Persistent identifiers (PIDs)](#persistent-identifiers-pids)
* [Examples](#examples)
* [Who is using it?](#who-is-using-it)
* [License](#license)


## Description ##

Gtransfer is a wrapper script for [tgftp] (which itself wraps [globus-url-copy])
and also uses functionality of [uberftp]. Gtransfer provides an advanced command
line interface for performing GridFTP data transfers. The primary aim of
gtransfer is to make GridFTP data transfers on the command line as easy as
possible for the user. Therefore a user only has to provide the source and the
destination to perform a data transfer:

```shell
$ gt -s <SOURCE> -d <DESTINATION>
```

[tgftp]: https://github.com/fr4nk5ch31n3r/tgftp/
[globus-url-copy]: http://toolkit.globus.org/toolkit/docs/latest-stable/gridftp/user/#globus-url-copy
[uberftp]: https://github.com/JasonAlt/UberFTP

## Features ##

### Multi-step data transfers ###

Gtransfer can transfer files along predefined paths by using transit sites and
can therefore bridge different network domains.

Example:

```shell
$ gt -s host1:/files/* -d host3:/files/
................
```

> **NOTICE:** This examples uses two [host aliases][aliases] - `host1:` and
> `host3:` - which can point to ordinary host addresses like
> `gsiftp://host1.domain.tld:2811`.

[aliases]: #host-aliases

![multi-step transfer](/share/doc/images/multi-step-transfer.png)

The host `host1` is located in a private network, `host3` is located in the
Internet and `host2` has connections to both networks. To transfer files from
`host1` to `host3` gtransfer copies the files to the transit host `host2` (first
step) and afterwards from `host2` to `host3` (second step). After the transfer
has finished temporary files are removed from `host2`. See [dpath(5)] for
details.

[dpath(5)]: /share/doc/dpath.5.md

### Data transfer using multipathing ###

Gtransfer can distribute a data transfer over multiple paths. This way users
can benefit from the combined bandwidth of multiple paths.

Example

```shell
$ gt -s host1:/file/* -d host3:/files/ -m all
010101011
```

![transfer using multipathing](/share/doc/images/multipathing-transfer.png)

The host `host1` has connections to both the Internet and a private network. The 
bandwidth of the Internet connection is limited to 1 Gb/s, but the connection to
the private network has a bandwidth of 10 Gb/s. The host `host2` has a bandwidth
of 10 Gb/s on connections to both the Internet and the private network. In
effect there are two paths available from `host1` to `host3`, one direct path
and one indirect path using `host2` as transit site. With multipathing, instead
of using only one path, both paths can be used to combine the available
bandwidth. To distribute a data transfer over those two paths, gtransfer splits
the list of files to be transferred into two lists according to the bandwidth
proportions taking into account the file size. I.e. the connection with the
greater bandwidth will transfer a greater amount of the total file size of the
data transfer than the other connection.

> **NOTICE:** Because the second path uses a transit site and needs two transfer
> steps to complete, the effective bandwidth is lower than the bandwidth of the
> used connections.

### Optimized data transfer performance ###

Another aim of gtransfer is to allow well-performing data transfers without
detailed knowledge about the underlying facilities. Therefore gtransfer supports
usage of pre-optimized data transfer parameters for specific connections. See
[dparam(5)] for details. In addition gtransfer can also automatically optimize a
data transfer depending on the size of the files.

[dparam(5)]: /share/doc/dparam.5.md

### Data transfer interruption and continuation ###

Gtransfer supports interruption and continuation of transfers. You can interrupt
a transfer by hitting `CTRL+C`. To continue an interrupted transfer simply issue
the very same command, gtransfer will then continue the transfer where it was
interrupted. The same procedure also works for a failed transfer.

### Data transfer reliability ###

Gtransfer supports automatic retries of failed transfer steps. The number of
retries is configurable. See [gtransfer(1)] for details.

[gtransfer(1)]: /share/doc/gtransfer.1.md

### Bash completion ###

Gtransfer makes use of bash completion to ease usage. This supports completion
of options and URLs. URL completion also expands (remote) paths directly on the
command line. Just hit the `TAB` key to see what's possible.

### Host aliases ###

Gtransfer can use host aliases as alternatives to host addresses. E.g. a user
can use `myGridFTP:` and `gsiftp://host1.domain.tld:2811` synonymically. See
[host aliases] for more details.

[host aliases]: /share/doc/host-aliases.md

### Persistent identifiers (PIDs) ###

Gtransfer can use persistent identifiers (PIDs) as used by [EUDAT] and provided 
by [EPIC] as source of a data transfer. See [persistent identifiers] for more
details.

[persistent identifiers]: /share/doc/persistent-identifiers.md
[EUDAT]: http://www.eudat.eu/
[EPIC]: http://www.pidconsortium.eu/


## Examples ##

As said, the primary aim of gtransfer is to make GridFTP data transfers on the
command line as easy as possible for the user. Therefore the [simple example] in
the description should be already suitable for most users.

[simple example]: #description

You can find more detailed examples in the [gtransfer wiki] on GitHub.
Additional examples will be made available occasionally.

[gtransfer wiki]: https://github.com/fr4nk5ch31n3r/gtransfer/wiki/Gtransfer-explained


## Who is using it? ##

This is a list of HPC centers in Europe that use gtransfer in production:

[![HLRS logo](https://raw.github.com/fscheiner/images/master/site_logos/hlrs_logo.png)](http://www.hlrs.de/)
  
[Höchstleistungsrechenzentrum Stuttgart (HLRS - Germany)](http://www.hlrs.de/)

****

[![CSC logo](https://raw.github.com/fscheiner/images/master/site_logos/csc_logo_h100.png)](http://www.csc.fi/)

[CSC - IT Center for Science (CSC - Finland)](http://www.csc.fi/)

****

[![LRZ logo](https://raw.github.com/fscheiner/images/master/site_logos/lrz_logo_new_h100.png)](http://www.lrz.de/)

[Leibniz-Rechenzentrum (LRZ) der Bayerischen Akademie der Wissenschaften (LRZ - Germany)](http://www.lrz.de/)

****

[![ICHEC logo](https://raw.github.com/fscheiner/images/master/site_logos/ichec_logo.png)](http://www.ichec.ie/)

[Irish Centre for High-End Computing (ICHEC - Ireland)](http://www.ichec.ie/)

****

[![CINECA logo](https://raw.github.com/fscheiner/images/master/site_logos/cineca_logo.png)](http://www.cineca.it/)

[Centro di supercalcolo, Consorzio di università (CINECA - Italy)](http://www.cineca.it/)

****

[![SURFSARA logo](https://raw.github.com/fscheiner/images/master/site_logos/surfsara_logo.png)](http://www.surfsara.nl/)

[SURFsara (SURFsara - The Netherlands)](http://www.surfsara.nl/)

****

[![CINES logo](https://raw.github.com/fscheiner/images/master/site_logos/cines_logo.png)](http://www.cines.fr/)

[Centre Informatique National de l’Enseignement Supérieur (CINES - France)](http://www.cines.fr/)

****

[![IT4Inoovations logo](https://raw.github.com/fscheiner/images/master/site_logos/it4innovations_logo_h100.png)](http://www.it4i.cz/)

[IT4Innovations national supercomputing center (IT4Innovations - Czech republic)](http://www.it4i.cz/)


## License ##

(GPLv3)

Copyright (C) 2010, 2011, 2013-2015 Frank Scheiner, HLRS, Universitaet Stuttgart  
Copyright (C) 2011, 2012, 2013 Frank Scheiner

The software is distributed under the terms of the GNU General Public License

This software is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a [copy] of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

[copy]: /COPYING

