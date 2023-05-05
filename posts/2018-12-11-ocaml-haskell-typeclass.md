---
title: Ocaml - Haskell Typeclasses in Ocaml
---

There are many articles explaining the things I'm about to log about. 
This is just my personal take and understanding on the subject.

I think this is how Haskell Typeclasses are transposed in Ocaml.

```haskell
class Functor f where
  fmap :: (a -> b) -> f a -> f b
```

```ocaml
module type FUNCTOR = sig
  type _ f
  val fmap : ('a -> 'b) -> 'a f -> 'b f
end
```
The most common data types I can think of is the `Maybe`{.codeLine} data type 
from Haskell or the `option`{.codeLine} in Ocaml. These data types are how 
these languages the possibility of `null`{.codeLine}. These data types are 
going to prevent us from encoutering `NullReferenceException`{.codeLine} 
like in other languages.

```haskell
data Maybe a 
  = Nothing
  | Just a
```

```ocaml
type 'a option
  = None
  | Some of 'a
```
Maybe and Option instance of the `Functor`{.codeLine} typeclass.

```haskell
instance Functor Maybe where
  fmap f Nothing = None
  fmap f (Just a) = Just (f a)
```

```ocaml
module OptionF : (FUNCTOR with type 'a f = 'a option) = struct
  type 'a f = 'a option
  let fmap f = function
  | None -> None
  | Some a -> Some (f a)
end
```

### In Action

```haskell
capitalize :: Maybe Text -> Maybe Text
capitalize name = fmap toUpper name
```
In ghci
```bash
gchi> capitalize (Just "John")
ghci> Just "JOHN"
```
The main difference here is I have to specify which `fmap`{.codeLine} I have to
use because Ocaml's typesystem is not as powerful as Haskell's where it will
immediately determine which `fmap`{.codeLine} to use just based on the type.

```ocaml
let capitalize (name : string option) =
  OptionF.fmap Js.String.toUpperCase name
  
let _ = Js.log @@ capitalize (Some "John")
```
Bucklescript will represent `Some`{.codeLine} as an array.
```bash
> ["JOHN"]
```
