-- |
-- Module:      Test.Network.Skylark.Core.TChans
-- Copyright:   (c) 2015 Mark Fine
-- License:     BSD3
-- Maintainer:  Mark Fine <mark@swift-nav.com>
--
-- Test send and receive TChans module for Skylark Core.

module Test.Network.Skylark.Core.TChans
  ( tests
  ) where

import Control.Concurrent.STM
import Network.Skylark.Core.Prelude
import Network.Skylark.Core.TChans
import Test.QuickCheck.Monadic
import Test.Tasty
import Test.Tasty.QuickCheck

writesReads :: Int -> Int -> Int -> Int -> IO [[Int]]
writesReads n r x y = atomically $ do
  wc  <- newTWChan $ fromIntegral n
  rcs <- replicateM r (newTRChan wc)
  forM_ (take x [1..]) (writeTWChan wc)
  forM rcs $ (catMaybes <$>) . replicateM y . tryReadTRChan

testWriterReaders :: TestTree
testWriterReaders =
  testGroup "Writer reader tests"
    [ testProperty "Empty write chan" $
        \r n m -> monadicIO $ do
          as <- run $ writesReads n r 0 m
          assert $ as == replicate r []
    , testProperty "0 length write chan" $
        \r n m -> monadicIO $ do
          pre $ n > 0
          as <- run $ writesReads 0 r n m
          assert $ as == replicate r []
    , testProperty "1 length write chan with n writes" $
        \r n m -> monadicIO $ do
          pre $ n > 0
          pre $ m > 0
          as <- run $ writesReads 1 r n m
          assert $ as == replicate r [n]
    , testProperty "n length write chan with m writes" $
        \r n m -> monadicIO $ do
          pre $ n > 0
          as <- run $ writesReads n r m m
          assert $ as ==
            if m <= n then replicate r (take m [1..]) else
              replicate r (take n (drop (m - n) [1..]))
    ]

tests :: TestTree
tests =
  testGroup "TChans tests"
    [ testWriterReaders
    ]

