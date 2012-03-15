gtransfer - The GridFTP transfer script - Installation instructions
====================================================================

Contents:

1. Dependencies
2. Installation
2.1	System install
2.2	User install
2.3	Add-ons
2.3.1		Modulefile
2.3.2		Bash completion
3. Uninstallation

################################################################################


(1) Dependencies:
------------------

To run the gtransfer scripts, some dependencies have to be met first. It needs
the following binaries/scripts in $PATH for operation:

* cat (GNU coreutils)
* cut (GNU coreutils)
* sleep (GNU coreutils)
* grep (GNU version)
* sed (GNU version)
* tgftp
* uberftp
* telnet (Linux NetKit version)

"tgftp" additionally needs "globus-url-copy" with "-list" function (>= Globus
Toolkit 4.2.0) and is available from:

<https://github.com/fr4nk5ch31n3r/tgftp/>


(2) Installation:
------------------

The gtransfer installer script (install.sh) supports two modes of installation:

2.1 System installation (for multiple users)

2.2 User installation (for a single user)


(2.1) System installation:
---------------------------

The gtransfer tarball tries to conform to the "FHS v2.3 standard"* and resembles
an add-on application software. This means that static files like scripts,
manual pages and documentation should be located in a directory structure below
"gtransfer" in "/opt/" or optionally in "/opt/<PROVIDER>/". The directory
structure is like the following:

gtransfer
|-- bin/
|-- etc/
`-- share/
    |-- doc/
    `-- man/
        `-- man1/

According to the "FHS v2.3 standard" configuration files of add-on application
software should be located below "/etc/opt/". To ease up installation for
subadmins which don't have write access to "/etc/", the configuration files for
gtransfer are also located below the installation directory ("/opt/gtransfer/").
Please adapt the configuration files to your local configuration.

The gtransfer scripts search for their configuration files in the following
places and order:

- "/opt/gtransfer/etc/" (default for system install)
- "/etc/opt/gtransfer/"
- "$HOME/.gtransfer/" (default for user install)

Hence only if gtransfer is installed below an optional <PROVIDER> directory,
manual intervention is needed to provide the configuration files to the scripts.
This can be achieved by either copying the configuration files to
"/etc/opt/gtransfer" or create a link there that points to the configuration
file base directory. Alternatively you can also reconfigure the path in the
script files itself after installation.

To install gtransfer in the way described above, just run the following command
from the package dir:

"./install.sh /opt/[<PROVIDER>]/"

Remember to make the configuration files available to the gtransfer scripts with
the methods described above if you install below a <PROVIDER> directory.
___________
*) FHS v2.3 <http://www.pathname.com/fhs/pub/fhs-2.3.html>


(2.2) User installation

It's also possible to install and run gtransfer from your home directory. For
this type of installation just run the following command from the package dir:

"./install.sh"

This will create a directory structure similar to the structure described in
the system installation chapter in your home directory, but also place links to
the gtransfer scripts in your private bin directory ($HOME/bin). This is because
this dir - if existing - is usually in $PATH by default. If it's not already
existing, it will be created. Another difference is that the configuration files
are copied to "$HOME/.gtransfer" for a user install. Please adapt the
configuration files to your local configuration.


(2.3) Add-ons:
---------------


(2.3.1) Modulefile:
--------------------

To ease usage of this tool for users that have a "modules environment"*
available, a modulefile has been created. All related files are stored below
"./modulefiles".
___________
*) modules environment <http://en.wikipedia.org/wiki/Modules_Environment>


(2.3.2) Bash completion:
-------------------------

To even more ease usage of this tool a bash completion file was created. This
supports options and URLs. URL completion also expands (remote) paths. The
related file is stored in "./etc/bash_completion.d/". Please move this file to a
convenient location.


(3) Uninstallation:
--------------------

For uninstallation just run the link "./uninstall.sh". This will remove the
gtransfer distribution and the directory "$HOME/.gtransfer". Hence if you want
to retain your dpaths and dparams, make a backup before uninstalling gtransfer.
If you add the original install path for a system installation to
"./uninstall.sh", the gtransfer distribution will be removed from there instead.
Because the modulefile and the bash completion file have to be installed
manually, they're not removed by the uninstallation.

