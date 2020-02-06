<<<<<<< HEAD
-- |
-- Module      :  Arivi.Network.Utils
-- Copyright   :
-- License     :
-- Maintainer  :  Mahesh Uligade <maheshuligade@gmail.com>
-- Stability   :
-- Portability :
=======
>>>>>>> breaking out arivi-core from arivi
--
-- This module provides useful utility functions for the Arivi Network Layer
--
module Arivi.Network.Utils
    ( lazyToStrict
    , strictToLazy
    , getIPAddress
    , getPortNumber
    ) where

<<<<<<< HEAD
import           Data.ByteString      (ByteString)
import qualified Data.ByteString.Lazy as Lazy (ByteString, fromStrict, toStrict)
import           Network.Socket       (HostName, PortNumber, SockAddr (..),
                                       inet_ntoa)
=======
import Data.ByteString (ByteString)
import qualified Data.ByteString.Lazy as Lazy (ByteString, fromStrict, toStrict)

--import Data.Word
import Network.Socket --(HostName, PortNumber, SockAddr(..), getNameInfo)
>>>>>>> breaking out arivi-core from arivi

-- | Converts lazy ByteString to Strict ByteString
-- TODO: Find usage and depreacate this function
lazyToStrict :: Lazy.ByteString -> ByteString
lazyToStrict = Lazy.toStrict

-- | Converts strict ByteString to lazy ByteString
-- TODO: Find usage and depreacate this function
strictToLazy :: ByteString -> Lazy.ByteString
strictToLazy = Lazy.fromStrict

-- | Given `SockAddr` retrieves `HostAddress`
getIPAddress :: SockAddr -> IO HostName
<<<<<<< HEAD
getIPAddress (SockAddrInet _ hostAddress) = inet_ntoa hostAddress
getIPAddress (SockAddrInet6 _ _ (_, _, _, hA6) _) = inet_ntoa hA6
getIPAddress _ =
    error "getIPAddress: SockAddr is not of constructor SockAddrInet "

-- | Given `SockAddr` retrieves `PortNumber`
getPortNumber :: SockAddr -> PortNumber
getPortNumber (SockAddrInet portNumber _) = portNumber
getPortNumber (SockAddrInet6 portNumber _ _ _) = portNumber
getPortNumber _ =
    error "getPortNumber: SockAddr is not of constructor SockAddrInet "
=======
getIPAddress addr = do
    hostport <- getNameInfo [NI_NUMERICHOST, NI_NUMERICSERV] True True addr
    let hostname = fst hostport
    case hostname of
        Just x -> return x
        Nothing -> error "getIPAddress: could not find!"

-- getIPAddress (SockAddrInet _ hostAddress) = inet_ntoa hostAddress
-- getIPAddress (SockAddrInet6 _ _ (_, _, _, hA6) _) = inet_ntoa hA6
-- | Given `SockAddr` retrieves `PortNumber`
getPortNumber :: SockAddr -> IO PortNumber
getPortNumber addr = do
    hostport <- getNameInfo [NI_NUMERICHOST, NI_NUMERICSERV] True True addr
    let port = snd hostport
    case port of
        Just x -> return $ fromInteger ((read x :: Integer))
        Nothing -> error "getPortNumber: could not find!"
>>>>>>> breaking out arivi-core from arivi
