{-# OPTIONS_GHC -fno-warn-type-defaults #-}
{-# LANGUAGE FlexibleInstances    #-}
{-# LANGUAGE OverloadedStrings    #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE FlexibleContexts     #-}

module Main
    ( module Main
    ) where

import           Arivi.Crypto.Utils.PublicKey.Signature as ACUPS
import           Arivi.Crypto.Utils.PublicKey.Utils
import           Arivi.Env
import           Arivi.Network
import           Arivi.P2P.P2PEnv
import           Arivi.P2P.ServiceRegistry

import           Arivi.P2P.Kademlia.LoadDefaultPeers    (loadDefaultPeers)
import           Arivi.P2P.Kademlia.VerifyPeer          (initBootStrap)
import           Arivi.P2P.MessageHandler.Handler       (newIncomingConnection)
import           Control.Concurrent.Async.Lifted        (async, wait)
import           Control.Monad                          (mapM_)
import           Control.Monad.IO.Class                 (liftIO)
import           Control.Monad.Logger
import           Control.Monad.Reader
import qualified CreateConfig                           as Config
import           Data.ByteString.Lazy                   as BSL (ByteString)
import           Data.ByteString.Lazy.Char8             as BSLC (pack)
import           Data.Monoid                            ((<>))
import           Data.String.Conv
import           Data.Text
import           System.Directory                       (doesPathExist)
import           System.Environment                     (getArgs)

type AppM = ReaderT P2PEnv (LoggingT IO)

instance HasNetworkEnv AppM where
    getEnv = asks ariviNetworkEnv

instance HasSecretKey AppM

instance HasKbucket AppM where
    getKb = asks kbucket

instance HasStatsdClient AppM where
    getStatsdClient = asks statsdClient

instance HasP2PEnv AppM where
    getP2PEnv = ask
    getAriviTVarP2PEnv = tvarAriviP2PInstance <$> getP2PEnv
    getNodeIdPeerMapTVarP2PEnv = tvarNodeIdPeerMap <$> getP2PEnv
    getMessageTypeMapP2PEnv = tvarMessageTypeMap <$> getP2PEnv
    getWatcherTableP2PEnv = tvarWatchersTable <$> getP2PEnv
    getNotifiersTableP2PEnv = tvarNotifiersTable <$> getP2PEnv
    getTopicHandlerMapP2PEnv = tvarTopicHandlerMap <$> getP2PEnv
    getMessageHashMapP2PEnv = tvarMessageHashMap <$> getP2PEnv
    getArchivedResourceToPeerMapP2PEnv =
        tvarArchivedResourceToPeerMap <$> getP2PEnv
    getTransientResourceToPeerMap = tvarDynamicResourceToPeerMap <$> getP2PEnv
    getSelfNodeId = selfNId <$> getP2PEnv

runAppM :: P2PEnv -> AppM a -> LoggingT IO a
runAppM = flip runReaderT

{--
writeConfigs path = do
    (skBootstrap, _) <- ACUPS.generateKeyPair
    (skNode1, _) <- ACUPS.generateKeyPair
    (skNode2, _) <- ACUPS.generateKeyPair
    let bootstrapPort = 8080
        bootstrapConfig = Config.Config bootstrapPort bootstrapPort skBootstrap [] (generateNodeId skBootstrap) (Data.Text.pack path <> "/bootstrapNode.log")
        config1 = Config.Config 8081 8081 skNode1 [Peer (generateNodeId skBootstrap,
NodeEndPoint "127.0.0.1" bootstrapPort bootstrapPort)] (generateNodeId skNode1) (Data.Text.pack path <> "/node1.log")
        config2 = Config.Config 8082 8082 skNode2 [Peer (generateNodeId skBootstrap,
NodeEndPoint "127.0.0.1" bootstrapPort bootstrapPort)] (generateNodeId skNode2) (Data.Text.pack path <> "/node2.log")
    Config.makeConfig bootstrapConfig (path <> "/bootstrapConfig.yaml")
    Config.makeConfig config1 (path <> "/config1.yaml")
    Config.makeConfig config2 (path <> "/config2.yaml")
-}
defaultConfig :: FilePath -> IO ()
defaultConfig path = do
    (sk, _) <- ACUPS.generateKeyPair
    let config =
            Config.Config
                5678
                5678
                sk
                []
                (generateNodeId sk)
                "127.0.0.1"
                (Data.Text.pack (path <> "/node.log"))
    Config.makeConfig config (path <> "/config.yaml")

runNode :: String -> IO ()
runNode configPath = do
    config <- Config.readConfig configPath
    let ha = Config.myIp config
    env <-
        makeP2Pinstance
            (generateNodeId (Config.secretKey config))
            ha
            (Config.tcpPort config)
            (Config.udpPort config)
            "127.0.0.1"
            8125
            "Xoken"
            (Config.secretKey config)
            20
            5
            3
    runFileLoggingT (toS $ Config.logFile config) $
    -- runStdoutLoggingT $
        runAppM
            env
            -- (runTcpServer (show (Config.tcpPort config))  newIncomingConnection)
            (do tid <-
                    async
                        (runTcpServer
                             (show (Config.udpPort config))
                             newIncomingConnection)
                mapM_ initBootStrap (Config.trustedPeers config)
                loadDefaultPeers (Config.trustedPeers config)
                wait tid
            -- let (bsNodeId, bsNodeEndPoint) = getPeer $ Prelude.head (Config.trustedPeers config)
            -- handleOrFail <- openConnection (nodeIp bsNodeEndPoint) (tcpPort bsNodeEndPoint) TCP bsNodeId
            -- case handleOrFail of
            --     Left e -> throw e
            --     Right cHandle -> do
            --         time <- liftIO getCurrentTime
            --         liftIO $ print timep
            --         mapConcurrently_
            --             (const (send cHandle (a 1024)))
            --             [1 .. 10]
            --         forever $ recv cHandle
            --         time2 <- liftIO getCurrentTime
            --         liftIO $ print time2
            -- liftIO $ print "done"
             )

runBSNode :: String -> IO ()
runBSNode configPath = do
    config <- Config.readConfig configPath
    let ha = "127.0.0.1"
    env <-
        makeP2Pinstance
            (generateNodeId (Config.secretKey config))
            ha
            (Config.tcpPort config)
            (Config.udpPort config)
            "127.0.0.1"
            8125
            "Xoken"
            (Config.secretKey config)
            20
            5
            3
    runFileLoggingT (toS $ Config.logFile config) $
    -- runStdoutLoggingT $
        runAppM
            env
            (runTcpServer (show (Config.tcpPort config)) newIncomingConnection
            --async (runTcpServer (show (Config.udpPort config)) newIncomingConnection)
            -- return ()
             )

main :: IO ()
main = do
    (path:_) <- getArgs
    b <- doesPathExist (path <> "/config.yaml")
    unless b (defaultConfig path)
    runNode (path <> "/config.yaml")
    --threadDelay 5000000
    --async (runNode (path <> "/config1.yaml"))
    --threadDelay 5000000
    --async (runNode (path <> "/config2.yaml"))
    --threadDelay 100000000
    --return ()

-- main' = do
--     [size, n] <- getArgs
--     _ <-
--         recipient receiver `concurrently`
--         (threadDelay 1000000 >> initiator sender size n)
--     return ()
a :: Int -> BSL.ByteString
a n = BSLC.pack (Prelude.replicate n 'a')

myAmazingHandler :: (HasLogging m, HasSecretKey m) => ConnectionHandle -> m ()
myAmazingHandler h = forever $ recv h >>= send h
