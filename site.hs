{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

import Data.Monoid (mappend)
import Hakyll
  ( Configuration (..),
    Context,
    applyAsTemplate,
    compile,
    compressCssCompiler,
    copyFileCompiler,
    dateField,
    defaultConfiguration,
    defaultContext,
    fromList,
    getResourceBody,
    hakyllWith,
    idRoute,
    listField,
    loadAll,
    loadAndApplyTemplate,
    match,
    pandocCompiler,
    recentFirst,
    relativizeUrls,
    route,
    setExtension,
    templateBodyCompiler,
  )

main :: IO ()
main = hakyllWith config $ do
  match "images/*" $ do
    route idRoute
    compile copyFileCompiler

  match "css/*" $ do
    route idRoute
    compile compressCssCompiler

  match (fromList ["about.rst", "contact.markdown"]) $ do
    route $ setExtension "html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

  match "posts/*" $ do
    route $ setExtension "html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/post.html" postCtx
        >>= loadAndApplyTemplate "templates/default.html" postCtx
        >>= relativizeUrls

  match "index.html" $ do
    route idRoute

    compile $ do
      posts <- loadAll "posts/*"
      posts <- recentFirst posts
      let indexCtx =
            listField "posts" postCtx (pure posts)
              `mappend` defaultContext

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls

  match "templates/*" $ compile templateBodyCompiler

config :: Configuration
config =
  defaultConfiguration
    { destinationDirectory = "docs"
    }

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y"
    `mappend` defaultContext
