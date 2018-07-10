{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}

-- |
-- Module      :  Arivi.Network.StreamDatagram
-- Copyright   :
-- License     :
-- Maintainer  :  Mahesh Uligade <maheshuligade@gmail.com>
-- Stability   :
-- Portability :
--
-- This module provides useful functions for managing connections in Arivi
-- communication for Datagrams
module Arivi.Network.DatagramServer
    ( runUdpServer
    ) where

import           Arivi.Env
import           Arivi.Network.Connection        as Conn
import           Arivi.Network.ConnectionHandler (closeConnection,
                                                  establishSecureConnection,
                                                  readUdpSock, sendUdpMessage)
import           Arivi.Network.Types             (ConnectionHandle (..), NodeId,
                                                  TransportType, deserialise,
                                                  Parcel)

import           Arivi.Utils.Logging
import           Control.Concurrent.Async.Lifted (async)
import           Control.Exception.Lifted        (finally)
import           Control.Monad                   (forever)
import           Control.Monad.IO.Class
import           Data.ByteString                 (ByteString)
import           Data.ByteString.Lazy            (fromStrict)
import           Data.Function                   ((&))
import           Network.Socket                  hiding (close, recv, recvFrom,
                                                  send)
import qualified Network.Socket
import           Network.Socket.ByteString       hiding (recv, send)

makeSocket :: ServiceName -> SocketType -> IO Socket
makeSocket portNumber socketType = do
    let hint =
            defaultHints {addrFlags = [AI_PASSIVE], addrSocketType = socketType}
    selfAddr:_ <- getAddrInfo (Just hint) Nothing (Just portNumber)
    sock <-
        Network.Socket.socket
            (addrFamily selfAddr)
            (addrSocketType selfAddr)
            (addrProtocol selfAddr)
    setSocketOption sock ReuseAddr 1
    setSocketOption sock ReusePort 1
    bind sock (addrAddress selfAddr)
    return sock

runUdpServer ::
       (HasSecretKey m, HasLogging m)
    => ServiceName
    -> (NodeId -> TransportType -> ConnectionHandle -> m ())
    -> m ()
runUdpServer portNumber handler =
    $(withLoggingTH) (LogNetworkStatement "UDP Server started...") LevelDebug $ do
        mSocket <- liftIO $ makeSocket portNumber Datagram
        finally
            (forever $ do
                 (msg, peerSockAddr) <- liftIO $ recvFrom mSocket 4096
                 mSocket' <- liftIO $ makeSocket portNumber Datagram
                 liftIO $ connect mSocket' peerSockAddr
                 async (newUdpConnection msg mSocket' handler))
            (liftIO
                 (print ("So long and thanks for all the fish." :: String) >>
                  Network.Socket.close mSocket))

newUdpConnection ::
       (HasSecretKey m, HasLogging m)
    => ByteString
    -> Socket
    -> (NodeId -> TransportType -> ConnectionHandle -> m ())
    -> m ()
newUdpConnection hsInitMsg sock handler =
    $(withLoggingTH) (LogNetworkStatement "newUdpConnection: ") LevelDebug $ do
        liftIO $ print (deserialise (fromStrict hsInitMsg) :: Parcel)
        sk <- getSecretKey
        conn <-
            liftIO $
            deserialise (fromStrict hsInitMsg) &
            establishSecureConnection sk sock id
        handler
            (Conn.remoteNodeId conn)
            (Conn.transportType conn)
            ConnectionHandle
                { send = sendUdpMessage conn
                , recv = readUdpSock conn
                , close = closeConnection (Conn.socket conn)
                }
