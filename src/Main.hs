--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleContexts #-}

import Hakyll
import Control.Applicative ((<$>),(<|>))
import Control.Arrow ((>>>),(>>^))
import Control.Monad.Trans
import Codec.Binary.UTF8.String (encodeString)
import Data.List (isPrefixOf,isSuffixOf,isInfixOf)
import Data.Monoid (mappend,(<>))
import Data.Text (pack,unpack,replace,empty)
import Data.Char (toLower)
import System.Random
import System.FilePath (takeFileName,takeBaseName,splitFileName,takeDirectory, (</>))

-- http://qnikst.github.io/posts/2013-02-04-hakyll-latex.html
--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do

    -- Build tags
    tags <- buildTags "posts/*" (fromCapture "tags/*.html")

    tagsRules tags $ \tag pattern -> do
        let title = "Posts tagged \"" ++ tag ++ "\""
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll pattern
            let ctx = constField "title" title
                        `mappend` listField "posts" postCtx (return posts)
                        `mappend` defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/tag.html" ctx
                >>= loadAndApplyTemplate "templates/default.html" ctx
                >>= relativizeUrls

    -- copy site icon to `favicon.ico`
    match "images/favicon.ico" $ do
            route   (constRoute "favicon.ico")
            compile copyFileCompiler


    -- copy humans.txt and robots.txt to web root
    match (fromList ["humans.txt", "robots.txt"]) $ do
        route   idRoute
        compile copyFileCompiler


    -- copy resources
    match ("images/**"
            .||. "js/**") $ do
        route   idRoute
        compile copyFileCompiler


    match "css/*.css" $ do
        route   idRoute
        compile compressCssCompiler

    match (fromList ["story.markdown"
                    ,"download.markdown"
                    ]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html"  (postCtxWithTags tags)
            >>= (externalizeUrls $ feedRoot feedConfiguration)
            >>= saveSnapshot "content"
            >>= (unExternalizeUrls $ feedRoot feedConfiguration)
            >>= relativizeUrls


    match "posts/*" $ do
        route $ setExtension "html"
--        route $ niceRoute
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    (postCtxWithTags tags)
            >>= (externalizeUrls $ feedRoot feedConfiguration)
            >>= saveSnapshot "content"
            >>= (unExternalizeUrls $ feedRoot feedConfiguration)
            >>= loadAndApplyTemplate "templates/default.html" (postCtxWithTags tags)
            >>= relativizeUrls
--            >>= cleanIndexUrls

    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Home"                `mappend`
                --    (tagCloudField "tagcloud" 100  240 tags) `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls


    -- Render RSS feed
    create ["rss.xml"] $ do
        route idRoute
        compile $ do
            loadAllSnapshots "posts/*" "content"
                >>= recentFirst
                >>= renderRss feedConfiguration feedCtx

    match "templates/*" $ compile templateCompiler


-- Routes

-- replace a foo/bar.md by foo/bar/index.html
-- this way the url looks like: foo/bar in most browsers
niceRoute :: Routes
niceRoute = customRoute createIndexRoute
  where
    createIndexRoute ident = takeDirectory p </> takeBaseName p </> "index.html" where p=toFilePath ident


cleanIndexUrls :: Item String -> Compiler (Item String)
cleanIndexUrls = return . fmap (withUrls clean)
      where
        idx = "index.html"
        clean url
            | idx `isSuffixOf` url = take (length url - length idx) url
            | otherwise            = url

-- Contexts

postCtx :: Context String
postCtx =
    dateField "date" "<span class=\"post-date\">%B %e, %Y</span>" `mappend`
    (defaultContext <> metaKeywordCtx)

postCtxWithTags :: Tags -> Context String
postCtxWithTags tags = tagsField "tags" tags `mappend` postCtx

feedCtx :: Context String
feedCtx =
    bodyField "description" `mappend`
    postCtx

-- metaKeywordContext will return a Context containing a String
metaKeywordCtx :: Context String
-- can be reached using $metaKeywords$ in the templates
-- Use the current item (markdown file)
metaKeywordCtx = field "metaKeywords" $ \item -> do
  -- tags contains the content of the "tags" metadata
  -- inside the item (understand the source)
  tags <- getMetadataField (itemIdentifier item) "tags"
  -- if tags is empty return an empty string
  -- in the other case return
  --   <meta name="keywords" content="$tags$">
  return $ maybe "" showMetaTags tags
    where
      showMetaTags t = "<meta name=\"keywords\" content=\"" ++ t ++ "\">\n"

----------------------------------------------

config :: Configuration
config = defaultConfiguration {
    deployCommand = "rsync -avz --delete --checksum _site/* hallaclean@kennycason.com:/home/hallaclean/public_html/ninjaturdle/"
}

-- Feed configuration

feedConfiguration :: FeedConfiguration
feedConfiguration = FeedConfiguration
    { feedTitle = "Ninja Turlde - RSS feed"
    , feedDescription = "Ninja Turdle's Development History"
    , feedAuthorName = "Kenny Cason"
    , feedAuthorEmail = "kenneth.cason@gmail.com"
    , feedRoot = "http://www.ninjaturdle.com"
    }


-- Auxiliary compilers

externalizeUrls :: String -> Item String -> Compiler (Item String)
externalizeUrls root item = return $ fmap (externalizeUrlsWith root) item

externalizeUrlsWith :: String -- ^ Path to the site root
                    -> String -- ^ HTML to externalize
                    -> String -- ^ Resulting HTML
externalizeUrlsWith root = withUrls ext
  where
    ext x = if isExternal x then x else root ++ x

unExternalizeUrls :: String -> Item String -> Compiler (Item String)
unExternalizeUrls root item = return $ fmap (unExternalizeUrlsWith root) item

unExternalizeUrlsWith :: String -- ^ Path to the site root
                      -> String -- ^ HTML to unExternalize
                      -> String -- ^ Resulting HTML
unExternalizeUrlsWith root = withUrls unExt
  where
    unExt x = if root `isPrefixOf` x then unpack $ replace (pack root) empty (pack x) else x
