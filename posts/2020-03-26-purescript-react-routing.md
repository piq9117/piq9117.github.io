---
title: Purescript - React Basic Hooks Routing
---

When I started doing web applications with purescript react and halogen I had no
clue how to do things. One of those things is routing. It wasn't that hard for
halogen because of the [realworld example][halogen-realworld]. It's built ready
for production. It even has great documentation!

Unfortunately, when it came to [react-basic-hooks][react-basic-hooks] this
information wasn't readily available. So here's my take on routing with
react-basic/react-basic-hooks.

The router component is the parent of all the components. The router component
will decide which component to render depending on the `Route`{.codeLine}.

## Router

```haskell
module Component.Router where

import Prelude
import Data.Either ( hush )
import Data.Maybe ( fromMaybe )
-- Internal Page
import Page.Home as Home
import Page.About as About
-- Internal Service
import Service.Route
import Service.Navigate
-- Internal Component
import Component.Store ( mkRouteStore )
-- Effect
import Effect ( Effect )
-- Routing
import Routing.Duplex ( parse )
import Routing.Hash ( getHash )
-- React
import React.Basic.Hooks ( ReactComponent, ReactContext )
import React.Basic.Hooks as React
import React.Basic.DOM as RD
import React.Basic.Events as RE

mkComponent :: Effect ( ReactComponent {} )
mkComponent = do
  -- Grab initial route. 
  -- This will try to match the browser's hash route. 
  mInitialRoute <- hush <<< ( parse routeCodec ) <$> getHash
  -- If it doesn't find a match it will default to the home route.
  -- Then a context is created on that route.
  routeContext <- React.createContext ( fromMaybe Home mInitialRoute )
  store <- mkRouteStore routeContext
  nav <- mkRouter routeContext
  React.component "RouterContainer" \props -> do
    pure $ React.element store { content: [ React.element nav {} ]}

-- This is the function that will match Route and render the right element that
-- matches that route.
mkRouter
  :: ReactContext Route
  -> Effect ( ReactComponent {} )
mkRouter routeContext = do
  home <- Home.mkComponent
  about <- About.mkComponent
  navbar <- mkNavbar
  React.component "Router" \props -> React.do
    route <- React.useContext routeContext
    pure
      $ React.fragment
        [ React.element navbar {}
        , case route of
             Home -> React.element home {}
             About -> React.element about {}
        ]

mkNavbar :: Effect ( ReactComponent {} )
mkNavbar =
  React.component "Navbar" $ const $ do
    pure
      $ RD.nav
        { children:
          [ RD.button
            { children: [ RD.text "Home" ]
            , onClick: RE.handler_ $ navigate Home
            }
          , RD.button
            { children: [ RD.text "About" ]
            , onClick: RE.handler_ $ navigate About
            }
          ]
        }
```

## Route
This is how `Route`{.codeLine} is defined. It's a sum type of all possible routes in the application. The rest of this
code is definition for the [routing-duplex][routing-duplex] interpreter and
printer. The routes can be directly written as strings but safety with types is what
I prefer; [routing][routing] and [routing-duplex] provide that for me.

```haskell
module Service.Route where

import Prelude hiding ((/))

-- Generic
import Data.Generic.Rep ( class Generic )
import Data.Generic.Rep.Show ( genericShow )
-- Routing
import Routing.Duplex
import Routing.Duplex.Generic
import Routing.Duplex.Generic.Syntax ( (/) )

-- All possible routes in the application
data Route
  = Home
  | About

derive instance genericRoute :: Generic Route _
derive instance eqRoute :: Eq Route
derive instance ordRoute :: Ord Route

instance showRoute :: Show Route where
  show = genericShow

routeCodec :: RouteDuplex' Route
routeCodec = root $ sum
  { "Home": noArgs
  , "About": "about" / noArgs
  }
```

## Page
The page components are defined [here][notes-page-example]. They're trivially
defined components that will display the text "Home" and "About". In a non-trivial app,
these would be the components that will encapsulate an entire page.

## Route Store
This is the component that will watch the route changes. Everytime the hash route changes,
it will run `setRoute`{.codeLine} and updates the `Route`{.codeLine}. This
component will then pass it on to its `content`{.codeLine}.
```haskell
module Component.Store where

import Prelude
import Data.Maybe ( Maybe(..) )
-- Internal Service
import Service.Route
-- Effect
import Effect ( Effect )
-- Routing
import Routing.Hash ( matchesWith )
import Routing.Duplex ( parse )
-- React
import React.Basic.Hooks ( ReactComponent, ReactContext, (/\), JSX )
import React.Basic.Hooks as React

mkRouteStore :: ReactContext Route -> Effect ( ReactComponent { content :: Array JSX } )
mkRouteStore context =
  React.component "Store" \props -> React.do
    r <- React.useContext context
    route /\ setRoute <- React.useState r
    React.useEffect route $ matchesWith ( parse routeCodec ) \mOld new -> do
      when ( mOld /= Just new ) $ setRoute $ const new
    pure
      $ React.provider context route props.content
```

## Navigation
The only capability of this app is navigation, but if there are other capabilities
like requesting data, logging, and authentication it will also be defined
similar to this.

```haskell
module Service.Navigate where

import Prelude
-- Internal Service
import Service.Route
-- Effect
import Effect ( Effect )
-- Routing
import Routing.Duplex
import Routing.Hash

class Monad m <= Navigate m where
  navigate :: Route -> m Unit

instance navigateEffect :: Navigate Effect where
  navigate = setHash <<< print routeCodec
```
I thought this was a great article on
[tagless-final-encoding][tagless-final-encoding]. This is the technique being
used here. Code re-use can be easier achieved with this technique because I don't
have to change big chunks of the app if I need to implement it in another
context. This app runs on `Effect`{.codeLine} so I only have to define an instance for
that. If the application needs to run on `Aff`{.codeLine} then I'll define a new
instance for `Aff`{.codeLine}

React runs on `Effect`{.codeLine} so that's why I've defined an `Effect`{.codeLine} instance.

## Main
Finally, the `Main`{.codeLine} module. This is where
purescript-react-basic-hooks runs application. Nothing really special, it looks
for an element with `id`{.codeLine} of `app`{.codeLine} then appends the
application to that DOM node.
```haskell
module Main where

import Prelude
import Data.Maybe ( Maybe(..) )
-- Web
import Web.DOM.NonElementParentNode ( getElementById )
import Web.HTML.HTMLDocument ( toNonElementParentNode )
import Web.HTML.Window ( document )
import Web.HTML ( window )
-- Internal
import Component.Router as Router
-- Effect
import Effect ( Effect )
import Effect.Exception ( throw )
-- React
import React.Basic.Hooks ( element )
import React.Basic.DOM as R

main :: Effect Unit
main = do
  mApp <- getElementById "app" =<< ( map toNonElementParentNode $ document =<< window )
  case mApp of
    Nothing -> throw "App element not found."
    Just app -> do
      mainComponent <- Router.mkComponent
      R.render ( element mainComponent {} ) app
```
## Sources

[Purescript Halogen Realworld][halogen-realworld]

[React Basic Hooks][react-basic-hooks]

[Routing Duplex][routing-duplex]

[Routing][routing]

[Tagless Final Encoding by Juan Pablo Royo][final-tagless-encoding]

[Introduction to Tagless Final by Serokell][tagless-final-intro]

[halogen-realworld]:https://github.com/thomashoneyman/purescript-halogen-realworld
[react-basic-hooks]:https://pursuit.purescript.org/packages/purescript-react-basic-hooks/4.2.2
[routing-duplex]:https://github.com/natefaubion/purescript-routing-duplex
[routing]:https://pursuit.purescript.org/packages/purescript-routing/9.0.0
[notes-page-example]:https://www.taezos.org/piq9117/notes-examples/src/branch/master/react-context-router/src/Page
[routing-gethash]:https://pursuit.purescript.org/packages/purescript-routing/9.0.0/docs/Routing.Hash#v:getHash
[final-tagless-encoding]:https://jproyo.github.io/posts/2019-03-17-tagless-final-haskell.html
[tagless-final-encoding]:https://jproyo.github.io/posts/2019-03-17-tagless-final-haskell.html
[routing-matcheswith]:https://pursuit.purescript.org/packages/purescript-routing/9.0.0/docs/Routing.Hash#v:matchesWith
[tagless-final-intro]:https://serokell.io/blog/tagless-final
