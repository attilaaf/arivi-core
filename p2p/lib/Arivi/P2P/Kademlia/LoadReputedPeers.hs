{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE GADTs                 #-}
{-# LANGUAGE RecordWildCards       #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TemplateHaskell       #-}

module Arivi.P2P.Kademlia.LoadReputedPeers
    ( loadReputedPeers
    , findGivenNode
    ) where

-- import           Arivi.P2P.Exception
import           Arivi.P2P.Kademlia.Kbucket
import           Arivi.P2P.Kademlia.LoadDefaultPeers   (getPeerListFromPayload)
import           Arivi.P2P.Kademlia.RunConcurrently
import           Arivi.P2P.Kademlia.Types
import           Arivi.P2P.MessageHandler.HandlerTypes hiding (NodeId)
import           Arivi.P2P.MessageHandler.NodeEndpoint (issueKademliaRequest)
import           Arivi.P2P.P2PEnv
import           Arivi.P2P.Types
-- import           Arivi.Utils.Logging

-- import           Control.Concurrent.Async.Lifted
import           Control.Exception                     (displayException)

-- import qualified Control.Exception.Lifted              as Exception (SomeException,
import           Control.Lens
import           Control.Monad.Except
import           Control.Monad.Logger
import           Control.Monad.Reader
import qualified Data.List                             as LL

-- import           Arivi.P2P.Exception

-- import           Data.Maybe                            (fromJust)
import qualified Data.Text                             as T

loadReputedPeers ::
       forall env m r t rmsg pmsg.
       ( MonadReader env m
       , HasP2PEnv env m r t rmsg pmsg
       )
    => [Arivi.P2P.Kademlia.Types.NodeId]
    ->  m ()
loadReputedPeers nodeIdList = do
    kb <- getKb
    let limit = hopBound kb
    rpeerList <- mapM (`getKClosestPeersByNodeid'` 10) nodeIdList
    let temp = zip nodeIdList rpeerList
    mapM_ (\x -> mapM_ (findGivenNode limit (fst x)) (snd x)) temp

getKClosestPeersByNodeid' :: (HasKbucket m, MonadIO m) => NodeId -> Int
                        -> m [Peer]
getKClosestPeersByNodeid' nid k = do
    temp <- runExceptT $ getKClosestPeersByNodeid nid k
    case temp of
        Left _ -> return []
        Right pl -> return pl


findGivenNode ::
       forall env m r t rmsg pmsg.
       ( MonadReader env m
       , HasP2PEnv env m r t rmsg pmsg
       )
    => Int
    -> Arivi.P2P.Kademlia.Types.NodeId
    -> Peer
    -> m ()
findGivenNode 0 _ _ = return ()
findGivenNode count tnid rpeer = do
    nc@NetworkConfig {..} <- asks (^. networkConfig)
    let rnid = fst $ getPeer rpeer
        rnep = snd $ getPeer rpeer
        ruport = Arivi.P2P.Kademlia.Types.udpPort rnep
        rip = nodeIp rnep
        rnc = NetworkConfig rnid rip ruport ruport
        fn_msg = packFindMsg nc tnid
    $(logDebug) $
        T.pack
            ("Issuing Find_Given_Node to : " ++ show rip ++ ":" ++ show ruport)
    resp <- runExceptT $ issueKademliaRequest rnc (KademliaRequest fn_msg)
    return ()
    case resp of
        Left e -> $(logDebug) $ T.pack (displayException e)
        Right (KademliaResponse payload)
            -- _ <- runExceptT $ addToKBucket rpeer
         ->
            case getPeerListFromPayload payload of
                Left e ->
                    $(logDebug) $
                    T.append
                        (T.pack
                             ("Couldn't deserialise message while recieving fn_resp from : " ++
                              show rip ++ ":" ++ show ruport))
                        (T.pack (displayException e))
                Right peerl -> do
                    $(logDebug) $
                        T.pack
                            ("Received PeerList from " ++
                             show rip ++
                             ":" ++ show ruport ++ ": " ++ show peerl)
                    let peerDetail =
                            LL.find (\x -> (fst . getPeer) x == tnid) peerl
                    case peerDetail of
                        Just details -> do
                            action <- runExceptT $ addToKBucket details
                            case action of
                                Left e -> do
                                    $(logDebug) $
                                        T.append
                                            (T.pack
                                                 "Couldn't Find the node ")
                                            (T.pack (displayException e))
                                    runKademliaActionConcurrently_
                                        (findGivenNode (count-1) tnid)
                                        peerl
                                Right _ ->
                                    $(logDebug) $
                                    T.pack
                                        ("Added the Peer with nodeId" ++
                                         show tnid ++ "to KBucket")
                        Nothing ->
                            runKademliaActionConcurrently_
                                (findGivenNode (count-1) tnid)
                                peerl
