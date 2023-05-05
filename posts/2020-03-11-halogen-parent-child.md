---
title: Purescript - Parent - Child Components in Halogen
---

Parent-Child component communication is already part of the halogen 
[examples][halogen-example] and [guide][halogen-guide].
This entry is just my own understanding of how Parent-Child component
communication works.

# Rendering
Let's start with rendering a child component inside a parent component. In other 
frameworks this is called transclusion/multitransclusion (angular), slots (vue),
and in react I think it's called component composition. In Halogen, this can be
acheived with what they call `Child Slots`{.codeLine}. The concept is pretty similar
to existing front end frameworks.

### Child component
Let's define the child component.
```haskell
module Component.Child where

import Prelude

-- Halogen
import Halogen as H
import Halogen.HTML as HH

type Slot = forall query. H.Slot query Void Unit

component :: forall q i o m. H.Component HH.HTML q i o m
component =
  H.mkComponent
  { initialState: identity
  , render
  , eval: H.mkEval H.defaultEval
  }

render :: forall state action m. state -> H.ComponentHTML action () m
render _ =
  HH.h2_
  [ HH.text "Child"
  ]
```

### Parent component
Now, the parent component with the slot and the child component.
```haskell
module Component.Parent where

import Prelude
import Data.Symbol ( SProxy (..) )
-- Internal
import Component.Child as Child
-- Halogen
import Halogen as H
import Halogen.HTML as HH

type ChildSlots =
  ( child :: Child.Slot
  )

component :: forall q i o m. H.Component HH.HTML q i o m
component =
  H.mkComponent
  { initialState: identity
  , render
  , eval: H.mkEval H.defaultEval
  }

render :: forall action state m. state -> H.ComponentHTML action ChildSlots m
render _ =
  HH.div_
  [ HH.h1_ [ HH.text "Parent" ]
  , HH.hr []
  , HH.slot ( SProxy :: _ "child" )  unit Child.component {} absurd
  ]
```
This will render the child component in the parent component.

### Child to Parent component communication
The key to child-parent component communication is acheived with the use of 
`raise`{.codeLine}. This is how the child component can send messages
that the parent can then listen to. According to the [docs][raise-documentation]
this is how `raise`{.codeLine} is defined.
```haskell
raise :: forall s f g p o m. o -> HalogenM s f g p o m Unit
```

Here's the child component again, using `raise`{.codeLine} in the 
`handleActions`{.codeLine} function.
```haskell
module Component.Child where

import Prelude
import Data.Maybe ( Maybe(..) )
-- Halogen
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE

type Slot = forall query. H.Slot query OutputMessage Unit

data Action = HandleClick

data OutputMessage = ButtonClick Int

component :: forall q m. H.Component HH.HTML q Unit OutputMessage m
component =
  H.mkComponent
  { initialState: identity
  , render
  , eval: H.mkEval $ H.defaultEval
    { handleAction = handleAction }
  }

render :: forall state m. state -> H.ComponentHTML Action () m
render _ =
  HH.div_
  [ HH.h2_ [ HH.text "Child" ]
  , HH.button
    [ HE.onClick ( const $ Just Click )
    ]
    [ HH.text "Send clicks to parent"]
  ]

handleAction :: forall m. Action -> H.HalogenM Unit Action () OutputMessage m Unit
handleAction = case _ of
  HandleClick -> do
    H.raise ( ButtonClick 1 )
```
And here's how the parent component can listen to that output message.
You'll notice that the constructor of `Action`{.codeLine} has 
`Child.OutputMessage`{.codeLine} input. This input is handled in the
`handleAction`{.codeLine} function.

```haskell
module Component.Parent where

import Prelude
import Data.Symbol ( SProxy (..) )
import Data.Maybe ( Maybe(..) )
-- Internal
import Component.Child as Child
-- Halogen
import Halogen as H
import Halogen.HTML as HH

type ChildSlots =
  ( child :: Child.Slot
  )

data Action
  = HandleChildMsg Child.OutputMessage

type State =
  { clickCount :: Int
  }

component :: forall q i o m. H.Component HH.HTML q i o m
component =
  H.mkComponent
  { initialState: const { clickCount: 0 }
  , render
  , eval: H.mkEval $ H.defaultEval
    { handleAction = handleAction }
  }

render :: forall m. State -> H.ComponentHTML Action ChildSlots m
render st =
  HH.div_
  [ HH.h1_ [ HH.text "Parent" ]
  , HH.div_ [ HH.text $ show st.clickCount ]
  , HH.hr []
  , HH.slot ( SProxy :: _ "child" )  unit Child.component unit ( Just <<< HandleChildMsg )
  ]

handleAction :: forall o m. Action -> H.HalogenM State Action ChildSlots o m Unit
handleAction = case _ of
  HandleChildMsg ( Child.ButtonClick n ) -> do
    count <- H.gets _.clickCount
    H.modify_ _ { clickCount = count + n }
```
Then `handleAction`{.codeLine} function then matches 
`HandleChildMsg Child.OutputMessage`{.codeLine} and modifies the state of the
parent component.

### Parent to Child component communication
Now for the parent to send messages to the child component. Let's modify the 
child component to receive messages.

First create the type of `Input`{.codeLine}. 
```haskell
type Input =
  { messageFromParent :: String
  }
```
This will replace the `i`{.codeLine} type variable in the `component`{.codeLine}
function. 

The key to receiving messages/input from the parent component is by providing the 
`receive`{.codeLine} field in `H.defaultEval`{.codeLine} with an action. 
According to the source, `receive`{.codeLine} is defined like this
```haskell
receive :: input -> Maybe action
```
So we provide the `receive`{.codeLine} field with 
`\input -> Just $ HandleReceiveMessage input`{.codeLine}, for that extra FP
points we'll provide it wit this this point free function 
`Just <<< HandleRecieveMessage`{.codeLine}. This action will then be handled
in the `handleAction` function and update the state as desired.

```haskell
module Component.Child where

import Prelude
import Data.Maybe ( Maybe(..) )
-- Halogen
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE

type Slot = forall query. H.Slot query OutputMessage Unit

data Action
  = HandleClick
  | HandleReceiveMessage Input

type State =
  { message :: String
  }

data OutputMessage = ButtonClick Int

type Input =
  { messageFromParent :: String
  }

component :: forall q m. H.Component HH.HTML q Input OutputMessage m
component =
  H.mkComponent
  { initialState: const $ { message: "" }
  , render
  , eval: H.mkEval $ H.defaultEval
    { handleAction = handleAction
    , receive = ( Just <<< HandleReceiveMessage )
    }
  }

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div_
  [ HH.h2_ [ HH.text "Child" ]
  , HH.button
    [ HE.onClick ( const $ Just HandleClick )
    ]
    [ HH.text "Send clicks to parent"]
  , HH.h5_ [ HH.text "Message from parent" ]
  , HH.text st.message
  ]

handleAction :: forall m. Action -> H.HalogenM State Action () OutputMessage m Unit
handleAction = case _ of
  HandleClick -> do
    H.raise ( ButtonClick 1 )

  HandleReceiveMessage str ->
    H.modify_ _ { message = str.messageFromParent }
```

Now, let's make the modification the parent component.

First, let's change the input parameter in the child slot from `unit`{.codeLine}
to `{ messageFromParent: st.messageToChild }`{.codeLine} in the
`render`{.codeLine} function. The field `messageFromParent`{.codeLine} is what 
the child component is expecting and `st.messageToChild`{.codeLine} is the 
piece of state from the parent component that we'll send to the child component.
```haskell
module Component.Parent where

import Prelude
import Data.Symbol ( SProxy (..) )
import Data.Maybe ( Maybe(..) )
-- Internal
import Component.Child as Child
-- Halogen
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE

type ChildSlots =
  ( child :: Child.Slot
  )

data Action
  = HandleChildMsg Child.OutputMessage
  | HandleInput String
  | SendMessageToChild

type State =
  { clickCount :: Int
  , message :: String
  , messageToChild :: String
  }

component :: forall q i o m. H.Component HH.HTML q i o m
component =
  H.mkComponent
  { initialState: const { clickCount: 0, message: "", messageToChild: "" }
  , render
  , eval: H.mkEval $ H.defaultEval
    { handleAction = handleAction }
  }

render :: forall m. State -> H.ComponentHTML Action ChildSlots m
render st =
  HH.div_
  [ HH.h1_ [ HH.text "Parent" ]
  , HH.div_
    [ HH.input
      [ HE.onValueInput ( Just <<< HandleInput )
      ]
    , HH.button
      [ HE.onClick ( const $ Just SendMessageToChild )
      ]
      [ HH.text "Send message to child component" ]
    ]
  , HH.h5_ [ HH.text "Clicks from child component" ]
  , HH.div_ [ HH.text $ show st.clickCount ]
  , HH.hr []
  , HH.slot ( SProxy :: _ "child" ) unit Child.component { messageFromParent: st.messageToChild } ( Just <<< HandleChildMsg )
  ]

handleAction :: forall o m. Action -> H.HalogenM State Action ChildSlots o m Unit
handleAction = case _ of
  HandleChildMsg ( Child.ButtonClick n ) -> do
    count <- H.gets _.clickCount
    H.modify_ _ { clickCount = count + n }

  HandleInput str ->
    H.modify_ _ { message = str }

  SendMessageToChild -> do
    msg <- H.gets _.message
    H.modify_ _ { messageToChild = msg }
```
The parent component is first updating the `message`{.codeLine} field in the 
state based on the input element. Then, when the button is clicked it will update
`messageToChild`{.codeLine} with the value from `message`{.codeLine}.

The project and it's entirety is [here][notes-example-repo]. Clone it and play
with it!

## Sources
[Halogen Example by the Halogen team][halogen-example]

[Halogen Guide by the Halogen team][halogen-guide]

[Realworld Halogen Example](https://github.com/thomashoneyman/purescript-halogen-realworld)

[halogen-example]: https://github.com/purescript-halogen/purescript-halogen/tree/master/examples/components
[halogen-guide]:https://github.com/purescript-halogen/purescript-halogen/blob/master/docs/5%20-%20Parent%20and%20child%20components.md
[raise-documentation]: https://pursuit.purescript.org/packages/purescript-halogen/4.0.0/docs/Halogen#v:raise
[notes-example-repo]:https://taezos.org/piq9117/notes-examples/src/branch/master/halogen-parent-child
[halogen-receive]: https://github.com/purescript-halogen/purescript-halogen/blob/78a47710678ac8b59142263149f7c532387b662d/src/Halogen/Component.purs#L137
