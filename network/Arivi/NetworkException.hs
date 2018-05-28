module Arivi.NetworkException (
    AriviNetworkException(..)
) where

import           Arivi.Crypto.Types (CryptoException (..))
import           Codec.Serialise    (DeserialiseFailure)
import           Control.Exception
data AriviNetworkException =  AriviDeserialiseFailure DeserialiseFailure
                            | AriviCryptoException CryptoException
                            | AriviSocketException deriving(Show)

instance Exception AriviNetworkException