> [!CAUTION]
> **THIS REPO IS ARCHIVED**
> 
> In the context of the [git migration](https://archlinux.org/news/git-migration-announcement/) using `asp` has been deprecated in favor of `pkgctl` or plain `git`.
> 
> For details see the respective wiki entry: https://wiki.archlinux.org/title/Arch_build_system#Retrieve_PKGBUILD_source

---

# asp

`asp` is a tool to manage the build source files used to create Arch Linux
packages. It replaces the `abs` tool, offering more up to date sources (via the
svntogit repositories) and uses a sparse checkout model to conserve diskspace.
This probably won't be interesting to users who want a full checkout (for
whatever reason that may be).

# Setup

None! Though, it should be noted that the `ASPROOT` environment variable
will control where `asp` keeps its local git repo. By default, this is
`${XDG_CACHE_HOME:-$HOME/.cache}/asp`.

# Examples

Get the source files for some packages:

~~~
asp export pacman testing/systemd extra/pkgfile
~~~

Get a fully functional git checkout of a single package:

~~~
asp checkout pkgfile
~~~

List the repositories a package has been pushed to:

~~~
asp list-repos pacman
~~~

