---
title: Purescript - React Basic Hooks, useAff
---

**This entry might be redundant now, since I've submitted documentation on `useAff`{.codeLine}**

According to the [documentation][useAff], `useAff`{.codeLine} is defined like this.
```Haskell
useAff :: forall key a. Eq key => key -> Aff a -> Hook (UseAff key a) (Result a)
```
`Aff`{.codeLine} is used for asynchronous effects. The [docs][aff] on
`Aff`{.codeLine} is a great place to learn about it!

Back to `useAff`{.codeLine}, when I first encountered this function I didn't
really know what it does. Sure, the type signature gave me some clues, like I
need to give me it some `key`{.codeLine} with the condition that this key has to
have an `Eq`{.codeLine} instance. The second parameter needs an `Aff`{.codeLine}, then it will
return some type [`Hook`{.codeLine}][hook]. Based on the second parameter this tells me
that this is the function I need to make asynchronous effects.

This is my [login component][login-component] using `useAff`{.codeLine} but it didn't start out
like this. My first implementation for `useAff`{.codeLine} was something like this
```Haskell
useAff unit $ do
    submitLogin isSubmitting { email: login.email, password: login.password }
```
I was very confused on why it's only getting called once after render. I also
tried something like this.
```Haskell
useAff "pleaseWork" $ do
    submitLogin isSubmitting { email: login.email, password: login.password }
```
Of course that didn't work. 

I kept going back to this [example][useAff-example] and this [repo][dogs-repo], 
and kept wondering what I'm doing different. Then I had my "eureka" moment. I 
said to myself, "Maybe the `Eq`{.codeLine} constraint has something to do with 
it. Maybe it checks the equality of the `key`{.codeLine} parameter I passed in, 
and if it changes something will happen?" So I changed my implementation to this
```Haskell
useAff login $ do
    submitLogin isSubmitting { email: login.email, password: login.password }
```
`login`{.codeLine} changes when the button is clicked on this [line][setLogin].
It worked!

# Sources:
[Purescript React Basic Hooks Documentation](https://pursuit.purescript.org/packages/purescript-react-basic-hooks/4.2.1)

[Purescript React Basic Hooks Examples](https://github.com/spicydonuts/purescript-react-basic-hooks/tree/master/examples)

[Purescript React Basic Dogs repo by Peter Murphy](https://github.com/ptrfrncsmrph/purescript-react-basic-dogs)

[Purescript Aff Documentation](https://pursuit.purescript.org/packages/purescript-aff/5.1.2)

[Miles Frain](https://github.com/milesfrain) for answering my questions in fpchat

[useAff]: https://pursuit.purescript.org/packages/purescript-react-basic-hooks/4.2.1/docs/React.Basic.Hooks.Aff#v:useAff
[aff]: https://pursuit.purescript.org/packages/purescript-aff/5.1.2
[hook]: https://pursuit.purescript.org/packages/purescript-react-basic-hooks/4.2.1/docs/React.Basic.Hooks.Internal#t:Hook
[login-component]: https://taezos.org/piq9117/notes-examples/src/branch/master/spago-react-hooks-login/src/Component/LoginAff.purs#L23
[useAff-example]: https://github.com/spicydonuts/purescript-react-basic-hooks/blob/master/examples/aff/src/AffEx.purs#L75
[setLogin]: https://taezos.org/piq9117/notes-examples/src/branch/master/spago-react-hooks-login/src/Component/LoginAff.purs#L46 
[dogs-repo]: https://github.com/ptrfrncsmrph/purescript-react-basic-dogs
