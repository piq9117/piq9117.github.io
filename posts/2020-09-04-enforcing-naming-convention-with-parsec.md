---
title: Haskell - Enforcing Naming Convention with Parsec
description: Parsing filename with parsec
---
In my project [migratum][migratum] I wanted to enforce a naming convention like this

```bash
V<version number>__<file name>.sql
+       +         +     +     + +
|       |         |     |     | |
|       |         |     |     | v
|       |         |     |     | Enforce sql extension.
|       |         |     |     v
|       |         |     |     Enforce this dot to indicate the end of the file name.
|       |         |     v
|       |         |     File name need to be alpha numeric. No other symbols, except underscore
|       |         v
|       |         Enforce the double underscore
|       v
|       Version number have to be numbers.
v
Enforce the V character to signify "version"
```
Ways I can accomplish these is with

* Regex
* Parser Combinators

I'm not sure how to do this with regex because to be honest, I know very simple 
regex and I don't have a [regex license][regex-license]. I'm decent with parser 
combinators and plus it's the title of this blog post, so that's what I'm 
going to use to accomplish the task I set out for.

Parser combinators really shine when you parse something recursive like 
`json`{.codeLine}. You know how `json`{.codeLine} can contain an array and objects 
and then these objects and arrays can contain arrays and objects, so on and so 
forth? Yeah, parser combinators are really neat for that. So don't judge parser 
combinators solely on this blog post. I chose parser combinators because it's
my go-to method for parsing, and I personally think they're convenient.

Before we touch parsing, let's create a type representation of the file name based 
on the ascii diagram above.
```haskell
data FilenameStructure 
  = FilenameStructure FileVersion Underscore Underscore FileName Dot FileExtension
  deriving ( Eq, Show )

newtype FileVersion = FileVersion Text
  deriving ( Eq, Show )
  
newtype Underscore = Underscore Text
  deriving ( Eq, Show )

newtype FileName = FileName Text
  deriving ( Eq, Show )

newtype Dot = Dot Text
  deriving ( Eq, Show )
  
newtype FileExtension = FileExtension Text
  deriving ( Eq, Show )
```

Now, we can focus on specific segments of the file name instead of thinking of 
parsing the entire file name. I think that makes it a bit easier. At least to me 
it does. I can think of parsing the file version, underscore, filename, etc individually.

Let's start with the imports. Popular libraries that come to mind are parsec, 
megaparsec, and attoparsec. Evaluate which one suits your project, but on this 
blog post we're using parsec.
```haskell
-- parsec
import           Text.ParserCombinators.Parsec (GenParser, ParseError)
import qualified Text.ParserCombinators.Parsec as Parsec

-- text
import qualified Data.Text                     as T
```

Let's start with the file version parser. Our convention says that we need to 
start with the character `V`{.codeLine}, then it should be followed by numbers.
```haskell
fileVersionParser :: GenParser Char st FileVersion
fileVersionParser = do
  vChar <- Parsec.char 'V'
  vNum <- Parsec.digit
  pure $ FileVersion $ T.pack $ ( vChar : vNum : [] )
```
If we try this in `ghci`{.codeLine} it will look like this

```bash
ghci> import Text.ParserCombinators.Parsec
ghci> parse fileVersion "" "V69"
ghci> Right ( FileVersion "V69" )
```
That's what we want, to match `Right`{.codeLine} and return our `FileVersion` with 
the text "V69".

```bash
ghci> parse fileVersion "" "Vwhat"
ghci> Left (line 1, column2):
unexpected "w"
```
That's right, it should fail when there's no version number.

```bash
ghci> parse fileVersion "" "V1what"
ghci> Right ( FileVersion "V1" )
```
It drops the input that isn't a number.

```bash
ghci> parse fileVersion "" "what"
ghci> Left (line 1, column 1):
unexpected "w"
expecting "V"
```
Finally, it will fail if it doesn't find the "V" character.

Woohoo! One parser down, four to go!

Let's do the rest of the parsers, and feel free to try these out in `ghci`{.codeLine}.
```haskell
underscoreParser :: GenParser Char st Underscore
underscoreParser = Underscore . T.pack . pure <$> Parsec.satisfy isUnderscore

isUnderscore :: Char -> Bool
isUnderscore char = any ( char== ) ( "_" :: String )

fileNameParser :: GenParser Char st FileName
fileNameParser = FileName . T.pack 
  <$> Parsec.many ( Parsec.alphaNum <|> Parsec.satisfy isUnderscore )

dotParser :: GenParser Char st Dot
dotParser = Dot . T.pack . pure <$> Parser.char '.'

fileExtensionParser :: GenParser Char st FileExtension
fileExtensionParser = FileExtension. T.pack <$> Parsec.string "sql"
```

Then, to create a parser for the whole file name we combine the rest of our parsers.
```haskell
filenameStructureParser :: GenParser Char st FilenameStructure
filenameStructureParser = FilenameStructure
  <$> fileVersionParser
  <*> underscoreParser
  <*> underscoreParser
  <*> fileNameParser
  <*> dotParser
  <*> fileExtensionParser
```
We can also do this with the `do`{.codeLine} syntax if that's more convenient.
```haskell
filenameStructureParser :: GenParser Char st FilenameStructure
filenameStructureParser = do
  version <- fileVersionParser
  u1 <- underscoreParser
  u2 <- underscoreParser
  fileName <- fileNameParser
  dot <- dotParser
  ext <- fileExtensionParser
  pure $ FilenameStructure version u1 u2 fileName dot ext
```

Finally, our parser "runner"
```haskell
namingConvention :: String -> Either ParseError FilenameStructure
namingConvention = 
  Parsec.parse filenameStructureParser "Error: Not following naming convention"
```

Instead of manually trying them out in `ghci`{.codeLine} we can instead do some 
unit testing. So we don't have to keep messing with the terminal.
```haskell
module NamingConventionSpec where

import Test.Hspec

spec :: Spec
spec = do
  desribe "Filename" $ do
    it "follows naming convention" $ do
      successResult <- pure $ namingConvention "V1__uuid_extension.sql"
      emptyFileName <- pure $ namingConvention ""
      noExtension <- pure $ namingConvention "V1__uuid_extension"
      noVersion <- pure $ namingConvention "uuid_extension.sql"
      upperCaseFileName <- pure $ namingConvention "V1_UUID_extension.sql"
      symbolFileName <- pure $ namingConvention "V1_UUID+extension.sql"

      -- success cases
      shouldBe successResult ( Right "V1__uuid_extension.sql" )
      shouldBe upperCaseFileName ( Right "V1__UUID+extension.sql" )

      -- failure cases
      shouldBe ( isLeft emptyFileName ) True
      shouldBe ( isLeft noFileExt ) True
      shouldBe ( isLeft noVersion ) True
      shouldBe ( isLeft symbolFilename ) True
```

Now that we have our parser we can use it check for duplicates, because our types
have an `Eq`{.codeLine} instance we can do equality checking.
```haskell
fileVersion :: FilenameStructure -> FileVersion
fileVersion ( FilenameStructure v _ _ _ _ _ ) = v

getVersion :: Either ParseError FilenameStructure -> Either ParseError FileVersion
getVersion res = case res of
  Left err -> Left err
  Right fs -> Right $ fileVersion fs

checkDuplicate :: [ String ] -> Either ParseError [ String ]
checkDuplicate filenames = do
  versions <- traverse getVersion ( namingConvention <$> filenames )
  if anySame versions
    -- Express your errors however you want, this is just to show that this is 
    -- the error branch.
    then error "Duplicate migration file"
    else Right filenames
  where
    anySame :: Eq a => [ a ] -> Bool
    anySame = isSeen []

    isSeen :: Eq a => [ a ] -> [ a ] -> Bool
    isSeen seen ( x:xs ) = x `elem` seen || isSeen ( x:seen ) xs
    isSeen _ [] = False
```

When creating your parsers, avoid doing any validation or any "smart" logic. 
Concentrate on parsing the input and nothing more. Once you have your parsers
then you can do whatever you want with the output.

# References

[Haskell from First Principles](https://haskellbook.com/)

[Monadic Parser Combinators](http://www.cs.nott.ac.uk/~pszgmh/monparsing.pdf)

[migratum]:https://taezos.org/taezos/migratum
[regex-license]:https://regexlicensing.org/
