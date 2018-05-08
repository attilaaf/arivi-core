{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE DuplicateRecordFields #-}
module Arivi.Network.Types
(   Payload        (..),
    Parcel         (..),
    PeerType (..),
    SessionId      (..),
    MessageId      (..),
    EncryptionType (..),
    TransportType  (..),
    EncodingType   (..),
    ContextID      (..),
    Version        (..),
    Socket,
    SockAddr,
    PortNumber,
    HostAddress,
    NodeId,
    ServiceId (..),
    ConnectionId,
    Opcode(..),
    SequenceNum,
    HandshakeInitMasked(..),
    HandshakeRespMasked(..)
) where

import           Codec.Serialise
import           Codec.Serialise.Class
import           Codec.Serialise.Decoding
import           Codec.Serialise.Encoding
import           Crypto.Error
import           Crypto.PubKey.Curve25519 (PublicKey, publicKey)
import           Crypto.PubKey.Ed25519    (Signature, signature)
import           Data.ByteArray
import qualified Data.ByteString
import           Data.ByteString.Char8    (ByteString)
import qualified Data.ByteString.Lazy     as BSL
import           Data.Int                 (Int16, Int32, Int64, Int8)
import qualified Data.Map.Strict          as Map
import           Data.Monoid
import           Data.UUID                (UUID)
import qualified Data.Word
import           GHC.Generics
import           Network.Socket

type ConnectionId   = ByteString
type SessionId      = Int32
-- need to be changed to Int24
type PayloadLength  = Int16
type FragmentNumber = Int16
type MessageId      = String
type ServiceId      = Int8
type Descriptor     = Data.ByteString.Char8.ByteString
type ContextID      = Int
type ServiceContext = Int32

type SequenceNum = Integer
type InitiatorNonce = Integer -- 1++
type RecipientNonce = Integer -- 2^32++

type NodeId = ByteString
-- The different messages we can get from the network
data Opcode = KEY_EXCHANGE_INIT
            | KEY_EXCHANGE_RESP
            | DATA
            deriving (Show,Eq, Generic)

-- | This message is encrypted and sent in the handshake message
data HandshakeInitMasked = HandshakeInitMessage {
      versionList   :: [Version]
    , connectionId  :: ConnectionId
    , nonce         :: InitiatorNonce
    , nodePublicKey :: NodeId
    , signature     :: Signature
} deriving (Show, Eq, Generic)

data HandshakeRespMasked = HandshakeRespMsg {
    versionList    :: [Version]
    , nonce        :: RecipientNonce
    , connectionId :: ConnectionId
} deriving (Show, Eq, Generic)

-- | This is the structure that goes out on the wire
-- Has been tested for cborg encoding, decoding successfully
data Parcel   =  KeyExParcel {
                    opcode              :: Opcode
                ,   handshakeCiphertext :: ByteString
                ,   ephemeralPublicKey  :: NodeId
                ,   aeadNonce           :: ByteString
               }

               | DataParcel  {
                    opcode         :: Opcode
                ,   messageId      :: MessageId
                ,   fragmentNumber :: FragmentNumber
                ,   connectionId   :: ConnectionId
                ,   payloadLength  :: PayloadLength
                ,   payload        :: Payload
               }

               | ErrorParcel {
                    opcode         :: Opcode
                ,   messageId      :: MessageId
                ,   fragmentNumber :: FragmentNumber
                ,   descriptor     :: Descriptor
                ,   connectionId   :: ConnectionId
               }

               | ByeParcel {
                    opcode         :: Opcode
                ,   fragmentNumber :: FragmentNumber
                ,   connectionId   :: ConnectionId
                ,   messageId      :: MessageId
               }
                deriving (Show,Eq,Generic)

data PeerType = INITIATOR | RECIPIENT
                deriving (Eq)

data Version
    = V0
    | V1
    deriving (Eq, Ord, Show,Generic)


data EncryptionType = NONE
                      | AES256_CTR
                      | CHACHA_POLY
                      deriving (Eq,Show,Generic)

data EncodingType =
                UTF_8
                | ASCII
                | CBOR
                | JSON
                | PROTO_BUFF
                deriving (Eq,Show,Generic)

data TransportType =
                   UDP
                 | TCP
                 deriving (Eq,Show,Generic)

newtype Payload = Payload Data.ByteString.Char8.ByteString
               deriving (Show,Eq,Generic)

instance Serialise Version
instance Serialise Opcode
instance Serialise EncodingType
instance Serialise TransportType
instance Serialise EncryptionType
instance Serialise Payload
instance Serialise Parcel
instance Serialise HandshakeInitMasked
instance Serialise HandshakeRespMasked

-- Serialise intance for PublicKey
instance Serialise PublicKey where
    encode = encodePublicKey
    decode = decodePublicKey

encodePublicKey :: PublicKey -> Encoding
encodePublicKey bytes = do
    let temp = convert bytes :: Data.ByteString.ByteString
    encodeListLen 2 <> encodeWord 0 <> encode temp

decodePublicKey :: Decoder s PublicKey
decodePublicKey = do
    len <- decodeListLen
    tag <- decodeWord
    case (len,tag) of
        (2,0)  -> throwCryptoError . publicKey <$>
                    (decode :: Decoder s Data.ByteString.ByteString)
        _      -> fail "invalid PublicKey encoding"


-- Serilaise instance for Signature
instance Serialise Signature where
    encode = encodeSignature
    decode = decodeSignature

encodeSignature :: Signature -> Encoding
encodeSignature bytes = do
    let temp = convert bytes :: ByteString
    encodeListLen 2 <> encodeWord 0 <> encode temp

decodeSignature :: Decoder s Signature
decodeSignature = do
    len <- decodeListLen
    tag <- decodeWord
    case (len,tag) of
        (2,0) ->  throwCryptoError . Crypto.PubKey.Ed25519.signature <$>
                    (decode :: Decoder s ByteString)
        _      -> fail "invalid Signature encoding"


-- | creates frame(prefixes length) from parcel
-- that has been serialised to cborg
createFrame :: BSL.ByteString -> BSL.ByteString
createFrame parcelSerialised = BSL.concat [lenSer, parcelSerialised]
                                where
                                    len = BSL.length parcelSerialised
                                    lenw8 = fromIntegral len :: Data.Word.Word8
                                    lenSer = BSL.pack [lenw8]
