#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings #-}
-- dependencies: libghc-pandoc-dev

-- usage: 'link-extract.hs [file]'; prints out a newline-delimited list of hyperlinks found in targeted Pandoc Markdown files when parsed.
-- Hyperlinks are not necessarily to the WWW but can be internal or interwiki hyperlinks (eg '/local/file.pdf' or '!Wikipedia').

module Main where

import Text.Pandoc (def, queryWith, readerExtensions, readMarkdown, runPure,
                     pandocExtensions, Inline(Link), Pandoc)
import Data.Text as T (append,  pack, unlines, Text)
import qualified Data.Text.IO as TIO (readFile, putStr)
import System.Environment (getArgs)

-- | Map over the filenames
main :: IO ()
main = do
  fs <- getArgs
  let printfilename = (head fs) == "--print-filenames"
  let fs' = if printfilename then Prelude.drop 1 fs else fs
  mapM_ (printURLs printfilename) fs'

-- | Read 1 file and print out its URLs
printURLs :: Bool -> FilePath -> IO ()
printURLs printfilename file = do
  input <- TIO.readFile file
  let converted = extractLinks input
  if printfilename then TIO.putStr $ T.unlines $ Prelude.map (\url -> (T.pack file) `T.append` ":" `T.append` url) converted else
     TIO.putStr $ T.unlines converted

-- | Read one Text string and return its URLs (as Strings)
extractLinks :: Text -> [T.Text]
extractLinks txt = let parsedEither = runPure $ readMarkdown def{readerExtensions = pandocExtensions } txt
                        -- if we don't explicitly enable footnotes, Pandoc interprets the footnotes as broken links, which throws many spurious warnings to stdout
                   in case parsedEither of
                              Left _ -> []
                              Right links -> extractURLs links

-- | Read 1 Pandoc AST and return its URLs as Strings
extractURLs :: Pandoc -> [T.Text]
extractURLs = queryWith extractURL
 where
   extractURL :: Inline -> [T.Text]
   extractURL (Link _ _ (u,_)) = [u]
   extractURL _ = []
