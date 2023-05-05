---
title: Haskell - Extracting IO
---
There are more articles out there discussing this topic but this is my take on it. This topic can be long and complicated but I'll try and extract a section of it that we can focus on.

Let's do a [contrived example][contrived-example]. Let's say we have a function that reads a file, processes it by capitalizing all the characters, then writes the results to another file. This is the first iteration of this function.
```haskell
{-# LANGUAGE OverloadedStrings #-}
module Lib where

import           Relude

-- text
import qualified Data.Text as T

-- 1. reads the file
-- 2. capitalizes all the characters
-- 3. writes result to the output path
processFile :: FilePath -> FilePath -> IO ()
processFile fp output = do
  inputFile <- readFileText fp
  writeFileText output ( T.toUpper inputFile )
```
This adequately performs the task we want. The problem comes when we want to test the text processing without interacting with the file system. Sure, we can unit test the text processing it self but what if we want to see how the text processing behaves in the `processFile`{.codeLine} function? 

I learned mtl, tagless final encoding, and started reading about free monads, fused-effects, etc to be able to extract `IO`{.codeLine} out; among other things. Then, I totally ignored an easier technique. Which is to make the "side-effecty" functions into a parameter, and give it a basic type constraint of `Monad`{.codeLine} instead of `IO`{.codeLine}, like this
```haskell
processFileBase
  :: Monad m
  => ( FilePath -> m Text )
  -> ( FilePath -> Text -> m () )
  -> FilePath
  -> FilePath
  -> m ()
processFileBase readFileF writeFileF inputPath outputPath = do
  inputFile <- readFileF inputPath
  writeFileF outputPath ( T.toUpper inputFile )
```
We can use some type alias to make it less confusing.
```haskell
type ReadFileF m = FilePath -> m Text
type WriteFileF m = FilePath -> Text -> m ()

processFileBase
  :: Monad m
  => ReadFileF m
  -> WriteFileF m
  -> FilePath
  -> FilePath
  -> m ()
```
We've extracted out the `IO`{.codeLine}. Yaaay! This function is now more flexible. We can pass in functions as long as they have a `Monad`{.codeLine} instance. If we go back to our `IO`{.codeLine} implementation we can provide it with functions from `relude`{.codeLine}. 
```haskell
processFileWithIO :: MonadIO m => FilePath -> FilePath -> m ()
processFileWithIO inputPath outputPath = processFileBase
  readFileText
  writeFileText
  inputPath
  outputPath
```
Another advantage of this technique is we can use another library and don't have to restructure our program. Let's say we ended up dropping `relude`{.codeLine} and using 
`prelude`{.codeLine} instead. We can massage the `writeFile`{.codeLine} and `readFile`{.codeLine} functions from `prelude`{.codeLine} so it can fit our program. Like so

```haskell

readFilePrelude :: MonadIO m => FilePath -> m Text
readFilePrelude = liftIO . fmap T.pack <$> Prelude.readFile

writeFilePrelude :: MonadIO m => FilePath -> Text -> m ()
writeFilePrelude fp content = liftIO 
  $ Prelude.writeFile fp ( T.unpack content )

processFileWithIO :: MonadIO m => FilePath -> FilePath -> m ()
processFileWithIO inputPath outputPath = processFileBase
  readFilePrelude
  writeFilePrelude
  inputPath
  outputPath
```

In testing, we can provide it different functions. 
```haskell
{-# LANGUAGE OverloadedStrings #-}
module ProcessFileSpec where

import qualified Data.HashMap.Strict as HS
import           Lib
import           Relude
import           Test.Hspec

textFileToProcess :: Text
textFileToProcess =
  "Letting the cat out of the bag is a whole lot easier than putting it back in."

spec :: Spec
spec = do
  describe "processFile" $ do
    it "will process the file and capitalize every character" $ do
      ioRef <- newIORef HS.empty
      let
        outPath = "sample-output.txt"

        testReadFile :: Monad m => FilePath -> m Text
        testReadFile _ = pure textFileToProcess

        testWriteFile :: MonadIO m => FilePath -> Text ->  m ()
        testWriteFile outputPath content = liftIO $
          modifyIORef ioRef (\ref -> HS.insert outputPath content ref )

      processFileBase testReadFile testWriteFile "input-path.txt" outPath

      result <- readIORef ioRef

      shouldBe result
        $ HS.singleton outPath
            "LETTING THE CAT OUT OF THE BAG IS A WHOLE LOT EASIER THAN PUTTING IT BACK IN."
```
Here we're using `IORef`{.codeLine} but you can use `Map`{.codeLine}, `List`{.codeLine}, `StateT`{.codeLine}, `WriterT`{.codeLine}. It's totally up to you. Whatever suits your use-case.

This technique can take you a long way! It is also a good complement to techniques like `mtl`{.codeLine} and tagless final encoding

## References
[Invert Your Mocks! - Matt Parsons](https://www.parsonsmatt.org/2017/07/27/inverted_mocking.html)

[contrived-example]:https://taezos.org/piq9117/notes-examples/src/branch/master/abstracting-io
