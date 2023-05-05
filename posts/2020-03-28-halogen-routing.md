---
title: Purescript - Halogen Routing
---
This entry will be pretty similar to my previous purescript-react-basic-hooks
routing entry. Where I go over how routing works within the framework. This time
it will be be using the halogen UI framework.

Thanks to the [halogen realworld example][halogen-realworld] it was easy to figure out
how to do routing in halogen. 

Here's my understanding of it. I'll and try and extract the routing part of the
example and focus on that in this entry.

## Router
First off, the router component. This component is the parent component. It's
the component that will decide what to render based on the route that's being
queried to it. The `render`{.codeLine} function `case`{.codeLine} matches on
the `Route`{.codeLine} then renders the component. 

```haskell
module Component.Router where

import Prelude
import Data.Maybe ( Maybe(..), fromMaybe )
import Data.Either ( hush )
-- Internal Page
import Page.Home as Home
import Page.About as About
-- Internal Service
import Service.Route
import Service.Navigate
-- Web
import Web.Event.Event ( preventDefault )
import Web.UIEvent.MouseEvent ( toEvent, MouseEvent )
-- Effect
import Effect.Class ( class MonadEffect, liftEffect )
-- Routing
import Routing.Duplex
import Routing.Hash
-- Halogen
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.HTML.Events as HE

type State =
  { route :: Maybe Route
  }

data Query a = Navigate Route a

data Action
  = Initialize
  | GoTo Route MouseEvent

type ChildSlots =
  ( home :: Home.Slot Unit
  , about :: About.Slot Unit
  )

component
  :: forall i o m
  . MonadEffect m
  => Navigate m
  => H.Component HH.HTML Query i o m
component =
  H.mkComponent
  { initialState: const { route: Nothing }
  , render
  , eval: H.mkEval $ H.defaultEval
    { handleAction = handleAction
    , handleQuery = handleQuery
    , initialize = Just Initialize
    }
  }

-- Renders a page component depending on which route is matched.
render :: forall m. State -> H.ComponentHTML Action ChildSlots m
render st = navbar $ case st.route of
  Nothing -> HH.h1_ [ HH.text "Oh no! That page wasn't found" ]
  Just route -> case route of
    Home -> HH.slot Home._home unit Home.component unit absurd
    About -> HH.slot About._about unit About.component unit absurd

handleAction
  :: forall o m
  . MonadEffect m
  => Navigate m
  => Action
  -> H.HalogenM State Action ChildSlots o m Unit
handleAction = case _ of
  -- Handles initialization of the route
  Initialize -> do
    initialRoute <- hush <<< ( parse routeCodec ) <$> H.liftEffect getHash
    navigate $ fromMaybe Home initialRoute
  --  Handles the consecutive route changes.
  GoTo route e -> do
    liftEffect $ preventDefault ( toEvent e )
    mRoute <- H.gets _.route
    when ( mRoute /= Just route ) $ navigate route

handleQuery :: forall a o m. Query a -> H.HalogenM State Action ChildSlots o m ( Maybe a )
handleQuery = case _ of
  -- This is the case that runs every time the brower's hash route changes.
  Navigate route a -> do
    mRoute <- H.gets _.route
    when ( mRoute /= Just route ) $
      H.modify_ _ { route = Just route }
    pure ( Just a )

navbar :: forall a . HH.HTML a Action -> HH.HTML a Action
navbar html =
  HH.div_
  [ HH.ul_
    [ HH.li_
      [ HH.a
        [ HP.href "#"
        , HE.onClick ( Just <<< GoTo Home )
        ]
        [ HH.text "Home" ]
      ]
    , HH.li_
      [ HH.a
        [ HP.href "#"
        , HE.onClick ( Just <<< GoTo About )
        ]
        [ HH.text "About" ]
      ]
    ]
  , html
  ]
```

## Page
This is how these [pages][notes-page-example] are defined. These components will
render the text **Home** and **About**. In a non-trivial application, these
components will hold several components to form a "page", but for simplicity I
left them off to just render text inside an `h1`{.codeLine}.

## Route
The key thing here is the `Route`{.codeLine} sum type. These are all the
possible routes in the application. The rest of the code is for
[routing-duplex][routing-duplex] to help me encode and decode the routes. The
routes can be directly written as strings but I prefer the safety of types.
Plus, the string definition only stays here. So this lessens the fishing
later on **if ever there is** a bug in the routing.

```haskell
module Service.Route where

import Prelude
import Data.Generic.Rep ( class Generic )
import Data.Generic.Rep.Show ( genericShow )
-- Routing
import Routing.Duplex ( RouteDuplex', root )
import Routing.Duplex.Generic ( noArgs, sum )
import Routing.Duplex.Generic.Syntax ((/))

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

## Navigation
Navigation capbility of this app is defined in a type class. This technique is
known as [tagless-final-encoding][tagless-final-encoding]. It's a technique
where we define a capability or method without concrete implementations and only
a small set of requirements. In this case, the minimum requirement is it needs to
be a `Monad`{.codeLine}. Then, an instance for `HalogenM`{.codeLine} is defined
here to save us from calling `lift`{.codeLine} everywhere inside the action (e.g
`lift $ navigate Home`{.codeLine}).

```haskell
module Service.Navigate where

import Prelude

-- Internal Route
import Service.Route
-- Halogen
import Halogen

class Monad m <= Navigate m where
  navigate :: Route -> m Unit

instance navigateHalogenM :: Navigate m => Navigate ( HalogenM state action slots msg m ) where
  navigate = lift <<< navigate

```

## AppM
`AppM`{.codeLine} is a custom application monad that will provide concrete
implementation for the capabilities, in this case it will only implement
`Navigation`{.codeLine}. As you'll notice this only provides a natural
transformation from `AppM`{.codeLine} to `Aff`{.codeLine}. In a typical
application this will wrap the [ReaderT pattern][readert-pattern]. This is also
the technique used in the [halogen real world example][halogen-realworld]. I
learned about this pattern [here][three-layer-haskell].

```haskell
module AppM where

import Prelude
-- Internal Service
import Service.Navigate
import Service.Route
-- Effect
import Effect.Class ( class MonadEffect, liftEffect )
-- Aff
import Effect.Aff ( Aff )
import Effect.Aff.Class ( class MonadAff )
-- Routing
import Routing.Hash ( setHash )
import Routing.Duplex ( print )

newtype AppM a = AppM ( Aff a )

runAppM :: AppM ~> Aff
runAppM ( AppM m ) = m

derive newtype instance functorAppM :: Functor AppM
derive newtype instance applyAppM :: Apply AppM
derive newtype instance applicativeAppM :: Applicative AppM
derive newtype instance bindAppM :: Bind AppM
derive newtype instance monadAppM :: Monad AppM
derive newtype instance monadEffectAppM :: MonadEffect AppM
derive newtype instance monadAffAppM :: MonadAff AppM

instance navigateAppM :: Navigate AppM where
  navigate = liftEffect <<< setHash <<< print routeCodec
```

## Main
Finally, the `Main`{.codeLine} module. This is where the application is ran.
This is also the place where the browser's route is observed. Whenever the route
changes the callback of `matchesWith`{.codeLine} will be called. This callback
will query the router component with `Navigate`{.codeLine} passing the
`new`{.codeLine} route.

```haskell
module Main where

import Prelude
import Data.Maybe ( Maybe(..) )
-- Internal
import AppM ( runAppM )
-- Internal Components
import Component.Router as Router
-- Internal Service
import Service.Route
-- Effect
import Effect ( Effect )
import Effect.Class ( liftEffect )
-- Aff
import Effect.Aff ( Aff, launchAff_ )
-- Routing
import Routing.Duplex ( parse )
import Routing.Hash ( matchesWith )
-- Halogen
import Halogen as H
import Halogen.HTML as HH
import Halogen.Aff as HA
import Halogen.VDom.Driver ( runUI )

main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody
  let
    rootComponent :: H.Component HH.HTML Router.Query {} Void Aff
    rootComponent = H.hoist runAppM Router.component

  -- Run the application
  halogenIO <- runUI rootComponent {} body

  -- Listen to the route changes.
  void $ liftEffect $ matchesWith ( parse routeCodec ) \mOld new ->
    when ( mOld /= Just new ) do
      launchAff_ $ halogenIO.query $ H.tell $ Router.Navigate new
  pure unit
```

## Sources

[Purescript Halogen Realworld Example][halogen-realworld]

[Tagless Final Encoding][tagless-final-encoding]

[ReaderT Design Pattern][readert-pattern]

[Three Layer Haskell Cake][three-layer-haskell]

[halogen-realworld]:https://github.com/thomashoneyman/purescript-halogen-realworld
[notes-page-example]:https://www.taezos.org/piq9117/notes-examples/src/branch/master/halogen-routing/src/Page
[routing-duplex]:https://github.com/natefaubion/purescript-routing-duplex
[tagless-final-encoding]:https://jproyo.github.io/posts/2019-03-17-tagless-final-haskell.html
[readert-pattern]:https://www.fpcomplete.com/blog/2017/06/readert-design-pattern
[three-layer-haskell]:https://www.parsonsmatt.org/2018/03/22/three_layer_haskell_cake.html
