---
title: Haskell - My setup/Workflow
---

Tools:

* [ghcid][ghcid]

* [doom-emacs][doom-emacs]

* [stylish-haskell][stylish-haskell]

* [cabal][cabal]

* [stack][stack]

* [nixpkgs][nixpkgs]

My setup matches my personality and that is I always go for the bare minimum. I
download all these tools using [nixpkgs][nixpkgs] and I enable haskell-mode in
[doom-emacs][doom-emacs]. That's it! I start writing Haskell.

Once I start writing Haskell I have another terminal open that runs
[ghcid][ghcid]. It has very fast development feedback loop, it's how I know if
my types are matching. I use [typed-holes][typed-holes] heavily so ghcid can
tell me what types I need for a section of my code.

Here's a contrived example

```haskell
add :: Integer -> Integer -> Integer
add x y = x `_whatdo` y
```
This will be ghcid's response in the repl
```bash
<interactive>:3:13: error:
    • Found hole: _what :: Integer -> Integer -> Integer
      Or perhaps ‘_what’ is mis-spelled, or not in scope
    • In the expression: _what
      In the expression: x `_what` y
      In an equation for ‘add’: add x y = x `_what` y
    • Relevant bindings include
        y :: Integer (bound at <interactive>:3:7)
        x :: Integer (bound at <interactive>:3:5)
        add :: Integer -> Integer -> Integer (bound at <interactive>:3:1)
      Valid hole fits include
        add :: Integer -> Integer -> Integer (bound at <interactive>:3:1)
        seq :: forall a b. a -> b -> b
          with seq @Integer @Integer
          (imported from ‘Prelude’
           (and originally defined in ‘ghc-prim-0.5.3:GHC.Prim’))
        (-) :: forall a. Num a => a -> a -> a
          with (-) @Integer
          (imported from ‘Prelude’ (and originally defined in ‘GHC.Num’))
        asTypeOf :: forall a. a -> a -> a
          with asTypeOf @Integer
          (imported from ‘Prelude’ (and originally defined in ‘GHC.Base’))
        const :: forall a b. a -> b -> a
          with const @Integer @Integer
          (imported from ‘Prelude’ (and originally defined in ‘GHC.Base’))
        max :: forall a. Ord a => a -> a -> a
          with max @Integer
          (imported from ‘Prelude’
           (and originally defined in ‘ghc-prim-0.5.3:GHC.Classes’))
        (Some hole fits suppressed; use -fmax-valid-hole-fits=N or -fno-max-valid-hole-fits)
```
This tells me that I need a function that takes two `Integer` that also outputs
an `Integer`. This even tells me the "Relevant bindings" and "Valid hole fits"
which is amazing. ghcid helps as much as it can. This flow goes a very long 
way. It starts getting hazy for me when it comes to [lens][lens] errors, 
but I'm sure if I use lens more often I'll be able to decipher what ghcid 
is telling me much quickly. This even works in the type level.

```haskell
add :: _whatdo
add x y = x + y
```
ghcid repl will respond with
```bash
<interactive>:8:1: error:
    • Couldn't match expected type ‘_whatdo’
                  with actual type ‘Integer -> Integer -> Integer’
      ‘_whatdo’ is a rigid type variable bound by
        the type signature for:
          add :: forall _whatdo. _whatdo
        at <interactive>:7:1-14
    • The equation(s) for ‘add’ have two arguments,
      but its type ‘_whatdo’ has none
    • Relevant bindings include
        add :: _whatdo (bound at <interactive>:8:1)
```
ghcid is the reason I don't use any IDE or any fancy editor plugins. I only have
syntax highlighting and some formatting in my emacs.

When it comes to actually running my code I usually use [cabal][cabal]. After
ghcid tells me my code is clear I run
```bash
cabal new-build
cabal new-run
```
Sometimes I use [stack][stack] because of [yesod][yesod]. That's mostly for work.

I'm aware of the holy war between stack, cabal, and nix, I hope this blog doesn't get
involved in that war. I use all of them. They all have a spot in my workflow.

[ghcid]: https://github.com/ndmitchell/ghcid
[doom-emacs]: https://github.com/hlissner/doom-emacs
[stylish-haskell]: https://github.com/jaspervdj/stylish-haskell
[cabal]: https://www.haskell.org/cabal/
[stack]: https://docs.haskellstack.org/en/stable/README/
[nixpkgs]: https://github.com/NixOS/nixpkgs
[type-holes]: https://wiki.haskell.org/GHC/Typed_holes
[lens]: https://www.stackage.org/lts-14.16/package/lens-4.17.1
[yesod]: https://github.com/yesodweb/yesod
[typed-holes]:https://downloads.haskell.org/~ghc/7.10.1/docs/html/users_guide/typed-holes.html
