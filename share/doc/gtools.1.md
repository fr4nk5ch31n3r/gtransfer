% GTOOLS(1) gtools 0.3.0 | User Commands
% Frank Scheiner
% Mar 14, 2017


# NAME #

**gtools**


# SYNOPSIS #

**gtools [function [arguments]...]** or

**function [arguments]...** if symlinked


# DESCRIPTION #

**gtools** is a multi-call shell script that combines various GridFTP
functionality (provided by **uberftp(1c)**) into a single executable. Most
people will create a link to gtools for each function they wish to use and
gtools will act like whatever is was invoked as.


# COMMON OPTIONS #

All **gtools** functions provide a terse runtime description of their behavior
when invoked without arguments.

# FUNCTIONS #

Currently defined functions:

(g)cat, (g)ls, (g)mkdir, (g)mv, (g)rm

All functions support host aliases and remote directory browsing via bash
completion. Function names are without the **g[...]** prefix when used as
arguments of **gtools**. When used drectly (via symlinks) the **g[...]** prefix
should be used to differentiate them from the similar OS tools (**cat(1)**,
**ls(1)**, **mkdir(1)**, **mv(1)** and **rm(1)**).

# FUNCTION DESCRIPTIONS #

## (g)cat ##

**gcat _url_**

Print to stdout the contents of the remote file given in _url_ (like **cat [...]**).

## (g)ls ##

**gls _url_**

List the remote file or the contents of the remote directory given in _url_.
Output is similar to **ls -la [...]**.

## (g)mkdir ##

**gmkdir _url_**

Create the remote directory given in _url_. Creates non-existing directories
recursively (like **mkdir -p [...]**) but needs one GridFTP operation per directory!

## (g)mv ##

**gmv _url1_ _url2_**

Move/rename the remote file or directory in _url1_ to the given path and/or
name in _url2_. Only works when both _url1_ and _url2_ point to the same remote
GridFTP service!

## (g)rm ##

**grm _url_**

Remove the remote file (like **rm [...]**) or empty directory (like **rmdir [...]**) given in _url_.


# SEE ALSO #

**uberftp(1c)**, **halias(1)**, **cat(1)**, **ls(1)**, **mkdir(1)**, **rm(1)**, **rmdir(1)**
