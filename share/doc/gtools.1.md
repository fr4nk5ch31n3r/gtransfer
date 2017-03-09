% GTOOLS(1) gtools 0.3.0 | User Commands
% Frank Scheiner
% Mar 09, 2017


# NAME #

**gtools**


# SYNOPSIS #

**gtools [function [arguments]...]** or

**function [arguments]...** if symlinked


# DESCRIPTION #

**gtools** is a multi-call shell script that combines various GridFTP
functionality into a single executable. Most people will create a
link to gtools for each function they wish to use and gtools will
act like whatever is was invoked as.


# COMMON OPTIONS #

All **gtools** functions provide a terse runtime description of their behavior
when invoked without arguments.

# FUNCTIONS #

Currently defined functions:

(g)cat, (g)ls, (g)mkdir, (g)mv, (g)rm

All functions support host aliases and remote directory browsing via bash completion. Use functions without the **g** prefix when using them via **gtools**, use functions with the **g** prefix when using them directly via (sym)links.

# FUNCTION DESCRIPTIONS #

## (g)cat ##

**gcat _url_**

Print to stdout the contents of the remote file given in _url_.

## (g)ls ##

**gls _url_**

List the remote file or the contents of the remote directory given in _url_.

## (g)mkdir ##

**gmkdir _url_**

Create the remote directory given in _url_. Creates non-existing directories
recursively but needs one GridFTP operation per directory.

## (g)mv ##

**gmv _url1_ _url2_**

Move/rename the remote file or directory in _url1_ to the given path and/or
name in _url2_.

## (g)rm ##

**grm _url_**

Remove the remote file or empty directory given in _url_.


# SEE ALSO #

**uberftp(1c)**, **halias(1)**
