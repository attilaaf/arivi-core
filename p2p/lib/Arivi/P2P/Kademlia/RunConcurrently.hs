<<<<<<< HEAD
{-# LANGUAGE ExplicitForAll        #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}

--------------------------------------------------------------------------------
-- |
-- Module      : Arivi.P2P.Kademlia.RunConcurrently
-- License     :
-- Maintainer  : Ankit Singh <ankitsiam@gmail.com>
-- Stability   :
-- Portability :
=======
{-# LANGUAGE ExplicitForAll #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}

--------------------------------------------------------------------------------
>>>>>>> breaking out arivi-core from arivi
--
-- This module provides functions to run any async kademlia action with
-- kademlia concurrency factor i.e at any time, alpha number of async actions
-- will be executed defined by the kademlia concurrency factor.
--
--------------------------------------------------------------------------------
module Arivi.P2P.Kademlia.RunConcurrently
    ( runKademliaActionConcurrently_
    , runKademliaActionConcurrently
    ) where

<<<<<<< HEAD
import           Arivi.P2P.Kademlia.Types
import           Control.Concurrent.Async.Lifted
import           Control.Monad.Trans.Control
import qualified Data.List                       as L

-- | Runs async kademlia action which doesn't return anything.
runKademliaActionConcurrently_ ::
       (MonadBaseControl IO m, HasKbucket m) => (a -> m b) -> [a] -> m ()
=======
import Arivi.P2P.Kademlia.Types
import Control.Concurrent.Async.Lifted
import Control.Monad.Trans.Control
import qualified Data.List as L

-- | Runs async kademlia action which doesn't return anything.
runKademliaActionConcurrently_ :: (MonadBaseControl IO m, HasKbucket m) => (a -> m b) -> [a] -> m ()
>>>>>>> breaking out arivi-core from arivi
runKademliaActionConcurrently_ fx lt = do
    kb <- getKb
    if length lt <= kademliaConcurrencyFactor kb
        then mapConcurrently_ fx lt
        else do
            let pl2 = L.splitAt (kademliaConcurrencyFactor kb) lt
            _ <- mapConcurrently_ fx (fst pl2)
            runKademliaActionConcurrently_ fx (snd pl2)

-- | Runs async kademlia action which returns something
<<<<<<< HEAD
runKademliaActionConcurrently ::
       (MonadBaseControl IO m, HasKbucket m) => (a -> m b) -> [a] -> m [b]
=======
runKademliaActionConcurrently :: (MonadBaseControl IO m, HasKbucket m) => (a -> m b) -> [a] -> m [b]
>>>>>>> breaking out arivi-core from arivi
runKademliaActionConcurrently fx lt = do
    kb <- getKb
    if length lt <= kademliaConcurrencyFactor kb
        then mapConcurrently fx lt
        else do
            let pl2 = L.splitAt (kademliaConcurrencyFactor kb) lt
            temp <- mapConcurrently fx (fst pl2)
            temp2 <- runKademliaActionConcurrently fx (snd pl2)
            return $ temp ++ temp2
