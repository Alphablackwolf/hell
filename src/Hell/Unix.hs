{-# LANGUAGE FlexibleInstances #-}
-- | A set of utilities that are named similarly and behave similarly
-- to the UNIX way of doing shells.

module Hell.Unix
  (R(..)
  ,A(..)
  ,Ls(..)
  ,Cd(..)
  ,Rm(..)
  ,pwd
  ,rmdir)
  where

import Control.Monad
import Data.List
import System.Directory
import System.FilePath

-- | R parameter.
data R = R

-- | A parameter.
data A = A

-- | List directory contents.
class Ls a where
  ls :: a

-- | Print recursive directory contents.
instance Ls (R -> IO String) where
  ls R = getCurrentDirectory >>= ls R

-- | Print everything in the directory.
instance Ls (A -> IO String) where
  ls A = getCurrentDirectory >>= ls A

-- | Print the given directory recursively.
instance Ls (R -> FilePath -> IO String) where
  ls R x = recursiveList False x

-- | Print the given directory recursively.
instance Ls (A -> R -> FilePath -> IO String) where
  ls _ _ x = recursiveList True x

-- | Print the given directory recursively.
instance Ls (R -> A -> FilePath -> IO String) where
  ls _ _ x = recursiveList True x

-- | Get directory contents.
instance Ls (A -> FilePath -> IO [FilePath]) where
  ls _ x = getEntries True x

-- | Get directory contents.
instance Ls (FilePath -> IO [FilePath]) where
  ls x = getEntries False x

-- | Get current directory contents.
instance Ls (IO [FilePath]) where
  ls = getCurrentDirectory >>= ls

-- | List the given directory.
instance Ls (FilePath -> IO String) where
  ls x = ls x >>= mapM_ putStrLn >> return ""

-- | List the given directory.
instance Ls (A -> FilePath -> IO String) where
  ls a x = ls a x >>= mapM_ putStrLn >> return ""

-- | List the current directory.
instance Ls (IO String) where
  ls =
    do pwd <- getCurrentDirectory
       ls pwd

-- | Set current directory.
class Cd a where
  cd :: a

-- | Switch to given directory.
instance Cd (FilePath -> IO String) where
  cd x = setCurrentDirectory x >> return ""

-- | Switch to home directory.
instance Cd (IO String) where
  cd =
    getHomeDirectory >>= setCurrentDirectory >> return ""

-- | Remove given file.
class Rm a where
  rm :: a

instance Rm (FilePath -> IO String) where
  rm x = removeFile x >> return ""

instance Rm (R -> FilePath -> IO String) where
  rm R x = removeDirectoryRecursive x >> return ""

-- | Print the present working directory.
pwd :: IO ()
pwd = getCurrentDirectory >>= putStrLn

-- | Remove given file.
rmdir :: FilePath -> IO ()
rmdir = removeDirectory

-- | Get directory listing.
getEntries :: Bool -> FilePath -> IO [String]
getEntries everything x =
  fmap (sort .
        filter (if everything
                   then \x -> not (all (=='.') x)
                   else \x -> not (isPrefixOf "." x) || all (=='.') x))
       (getDirectoryContents x)

-- | Recursive list.
recursiveList :: Bool -> FilePath -> IO String
recursiveList everything x =
  do xs <- ls x
     forM_ (map (x </>)
                (if everything
                    then xs
                    else filter (not . isPrefixOf ".") xs))
           (\x ->
              do putStrLn x
                 isDir <- doesDirectoryExist x
                 when isDir
                      (do "" <- ls R x
                          return ()))
     return ""
