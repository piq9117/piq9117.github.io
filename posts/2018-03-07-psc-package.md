---
title: Purescript - Using psc-package instead of Bower
---
I have been using [Bower][bower] to manage purescript dependencies. This relies 
on [node][node] and Bower to manage the packages. The problem is that there's 
not a lot of users using Bower these days, meaning Bower is not well maintained 
anymore. 

The purescript community has been trying to liberate purescript from node and 
bower. So they have made [psc-package][psc-package]. 

Download the [source][psc-source], extract, then build with `stack build`{.codeLine}. After
the compilation, run `stack install`{.codeLine}. This will install the executable in the 
local bin-path. `psc-package`{.codeLine} is now ready to be used.

To start a project run `pulp build`{.codeLine} to scaffold the project. This will generate
the `Main`{.codeLine} directory with the `Main.purs`{.codeLine} file and `Test`{.codeLine} directory with the
`Test.purs`{.codeLine} file. This will also generate `bower.json`{.codeLine} file. Delete this file
since we will not be using bower anymore. Run `psc-package init`{.codeLine} to  generate 
`psc-package.json`{.codeLine}.

Important sections to note about the `psc-package.json`{.codeLine} file is the `sets`{.codeLine} and 
`depends`{.codeLine} field. `sets`{.codeLine} is the set of packages, and the contents of the set is 
based on the version. So if the package we're trying to install is missing check
the version we may not have the right version. To check which package is 
included in the list go to [package-sets][psc-sets]. I believe package-sets are 
packages blessed by the community.

To install packages run `psc-package install <package-name>`{.codeLine} or put the package 
name in the `depends`{.codeLine} section of `psc-package.json`{.codeLine} and run `psc-package build`{.codeLine}.

[bower]: https://bower.io/
[node]: https://nodejs.org/en/
[psc-package]: https://github.com/purescript/psc-package
[psc-source]: https://github.com/purescript/psc-package/releases
[psc-sets]: https://github.com/purescript/package-sets
