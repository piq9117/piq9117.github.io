---
title: Haskell - Generating lenses for third party libraries
---
This is going to be a short post, maybe even a tweet size post. I'm going to
highlight how to generate lenses for third party libraries because when I was
searching for this information it wasn't that easy to find. 

My concern was less on the mechanics on how to generate them but more on best
practices, I wasn't sure if generating lenses for data types I don't own is good
practice. When I asked in [fp-chat][fp-chat], I was told to "Go hog wild!" and
didn't get any opposing views. So that gave me the peace of mind to do this.

I'm going to use the [purescript language library][purescript] as an example since it's the
most recent library I had to work with.

I'm going to use `makeLenses`{.codeLine} from `Control.Lens.TH`{.codeLine}. 
The default configuration of `makeLenses`{.codeLine} is it will only generate
lenses for record fields that are prefixed with an underscore. 

```haskell
data Person = Person
  { firstName :: Text -- does not generate lens for this field.
  , _lastName :: Text -- generates the lens for this field.
  } deriving ( Eq, Show )

makeLenses ''Person
```

Before I can start generating lenses for the types I don't own, I have to change
the `makeLenses`{.codeLine} configuration a little bit. 
```haskell
module Util where

import           Language.Haskell.TH
import           Control.Lens.Operators
import           Control.Lens.TH

mkCustomLenses :: Name -> DecsQ
mkCustomLenses = makeLensesWith
  $ lensRules
  & lensField
  .~ (\_ _ name -> [TopName ( mkName $ nameBase name ++ "L" )]) -- you can append whatever suits your code base here, I chose to append "L"
```

It has to be in a separate module from where you generate the lenses because the
compiler will complain with this error
```sh
GHC stage restriction:
      `mkCustomLenses' is used in a top-level splice, quasi-quote, or annotation,
      and must be imported, not defined locally
```
After that setup you can start generating lenses!
```haskell
module Optics where

-- util
import           Util

-- purescript
import           Language.PureScript.CST.Types

makePrisms ''Declaration
makePrisms ''Guarded
makePrisms ''Expr

mkCustomLenses ''ValueBindingFields
mkCustomLenses ''Name
mkCustomLenses ''Ident
mkCustomLenses ''Labeled
mkCustomLenses ''Where
mkCustomLenses ''Wrapped
mkCustomLenses ''Separated
mkCustomLenses ''Module
```

Now, if I want to manipulate `Separated`{.codeLine} I can do something like
```haskell
updateToEmptyList :: Separated a -> Separated a
updateToEmptyList s = s & sepTailL .~ []
```

When it comes to sum types you can just use `makePrisms`{.codeLine} to generate prisms.

# Sources

[Optics by Example - Chris Penner][optics-by-example]

[Lens Tutorial][lens-tutorial]

[fp-chat]:https://fpchat-invite.herokuapp.com/
[purescript]:https://hackage.haskell.org/package/purescript-0.13.8/docs/Language-PureScript-CST-Types.html
[optics-by-example]: https://leanpub.com/optics-by-example
[lens-tutorial]: https://hackage.haskell.org/package/lens-tutorial-1.0.4/docs/Control-Lens-Tutorial.html
