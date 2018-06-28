-- |
-- Module      : Arivi.Kademlia.MessageHandler
-- Copyright   : (c) Xoken Labs
-- License     : -
--
-- Maintainer  : Ankit Singh {ankitsiam@gmail.com}
-- Stability   : experimental
-- Portability : portable
--
-- This module process the incoming kademlia request and produces the sutiable
-- response as per the Kademlia protocol.
--
module Arivi.P2P.Kademlia.MessageHandler
    ( kademliaMessageHandler
    ) where

import           Arivi.P2P.Kademlia.Kbucket
import           Arivi.P2P.Kademlia.Types
import           Arivi.P2P.P2PEnv
import           Arivi.P2P.Types
import           Arivi.Utils.Exception
import           Codec.Serialise             (deserialise, serialise)
import           Control.Concurrent.STM.TVar
import           Control.Monad.IO.Class
import           Control.Monad.STM
import qualified Data.ByteString.Lazy        as L

-- | Handler function to process incoming kademlia requests, requires a
--   P2P instance to get access to local node information and kbukcet itself.
--   It takes a bytesting as input which is deserialized to kademlia
--   payload, based on the type of request inside payload an appropriate
--   response is returned to the caller.
-- | As per Kademlia protocol there are two valid requests i.e PING and
--   FIND_NODE, in case of PING a simple PONG response is returned to let the
--   request initiator know that remote node is still active. In case of
--   FIND_NODE remote node asks for node closest to a given nodeId thus local
--   kbucket is queried to extract k-closest node known by the local node and a
--   list of k-closest peers wrapped in payload type is returned as a serialised
--   bytestring.
kademliaMessageHandler ::
       (HasP2PEnv m) => L.ByteString -> m (Either AriviException L.ByteString)
kademliaMessageHandler payl = do
    let payl' = deserialise payl :: PayLoad
        msgb = messageBody $ message payl'
        nep = fromEndPoint msgb
        rnid = nodeId msgb
    p2pInstanceTVar <- getAriviTVarP2PEnv
    p2pInstance <- liftIO $ atomically $ readTVar p2pInstanceTVar
    let lnid = selfNodeId p2pInstance
    let rpeer = Peer (rnid, nep)
    case msgb of
        PING {} -> do
            addToKBucket rpeer
            return $
                Right $
                serialise $
                packPong lnid (nodeIp nep) (udpPort nep) (tcpPort nep)
        FIND_NODE {} -> do
            addToKBucket rpeer
            pl <- getKClosestPeersByNodeid rnid 5
            case pl of
                Right pl2 ->
                    return $
                    Right $
                    serialise $
                    packFnR lnid pl2 (nodeIp nep) (udpPort nep) (tcpPort nep)
                Left _ -> return $ Left KademliaInvalidPeer
        _ -> return $ Left KademliaInvalidRequest