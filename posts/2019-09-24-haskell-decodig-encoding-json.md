---
title: Haskell - Encoding and Decoding JSON with Aeson
---

There are a lot of blog posts and tutorial about encoding/decoding JSON with
[aeson][aeson-library]. Even the library is pretty good at teaching how to do 
this. The tutorial I always go back to is [Artyom Kazak's][aeson-tutorial] 
tutorial. They talk about lots of different techniques on how to decode and
encode json on different cases. 

Let's start off with the basics by deriving instances of `FromJSON`{.codeLine}
and `ToJSON`{.codeLine} manually.

```Haskell
data Book = Book
  { bookTitle     :: Text
  , bookISBN      :: Text
  , bookPublisher :: Text
  , bookLanguage  :: Text
  } deriving Show
  
instance FromJSON Book where
  parseJSON = withObject "Book" $ \b ->
    Book <$> b .: "title"
         <*> b .: "ISBN"
         <*> b .: "publisher"
         <*> b .: "language"

instance ToJSON Book where
  toJSON Book {..} = object
    [ "title"     .= bookTitle
    , "ISBN"      .= bookISBN
    , "publisher" .= bookPublisher
    , "language"  .= bookLanguage
    ]
```

With `FromJSON`{.codeLine} and `ToJSON`{.codeLine} instances we can now consume json of 
this shape:
```json
{ "title": ".."
, "ISBN": ".."
, "publisher": ".."
, "language": ".."
}
```

As you can see when the type has more fields that also means that we have to
type out all those fields. Your fingers are going to fall off by the time you
are done with your app.

One solution to minimize the boilerplate is by using `Generics`{.codeLine}

```Haskell
{-# LANGUAGE DeriveGeneric #-}

import GHC.Generics

data Book = Book
  { bookTitle     :: Text
  , bookISBN      :: Text
  , bookPublisher :: Text
  , bookLanguage  :: Text
  } deriving (Generic, Show)
  
instance FromJSON Book
instance ToJSON Book
```
If we use `{-# LANGUAGE DeriveAnyClass #-}`{.codeLine} pragma we can do this.
```Haskell
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}

data Book = Book
  { bookTitle     :: Text
  , bookISBN      :: Text
  , bookPublisher :: Text
  , bookLanguage  :: Text
  } deriving (Generic, Show, FromJSON, ToJSON)
```

## DeriveAnyClass and GenerlizedNewTypeDeriving

If we have both of these language extensions enabled, ghc will complain about
derivation being ambigious. To get around this use `
{-# LANGUAGE DerivingStrategies #-}`{.codeLine} language extension.
```Haskell
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DeriveGeneric #-}

data Book = Book
  { bookTitle     :: Text
  , bookISBN      :: Text
  , bookPublisher :: Text
  , bookLanguage  :: Text
  } 
  deriving (Generic, Show)
  deriving anyclass (FromJSON, ToJSON)
```

If we don't need to do anything with the field name this will suffice. However,
our field name is `title`{.codeLine} not `bookTitle`{.codeLine} so we have to do a
little modification to the field names by doing the following
```Haskell
import Text.Casing (camel)
import Data.Aeson

instance FromJSON Book where
  parseJSON = genericParseJSON 
    defaultOptions { fieldLabelModifier = camel . drop 4 }

instance ToJSON Book where
  toJSON = genericToJSON 
    defaultOptions { fieldLabelModifier = camel . drop 4 }
```
Here's a reference to [defaultOptions][aeson-default-options]. In the code above
we're doing a record update. That means it's gonna `drop`{.codeLine} 4
characters from the beginning and then camel case it.

## Nullable Fields
When it comes to nullable fields, `Generics`{.codeLine} will automatically use
this operator [(.:?)][nullable-operator] on fields that are `Maybe`{.codeLine}s, which will use `Nothing`{.codeLine} if 
the field is `null`{.codeLine} or missing.

## Optional Fields
For optional fields we have to go back to manually deriving `ToJSON`{.codeLine}
and `FromJSON`{.codeLine} manually.
```Haskell
data Book = Book
  { bookTitle     :: Text
  , bookISBN      :: Text
  , bookPublisher :: Text
  , bookLanguage  :: Text
  , bookPrice     :: Maybe (Fixed E2)
  } deriving Show
  
instance FromJSON Book where
  parseJSON = withObject "Book" $ \b ->
    Book <$> b .: "title"
         <*> b .: "ISBN"
         <*> b .: "publisher"
         <*> b .: "language"
         <*> optional (b .: "price")
```
### Sum Types

```Haskell
{-# LANGUAGE RecordWildCards #-}

data BookFormat 
 = Ebook { price :: Fixed E2 }
 | PhysicalBook { price :: Fixed E2, coverType :: Text }
  deriving Show

instance FromJSON BookFormat where
  parseJSON = withObject "BookFormat" $ \b -> asum
    [ Ebook <$> b .: "price"
    , PhysicalBook <$> b .: "price"
                   <*> b .: "coverType"
    ]

instance ToJSON BookFormat where
  toJSON = \case 
    Ebook {..} -> object [ "price" .= price ]
    PhysicalBook {..} -> object [ "price" .= price, "coverType" .= coverType]

```
or if we we can decide based on the `format`{.codeLine}
```Haskell
instance FromJSON BookFormat where
  parseJSON = withObject "BookFormat" $ \b -> do
    format <- b .: "format"
    case (format :: Text) of
      "ebook" -> Ebook <$> b .: "price"
      "physicalBook" ->
        PhysicalBook <$> b .: "price"
                     <*> b .: "coverType"
```
The same with product types we can also use `Generics`{.codeLine} and some
language extensions to derive `FromJSON`{.codeLine} and `ToJSON`{.codeLine} instance
```Haskell
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
import GHC.Generics

data BookFormat
 = Ebook { price :: Fixed E2 }
 | PhysicalBook { price :: Fixed E2, coverType :: Text }
  deriving (Show, Generic, ToJSON, FromJSON)
```
These are the usual day to day techniques of encoding/decoding json data that I
use.



[aeson-default-options]: https://www.stackage.org/haddock/lts-14.2/aeson-1.4.4.0/Data-Aeson.html#v:defaultOptions
[nullable-operator]: https://www.stackage.org/haddock/lts-14.2/aeson-1.4.4.0/Data-Aeson.html#v:.:-63-
[aeson-tutorial]: https://artyom.me/aeson
[aeson-library]: https://hackage.haskell.org/package/aeson
