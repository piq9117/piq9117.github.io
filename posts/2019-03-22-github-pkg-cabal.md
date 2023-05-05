---
title: Haskell - Github Repos as Haskell Dependencies
---
Thanks to [\@samderbyshire][tweet]
I've figured out how to use the library I've written into one of my other 
project without publishing it to [stackage][stackage] or [hackage][hackage]. It's similar to what
I do in node and bower. Which is to include it in the config file.

Create a `cabal.project`{.codeLine} file and include the following
```yaml
source-repository-package
  type: git
  location: git://github.com/[repo owner]/[the repo you want to include].git

packages: ./*.cabal
```
Then in the `*.cabal`{.codeLine} file include the repository under the 
`build-depends`{.codeLine} section

```yaml
build-depends: base ^>= 4.11.1.0
             , the-repo-you-want-to-include
```
Running `cabal new-build`{.codeLine} should fetch this repository from github
and add it to the dependencies that the project can use.

[tweet]:https://twitter.com/samderbyshire/status/1088838958241538048
[stackage]:https://www.stackage.org/
[hackage]:https://hackage.haskell.org/
