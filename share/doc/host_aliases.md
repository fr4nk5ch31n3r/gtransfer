# (gtransfer) host aliases #

* [What is a host alias?](https://github.com/fr4nk5ch31n3r/gtransfer/wiki/Host-aliases#what-is-a-host-alias)
* [Alias syntax](https://github.com/fr4nk5ch31n3r/gtransfer/wiki/Host-aliases#alias-syntax)
* [Alias mapping](https://github.com/fr4nk5ch31n3r/gtransfer/wiki/Host-aliases#alias-mapping)
    * [Alias mapping with file](https://github.com/fr4nk5ch31n3r/gtransfer/wiki/Host-aliases#alias-mapping-with-file)
    * [Alias mapping with directory](https://github.com/fr4nk5ch31n3r/gtransfer/wiki/Host-aliases#alias-mapping-with-directory)

## What is a host alias? ##

A so-called *host alias* is a string (e.g. `myGridFTP:`) which is mapped to a
host address (e.g. `gsiftp://host.domain.tld:2811`). Gtransfer supports host
aliases by using a small helper tool named `halias`. In gtransfer both the
alias and its expansion can be used synonymical. E.g.:

```shell
gt -s gsiftp://host.domain.tld:2811/~/file1 -d gsiftp://host.domain.tld:2811/~/file2
```

...and...

```shell
gt -s myGridFTP:/~/file1 -d myGridFTP:/~/file2
```

...will perform the same transfer. The gtransfer bash completion was also
enhanced to support host aliases. Aliases are proposed as possible host
addresses like regular host addresses. And you can also browse through remote
directories when using aliases. Currently the addition of `user@` in front of
the aliases does not work yet, so if you need to access GridFTP servers with
non-standard user names, use the regular host addresses currently (e.g.
`gsiftp://user@host.domain.tld:2811`).

## Alias syntax ##

The following characters are not allowed in alias strings:

* `;`
* `/`
* ` ` (space)

Apart from that an alias string has to be a valid file name, too. Also not
needed, placing a `:` at the end of an alias string mimics the look of SSH URLs,
so this is recommended.

## Alias mapping ##

Aliases can be mapped to host addresses either by means of a file or a
directory. If many aliases are available the expansion will be faster if you are
using a directory. Therefore the recommendation is to use a directory as alias
source by default.

### Alias mapping with file ###

```shell
$ cat aliases
alias1:;gsiftp://host.domain.tld:2811
myGridFTP:;alias1
alias3:;$( doSomething )
alias4:;$( doSomethingWith %alias )
```

This exemplary alias source also shows what is currently possible:

* `alias1:` will be expanded to the host address `gsiftp://host.domain.tld:2811`
* `myGridFTP:` maps to `alias1` which itself is again an alias. `myGridFTP:`
will therefore also be expanded to the host address
`gsiftp://host.domain.tld:2811`

> **CAUTION**
> Do not create (expansion) loops (like `myGridFTP:;myGridFTP:`)!

* `alias3:` maps to a so-called *command substitution* and will therefore be
expanded to what `doSomething` prints out.
* `alias4:` is similar to `alias3:` but uses the `%alias` keyword. This keyword
is expanded to the actual alias string (`alias4` in this case) before the
command is executed. This way you can use the alias string inside of the command
substitution.

> **CAUTION**
> To perform the command substitution and to retrieve the output, the `eval`
> command is used internally. Therefore be careful not to map to something like
> `rm -rf ~/*`, as this command would be executed during expansion.

### Alias mapping with directory ###

This uses the same mapping as the file above and will be expanded the same way.

```
$ ls -1 aliases.d
alias1:
myGridFTP:
alias3:
alias4:
```

File contents of `alias1:`
```
gsiftp://host.domain.tld:2811
```

File contents of `myGridFTP:`
```
alias1:
```
Alternatively you could also use a symlink to `alias1:` (saves the time for the
second expansion)


File contents of `alias3:`
```
$( doSomething ) 
```

File contents of `alias4:`
```
$( doSomethingWith %alias )
```

