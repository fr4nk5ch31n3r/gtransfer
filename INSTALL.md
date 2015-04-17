# gtransfer - The GridFTP transfer script - Installation instructions #

## Contents ##

1. Dependencies
2. Installation  
    2.1	System install  
    2.2	User install  
    2.3 Git deployment  
    2.4 Add-ons  
        2.4.1 Module file  
        2.4.2 Bash completion
3. Uninstallation

****

## (1) Dependencies ##

To run the _gtransfer_ scripts, some dependencies have to be met first. They
need the following binaries/scripts in `$PATH` for operation:

* `cat` (GNU coreutils)
* `cut` (GNU coreutils)
* `sleep` (GNU coreutils)
* `truncate` (GNU coreutils)
* `grep` (GNU version)
* `sed` (GNU version)
* `sha1sum` (GNU version)
* `tgftp`
* `uberftp`
* `telnet` (Linux NetKit version or compatible)

`tgftp` additionally needs a `globus-url-copy` with `-list` function (Globus
Toolkit >= v4.2.0) and is available from [GitHub].

[GitHub]: https://github.com/fr4nk5ch31n3r/tgftp/

## (2) Installation ##

The gtransfer installer script (`install.sh`) supports two modes of
installation:

* System installation (for multiple users)
* User installation (for a single user)

### (2.1) System installation ###

The gtransfer tarball tries to conform to the [FHS v2.3 standard] and resembles
an add-on application software. This means that static files like scripts,
manual pages and documentation should be located in a directory structure below
`gtransfer` in `/opt` or optionally in `/opt/<PROVIDER>`. The directory
structure is like the following:

```
gtransfer
|-- bin/
|-- etc/
`-- share/
    |-- doc/
    `-- man/
        `-- man1/
```

According to the [FHS v2.3 standard], configuration files of add-on application
software should be located below `/etc/opt`. To ease up installation for
subadmins which don't have write access to `/etc`, the configuration files for
gtransfer are not installed there by the installer. After installation they are
located below `<INSTALL_PATH>/etc`. Please adapt the configuration files to your
local configuration after installation.

The gtransfer scripts search for their configuration files in the following
places and order:

* `/etc/gtransfer`
* `<INSTALL_PATH>/etc`
* `/etc/opt/gtransfer`
* `$HOME/.gtransfer`
* `$( dirname $BASH_SOURCE )/../etc/gtransfer`

The paths to the library files and additional helper tools are derived from
these paths. I.e. the following paths are used respectively to find the library
files:

* `/usr/share/gtransfer`
* `<INSTALL_PATH>/lib`
* `/opt/gtransfer/lib`
* `$HOME/opt/gtransfer/lib`
* `$( dirname $BASH_SOURCE )/../lib`

The following paths are used respectively to find the additional helper tools:

* `/usr/libexec/gtransfer`
* `<INSTALL_PATH>/libexec`
* `/opt/gtransfer/libexec`
* `$HOME/opt/gtransfer/libexec`
* `$( dirname $BASH_SOURCE )/../libexec`

Hence manual intervention to provide the configuration files to the scripts is
only needed, if gtransfer is installed below an optional `<PROVIDER>` directory.
This can be achieved by either copying the configuration files to
`/etc/opt/gtransfer` or create a link there that points to the configuration
file base directory. Alternatively you can also reconfigure the path in the
script files itself after installation.

To install gtransfer in the way described above, just run the following command
from the package dir:

```
./install.sh /opt[/<PROVIDER>][/]
```

Remember to make the configuration files available to the gtransfer scripts with
the methods described above if you install below a `PROVIDER` directory.

[FHS v2.3 standard]: http://www.pathname.com/fhs/pub/fhs-2.3.html

### (2.2) User installation ###

It's also possible to install and run gtransfer from your home directory. For
this type of installation just run the following command from the package dir:

```
./install.sh
```

This will create a directory structure similar to the structure described in the
system installation chapter in your home directory, but also place links to the
gtransfer scripts in your private bin directory (`$HOME/bin`). This is because
this dir - if existing - is usually in `$PATH` by default. If it's not already
existing, it will be created. Another difference is that the configuration files
are copied to `$HOME/.gtransfer` for a user install. Please adapt the
configuration files to your local configuration after installation.

### (2.3) Git deployment ###

Gtransfer can also be used directly from its git repository. Simply clone the
[gtransfer git repository], adapt your `$PATH` environment variable, optionally
source the [bash completion file] for an improved user experience and you are
ready to go.

> **NOTICE:** Due to the used implementation for finding its configuration and
> library files, the gtransfer scripts will not use the configuration and
> library files from the git repository as long as another gtransfer system or
> user installation is available on the same host. This is also true if native
> OS packages are already installed. The gtransfer scripts will then use the
> first available path with configuration and library files.

[gtransfer git repository]: https://github.com/fr4nk5ch31n3r/gtransfer.git
[bash completion file]: #242-bash-completion


### (2.4) Add-ons ###


#### (2.4.1) Module file ####

To ease usage of this tool for users that have a [modules environment]
available, a module file has been created. All related files are stored below
`./modulefiles` in the package dir. As the implementation of a modules
environment usually differs from host to host or site to site, the module files
have to be installed manually. After installation change the string "version" in
the file names to the installed version of gtransfer (e.g. "gtransfer-version"
=> "gtransfer-0.3.0").

[modules environment]: http://en.wikipedia.org/wiki/Modules_Environment

#### (2.4.2) Bash completion ####

To even more ease usage of this tool a bash completion file was created. This
supports options and URLs. URL completion also expands (remote) paths. The
related file is stored in `./etc/bash_completion.d/` in the package dir. Please
move this file to a convenient location and make sure it is sourced by the
users' bash shells.

## (3) Uninstallation ##

For uninstallation just run the link `./uninstall.sh`. This will remove the
gtransfer distribution and the directory `$HOME/.gtransfer`. Hence if you want
to retain your dpaths and dparams, make a backup before uninstalling gtransfer.
If you add the original install path for a system installation, e.g.
`./uninstall.sh /opt`, the gtransfer distribution will be removed from there
instead. Because the modulefile and the bash completion file have to be
installed manually, they're not removed by the uninstallation procedure.

