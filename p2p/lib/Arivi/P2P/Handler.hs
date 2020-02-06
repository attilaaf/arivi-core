{-# LANGUAGE ScopedTypeVariables #-}

<<<<<<< HEAD
module Arivi.P2P.Handler (
    newIncomingConnectionHandler
  , readIncomingMessage
) where

import           Arivi.Network                         (AriviNetworkException (..),
                                                        ConnectionHandle (..),
                                                        TransportType (..))
import           Arivi.P2P.Exception
import           Arivi.P2P.MessageHandler.HandlerTypes
import           Arivi.P2P.MessageHandler.Utils
import           Arivi.P2P.P2PEnv
import           Arivi.P2P.Types
import           Arivi.Network.Types                   hiding(NodeId)

import qualified Control.Concurrent.Async.Lifted       as LA (async)
import           Control.Concurrent.MVar
import           Control.Concurrent.STM
import           Control.Exception                     (displayException)
import qualified Control.Exception.Lifted              as LE (try)
import           Control.Monad                         (void)
import           Control.Monad.IO.Class                (liftIO)
import           Data.HashMap.Strict                   as HM
import           Data.Maybe                            (fromJust)
import           Control.Lens

-- | Processes a new request from peer
processRequest :: (HasP2PEnv env m r t rmsg pmsg)
    => ConnectionHandle
    -> P2PMessage
    -> NodeId
    -> m (Either AriviP2PException ())
processRequest connHandle p2pMessage peerNodeId = do
    hh <- getHandlers
    responseMsg <- case messageType p2pMessage of
        Rpc -> serialise <$> rpc hh (deserialise $ payload p2pMessage)
        Kademlia -> serialise <$> kademlia hh (deserialise $ payload p2pMessage)
        Option -> serialise <$> option hh
        PubSub p -> pubsub hh undefined p (payload p2pMessage)
    let p2pResponse = generateP2PMessage (uuid p2pMessage) (messageType p2pMessage) responseMsg
    res <- LE.try $ send connHandle (serialise p2pResponse)
    case res of
        Left (e::AriviNetworkException) -> logWithNodeId peerNodeId "network send failed while sending response" >> return (Left (NetworkException e))
        Right _                         -> return (Right ())


-- | Takes an incoming message from the network layer and procesess it in 2 ways. If the mes0sage was an expected reply, it is put into the waiting mvar or else the appropriate handler for the message type is called and the generated response is sent back
processIncomingMessage :: (HasP2PEnv env m r t rmsg pmsg)
    => ConnectionHandle
    -> TVar PeerDetails
    -> P2PPayload
    -> m (Either AriviP2PException ())
=======
module Arivi.P2P.Handler
    ( newIncomingConnectionHandler
    , readIncomingMessage
    ) where

import Arivi.Network (AriviNetworkException(..), ConnectionHandle(..), TransportType(..))
import Arivi.Network.Types hiding (NodeId)
import Arivi.P2P.Exception
import Arivi.P2P.MessageHandler.HandlerTypes
import Arivi.P2P.MessageHandler.Utils
import Arivi.P2P.P2PEnv

--import Arivi.P2P.Types
import Codec.Serialise
import qualified Control.Concurrent.Async.Lifted as LA (async)
import Control.Concurrent.MVar
import Control.Concurrent.STM
import Control.Exception (displayException)
import qualified Control.Exception.Lifted as LE (try)
import Control.Lens
import Control.Monad (void)
import Control.Monad.IO.Class (liftIO)
import Data.HashMap.Strict as HM
import Data.Maybe (fromJust)

-- | Processes a new request from peer
processRequest ::
       (Serialise pmsg, Show t)
    => (HasP2PEnv env m r t rmsg pmsg) =>
           ConnectionHandle -> P2PMessage -> NodeId -> m (Either AriviP2PException ())
processRequest connHandle p2pMessage peerNodeId = do
    hh <- getHandlers
    responseMsg <-
        case messageType p2pMessage of
            Rpc -> serialise <$> rpc hh (deserialise $ payload p2pMessage)
            Kademlia -> serialise <$> kademlia hh (deserialise $ payload p2pMessage)
            Option -> serialise <$> option hh
            PubSub p -> pubsub hh peerNodeId p (payload p2pMessage)
    let p2pResponse = generateP2PMessage (uuid p2pMessage) (messageType p2pMessage) responseMsg
    res <- LE.try $ send connHandle (serialise p2pResponse)
    case res of
        Left (e :: AriviNetworkException) ->
            logWithNodeId peerNodeId "network send failed while sending response" >> return (Left (NetworkException e))
        Right _ -> return (Right ())

-- | Takes an incoming message from the network layer and procesess it in 2 ways. If the mes0sage was an expected reply, it is put into the waiting mvar or else the appropriate handler for the message type is called and the generated response is sent back
processIncomingMessage ::
       (Serialise pmsg, Show t)
    => (HasP2PEnv env m r t rmsg pmsg) =>
           ConnectionHandle -> TVar PeerDetails -> P2PPayload -> m (Either AriviP2PException ())
>>>>>>> breaking out arivi-core from arivi
processIncomingMessage connHandle peerDetailsTVar msg = do
    peerNodeId <- liftIO $ getNodeId peerDetailsTVar
    let p2pMessageOrFail = deserialiseOrFail msg
    case p2pMessageOrFail of
<<<<<<< HEAD
        Left _ -> logWithNodeId peerNodeId "Peer sent malformed msg" >> return  (Left DeserialiseFailureP2P)
=======
        Left _ -> logWithNodeId peerNodeId "Peer sent malformed msg" >> return (Left DeserialiseFailureP2P)
>>>>>>> breaking out arivi-core from arivi
        Right p2pMessage -> do
            peerDetails <- liftIO $ atomically $ readTVar peerDetailsTVar
            case uuid p2pMessage of
                Just uid ->
<<<<<<< HEAD
                    case peerDetails ^. uuidMap.at uid of
=======
                    case peerDetails ^. uuidMap . at uid of
>>>>>>> breaking out arivi-core from arivi
                        Just mvar -> liftIO $ putMVar mvar p2pMessage >> return (Right ())
                        Nothing -> processRequest connHandle p2pMessage peerNodeId
                Nothing -> error "Don't know what to do here"

-- | Recv from connection handle and process incoming message
<<<<<<< HEAD
readIncomingMessage :: (HasP2PEnv env m r t rmsg pmsg)
    => ConnectionHandle
    -> TVar PeerDetails
    -> m ()
=======
readIncomingMessage ::
       (Serialise pmsg, Show t)
    => (HasP2PEnv env m r t rmsg pmsg) =>
           ConnectionHandle -> TVar PeerDetails -> m ()
>>>>>>> breaking out arivi-core from arivi
readIncomingMessage connHandle peerDetailsTVar = do
    peerNodeId <- liftIO $ getNodeId peerDetailsTVar
    msgOrFail <- LE.try $ recv connHandle
    case msgOrFail of
<<<<<<< HEAD
        Left (e::AriviNetworkException) -> void $ logWithNodeId peerNodeId ("network recv failed from readIncomingMessage" ++ displayException e)
=======
        Left (e :: AriviNetworkException) ->
            void $ logWithNodeId peerNodeId ("network recv failed from readIncomingMessage" ++ displayException e)
>>>>>>> breaking out arivi-core from arivi
        Right msg -> do
            _ <- LA.async (processIncomingMessage connHandle peerDetailsTVar msg)
            readIncomingMessage connHandle peerDetailsTVar

<<<<<<< HEAD
newIncomingConnectionHandler :: (HasP2PEnv env m r t rmsg pmsg)
    => NetworkConfig
    -> TransportType
    -> ConnectionHandle
    -> m ()
newIncomingConnectionHandler nc transportType connHandle = do
    nodeIdMapTVar <- getNodeIdPeerMapTVarP2PEnv
    -- msgTypeMap <- getMessageTypeMapP2PEnv
    nodeIdPeerMap <- liftIO $ atomically $ readTVar nodeIdMapTVar
    -- lock <- liftIO $ atomically $ newTMVar True
=======
newIncomingConnectionHandler ::
       (Serialise pmsg, Show t)
    => (HasP2PEnv env m r t rmsg pmsg) =>
           NetworkConfig -> TransportType -> ConnectionHandle -> m ()
newIncomingConnectionHandler nc transportType connHandle = do
    nodeIdMapTVar <- getNodeIdPeerMapTVarP2PEnv
  -- msgTypeMap <- getMessageTypeMapP2PEnv
    nodeIdPeerMap <- liftIO $ atomically $ readTVar nodeIdMapTVar
  -- lock <- liftIO $ atomically $ newTMVar True
>>>>>>> breaking out arivi-core from arivi
    case HM.lookup (nc ^. nodeId) nodeIdPeerMap of
        Nothing -> do
            peerDetailsTVar <- liftIO $ atomically $ mkPeer nc transportType (Connected connHandle)
            liftIO $ atomically $ addNewPeer (nc ^. nodeId) peerDetailsTVar nodeIdMapTVar
        Just peerDetailsTVar -> liftIO $ atomically $ updatePeer transportType (Connected connHandle) peerDetailsTVar
    nodeIdPeerMap' <- liftIO $ atomically $ readTVar nodeIdMapTVar
    let peerDetailsTVar = fromJust (HM.lookup (nc ^. nodeId) nodeIdPeerMap')
    readIncomingMessage connHandle peerDetailsTVar
