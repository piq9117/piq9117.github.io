---
title: Purescript - Serving Static Files with Purescript-Express
---

This is a server that will only serve static files. 
There's no complicated routing, and no complicated request/response handling.

The only route it will have is the "catch-all" route that is needed by a single page
application.

This static file server will be using [purescript-exress][express].

In my [example][example-project] I used [angular][angular] and [angular-cli][angular-cli]
as my client side application. Angular cli will scaffold project. It will also build 
the client side application and output it to the `dist`{.codeLine} directory.

Afterwards, the purescript server will look for that `dist`{.codeLine} directory
and serve it.

This is the entirety of the code.
```haskell
module Main where

import Prelude

import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console (CONSOLE, log)
import Control.Monad.Eff.Ref (newRef, REF, Ref)
import Data.Int (fromString)
import Data.Maybe (fromMaybe)
import Node.Express.App (listenHttp, AppM, use)
import Node.Express.Handler (HandlerM, next)
import Node.Express.Middleware.Static (static)
import Node.Express.Request (getOriginalUrl, setUserData)
import Node.Express.Response (send)
import Node.Express.Types (EXPRESS)
import Node.HTTP (Server)
import Node.Process (lookupEnv, PROCESS)

parseInt :: String -> Int
parseInt str = fromMaybe 0 $ fromString str

logger
  :: ∀ a b.
     b
     -> HandlerM ( express:: EXPRESS
                 , console :: CONSOLE | a) Unit
logger state = do
  url <- getOriginalUrl
  liftEff $ log (">>> " <> url)
  setUserData "logged" url
  next

type AppState = String

initState
  :: ∀ eff.
     Eff (ref :: REF | eff) (Ref String)
initState = newRef ("" :: AppState)

appSetup
  :: ∀ a e.
     a
     ->  AppM ( express :: EXPRESS
              , console :: CONSOLE | e) Unit
appSetup state = do
  use (logger state)
  use (static "dist")

server
  :: ∀ eff.
     Eff ( console :: CONSOLE
         , ref :: REF
         , process :: PROCESS
         ,  express :: EXPRESS
         , console :: CONSOLE | eff) Server
server = do
  state <- initState
  port <- (parseInt <<< fromMaybe "8000") <$> lookupEnv "PORT"
  listenHttp (appSetup state) port \_ ->
    log $ "Listening on " <> show port

main
  :: ∀ eff.
     Eff ( console :: CONSOLE
         , ref :: REF
         , process :: PROCESS
         ,  express :: EXPRESS
         , console :: CONSOLE | eff) Server
main = server
```

[express]:https://github.com/nkly/purescript-express
[angular]: https://angular.io/
[angular-cli]:https://cli.angular.io/
[example-project]:https://github.com/piq9117/ps-playground/tree/master/purs-static
