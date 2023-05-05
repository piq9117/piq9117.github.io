---
title: Haskell - Look Ma! No Concrete Implementation!
description: Using tagless final to structure programs
---
This is my post about tagless final encoding. There are many like it, but this 
one is mine. My tagless final encoding post is my best friend. It is my life. I 
must master it as I must master my life.

I can't think of a good intro so I modified the Rifleman's Creed. Anyway,
the tagless final encoding technique has been very helpful in structuring my 
programs without being burdened about dependencies so much, because of this I 
can change dependencies and mostly don't have to re-structure my program. This 
technique also makes it _almost_ effortless to do unit testing.

Just like my other posts let's do a [contrived example][example]. 

This is our user story.

* A command line tool that takes a file path to a text file that contains some text.
* The content of the input file will be processed, and the text content will 
be capitalized.
* The processed text content will then be printed to an output file.

Let's start by creating the representation of our application.
```haskell
{-# LANGUAGE DerivingStrategies         #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module AppM where

newtype AppM a
  = AppM
  { runAppM :: IO a
  } deriving newtype ( Functor, Applicative, Monad, MonadIO )
```
Then, let's define the capabilities of the app based on the made up user story. 
First, the cli capability.
```haskell
module Capability.CLI where

class Monad m => ManageCLI m where
  parseCliCommand :: m Command
  interpretCLI :: Command -> m ()

data Command = Command
  { commandInput  :: Text
  , commandOutput :: Text
  } deriving ( Eq, Show )
```
Next, the capabalities to manipulate files in the file system.
```haskell
module Capability.File where

class Monad m => ManageFile m where
  getFileContent :: Text -> m Text
  printContent :: Text -> Text -> m ()
```
Finally, the capability to manipulate text.
```haskell
module Capability.TextContent where

class Monad m => ManageTextContent m where
  capitalizeContent :: Text -> m Text
```
With all these capabilities, I think we are ready to assemble our program. So, 
let's go back to the `AppM`{.codeLine} module. We have to create instances but 
skip the implementation for now, and use `undefined`{.codeLine}
```haskell
{-# LANGUAGE DerivingStrategies         #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE InstanceSigs               #-}
{-# LANGUAGE RecordWildCards            #-}
module AppM where

import           Capability.CLI
import           Capability.File
import           Capability.TextContent

newtype AppM a
  = AppM
  { runAppM :: IO a
  } deriving newtype ( Functor, Applicative, Monad, MonadIO )

startApp :: IO ()
startApp = runAppM $ interpretCLI =<< parseCliCommand

instance ManageCLI AppM where
  parseCliCommand :: AppM Command
  parseCliCommand = undefined

  interpretCLI :: Command -> AppM ()
  interpretCLI Command{..} = do
    file <- getFileContent commandInput
    content <- capitalizeContent file
    printContent commandOutput content

instance ManageFile AppM where
  getFileContent :: Text -> AppM Text
  getFileContent filePath = undefined

  printContent :: Text -> Text -> AppM ()
  printContent outputPath content = undefined

instance ManageTextContent AppM where
  capitalizeContent :: Text -> AppM Text
  capitalizeContent content = undefined
```
As you can see we were able to assemble our program in `interpretCLI`{.codeLine}
without any concrete implementations. When we provide the concrete implementations,
we won't get so bogged down by thinking about the entire the program because we've 
already done that. We only have to think about the concrete implementations of 
individual capabilities. For example, we only need to think about how to retreive 
a file, print a file, etc.

Proceeding to our concrete implementation we can pick 
`optparse-applicative`{.codeLine} as our cli utility and `relude`{.codeLine} as 
our prelude.
```haskell
module AppM where

...
import           Relude
import qualified Data.Text              as T
import           Options.Applicative

instance ManageCLI AppM where
  parseCliCommand :: AppM Command
  parseCliCommand = liftIO 
    $ execParser ( info ( helper <*> parseCommand ) fullDesc )

  interpretCLI :: Command -> AppM ()
  interpretCLI Command{..} = do
    file <- getFileContent commandInput
    content <- capitalizeContent file
    printContent commandOutput content

instance ManageFile AppM where
  getFileContent :: Text -> AppM Text
  getFileContent filePath = readFileText ( T.unpack filePath )

  printContent :: Text -> Text -> AppM ()
  printContent outputPath content = 
    writeFileText ( T.unpack outputPath ) content

instance ManageTextContent AppM where
  capitalizeContent :: Text -> AppM Text
  capitalizeContent content = pure $ T.toUpper content
```
By using `optparse-applicative`{.codeLine}, here's the implementatin of `parseCommand`{.codeLine}
```haskell
parseCommand :: Parser Command
parseCommand = Command
  <$> strOption ( long "input" <> short 'i' <> metavar "INPUT_FILE" <> help "Input file" )
  <*> strOption ( long "output" <> short 'o' <> metavar "OUTPUT_FILE" <> help "Output file" )
```

One obvious downside to this is the `n^2`{.codeLine} instance problem which Vasiliy
Kevroletin mentions in his [article][intro-to-tagless-final].

That's it! We import our library code to the `Main`{.codeLine} module and execute 
the program.
```haskell
module Main where

import           Relude

import           AppM

main :: IO ()
main = startApp
```

## References

[Purescript Halogen Realworld repository](https://github.com/thomashoneyman/purescript-halogen-realworld)

[Three Layer Cake by Matt Parson](https://www.parsonsmatt.org/2018/03/22/three_layer_haskell_cake.html)

[Introduction to Tagless Final by Vasiliy Kevroletin][intro-to-tagless-final]

[Tagles Final Encoding by Juan Pablo Royo Sales](https://jproyo.github.io/posts/2019-03-17-tagless-final-haskell.html)

[intro-to-tagless-final]:https://serokell.io/blog/tagless-final
[example]:https://taezos.org/piq9117/notes-examples/src/branch/master/tagless-transform
