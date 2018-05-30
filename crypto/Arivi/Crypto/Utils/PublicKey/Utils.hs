module Arivi.Crypto.Utils.PublicKey.Utils
(
    getSignaturePublicKey,
    getSignaturePublicKeyFromNodeId,
    signMsg,
    verifyMsg,
    getEncryptionSecretKey,
    getEncryptionPublicKey,
    getEncryptionPublicKeyFromNodeId,
    getEncryptionPubKeyFromSigningSecretKey,
    createSharedSecretKey,
    deriveSharedSecretKey,
    generateSigningKeyPair,
    generateNodeId,
    encryptMsg,
    decryptMsg
) where

import           Arivi.Crypto.Cipher.ChaChaPoly1305
import qualified Arivi.Crypto.Utils.PublicKey.Encryption as Encryption
import qualified Arivi.Crypto.Utils.PublicKey.Signature  as Signature
import           Arivi.Crypto.Utils.Random
import           Arivi.Utils.Exception                   (AriviException (AriviCryptoException))
import           Codec.Serialise
import           Control.Exception                       (throw, try)
import           Crypto.ECC                              (SharedSecret)
import           Crypto.Error                            (CryptoError (..),
                                                          CryptoFailable,
                                                          eitherCryptoError)
import           Crypto.Hash                             (Digest, SHA256, hash)
import qualified Crypto.PubKey.Curve25519                as Curve25519
import qualified Crypto.PubKey.Ed25519                   as Ed25519
import qualified Data.Binary                             as Binary (encode)
import           Data.ByteArray                          (convert)
import           Data.ByteString.Char8                   (ByteString, concat,
                                                          length, splitAt,
                                                          unpack)
import qualified Data.ByteString.Lazy                    as L
import           Data.Int                                (Int64)
-- | Wrapper function for getting the signature public key, given private key
getSignaturePublicKey :: Ed25519.SecretKey -> Ed25519.PublicKey
getSignaturePublicKey = Signature.getPublicKey

-- | Function for getting signature pk from nodeId
getSignaturePublicKeyFromNodeId :: ByteString -> Ed25519.PublicKey
getSignaturePublicKeyFromNodeId nodeId = pk where
    pkPair = Data.ByteString.Char8.splitAt 32 nodeId
    pkBs = fst pkPair
    pkOrFail = eitherCryptoError $ Ed25519.publicKey pkBs
    pk = case pkOrFail of
            Left e       -> throw $ AriviCryptoException e -- do something with e
            Right pubkey -> pubkey

-- | Wrapper function for signing a message given just the sk and msg
signMsg :: Ed25519.SecretKey -> ByteString -> Ed25519.Signature
signMsg sk = Ed25519.sign sk pk where
    pk = getSignaturePublicKey sk

verifyMsg :: ByteString -> ByteString -> Ed25519.Signature -> Bool
verifyMsg nodeId = Ed25519.verify pk where
    pk = getSignaturePublicKeyFromNodeId nodeId

-- | Wrapper function for getting EncryptionSecretKey from SignatureSecretKey
getEncryptionSecretKey :: Ed25519.SecretKey -> Curve25519.SecretKey
getEncryptionSecretKey = Encryption.getSecretKey

-- | Wrapper function for getting the encryption public key, given private key
getEncryptionPublicKey :: Curve25519.SecretKey -> Curve25519.PublicKey
getEncryptionPublicKey = Encryption.getPublicKey

-- | Get Encryption Public key from signature secretKey
getEncryptionPubKeyFromSigningSecretKey :: Ed25519.SecretKey -> Curve25519.PublicKey
getEncryptionPubKeyFromSigningSecretKey = getEncryptionPublicKey . getEncryptionSecretKey

-- | Function for getting encryption pk from nodeId
getEncryptionPublicKeyFromNodeId :: ByteString -> Curve25519.PublicKey
getEncryptionPublicKeyFromNodeId nodeId = pk where
    pkPair = Data.ByteString.Char8.splitAt 32 nodeId
    pkBs = snd pkPair
    pkOrFail = eitherCryptoError $ Curve25519.publicKey pkBs
    pk = case pkOrFail of
            Left e       -> throw $ AriviCryptoException e
            Right pubkey -> pubkey

-- | Takes the secret key (signSK) and the nodeId of remote and calls the Encryption.createSharedSecretKey with appropriate arguements
createSharedSecretKey :: Curve25519.PublicKey -> Ed25519.SecretKey -> SharedSecret
createSharedSecretKey remotePubKey signSK = Encryption.createSharedSecretKey encryptSK remotePubKey where
        encryptSK = getEncryptionSecretKey signSK
        -- encryptPK = getEncryptionPublicKeyFromNodeId remoteNodeId

-- | Takes the master secret key (signSK) and the encryption pubkey of remote and calls the Encryption.deriveSharedSecretKey with appropriate arguements
deriveSharedSecretKey :: Curve25519.PublicKey -> Ed25519.SecretKey -> SharedSecret
deriveSharedSecretKey remotePubKey signSK = Encryption.derivedSharedSecretKey remotePubKey encryptSK where
        encryptSK = getEncryptionSecretKey signSK


generateSigningKeyPair :: IO (Ed25519.SecretKey, Ed25519.PublicKey)
generateSigningKeyPair = do
    res <- try Signature.generateKeyPair :: IO (Either CryptoError (Ed25519.SecretKey, Ed25519.PublicKey))
    case res of
        Left ex       -> throw $ AriviCryptoException ex -- Make use of ex
        Right (sk,pk) -> return (sk, pk)


generateNodeId :: Ed25519.SecretKey -> ByteString
generateNodeId signsk = Data.ByteString.Char8.concat [signingPK, encryptionPK] where
    signingPK = Signature.toByteString (getSignaturePublicKey signsk)
    encryptionPK = Encryption.toByteString (getEncryptionPublicKey (getEncryptionSecretKey signsk))

-- | Simple wrapper over chacha encryption
encryptMsg :: Int64 -> SharedSecret -> ByteString -> ByteString -> ByteString
encryptMsg aeadnonce ssk header msg = ciphertext where
        sskBS = Encryption.sharedSecretToByteString ssk
        aeadBS = L.toStrict $ Binary.encode aeadnonce
        errOrEncrypted = eitherCryptoError $ chachaEncrypt aeadBS sskBS header msg
        ciphertext = case errOrEncrypted of
                Left e   -> throw $ AriviCryptoException e
                Right ct -> ct

-- | Simple wrapper over chacha decryption
decryptMsg :: Int64 -> SharedSecret -> ByteString -> ByteString -> ByteString -> ByteString
decryptMsg aeadnonce ssk header tag ct = plaintext where
        sskBS = Encryption.sharedSecretToByteString ssk
        aeadBS = L.toStrict $ Binary.encode aeadnonce
        errOrDecrypted = eitherCryptoError $ chachaDecrypt aeadBS sskBS header tag ct
        plaintext = case errOrDecrypted of
                        Left e   -> throw $ AriviCryptoException e
                        Right pt -> pt
