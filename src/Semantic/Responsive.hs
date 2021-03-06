module Semantic.Responsive
  ( module Properties
  , module Tools
  , Responsive(..), pattern Responsive
  , pattern OnlyMobile, pattern OnlyTablet
  , pattern OnlyComputer, pattern OnlyLargeScreen, pattern OnlyWidescreen
  )where

import Pure hiding (MinWidth,MaxWidth,(#))

import Control.Monad (join,unless,void)
import Data.IORef
import GHC.Generics as G

import Semantic.Utils

import Semantic.Properties as Tools ( HasProp(..) )

import Semantic.Properties as Properties
  ( pattern As, As(..)
  , pattern MinWidth, MinWidth(..)
  , pattern MaxWidth, MaxWidth(..)
  , pattern FireOnMount, FireOnMount(..)
  , pattern OnUpdate, OnUpdate(..)
  )

import Data.Function as Tools ((&))

data Responsive = Responsive_
    { as          :: Features -> [View] -> View
    , features    :: Features
    , children    :: [View]
    , fireOnMount :: Bool
    , maxWidth    :: Int
    , minWidth    :: Int
    , onUpdate    :: IO ()
    } deriving (Generic)

instance Default Responsive where
    def = (G.to gdef) { as = \fs cs -> Div & Features fs & Children cs }

pattern Responsive :: Responsive -> Responsive
pattern Responsive r = r

pattern OnlyMobile :: Responsive -> Responsive
pattern OnlyMobile r = (MinWidth 320 (MaxWidth 767 r))

pattern OnlyTablet :: Responsive -> Responsive
pattern OnlyTablet r = (MinWidth 768 (MaxWidth 991 r))

pattern OnlyComputer :: Responsive -> Responsive
pattern OnlyComputer r = (MinWidth 992 r)

pattern OnlyLargeScreen :: Responsive -> Responsive
pattern OnlyLargeScreen r = (MinWidth 1200 (MaxWidth 1919 r))

pattern OnlyWidescreen :: Responsive -> Responsive
pattern OnlyWidescreen r = (MinWidth 1920 r)

data ResponsiveState = RS
    { width   :: Int
    , handler :: IORef (IO ())
    , ticking :: IORef Bool
    }

instance Pure Responsive where
    view =
        Component $ \self ->
            let
                handleResize = do
                    RS {..} <- get self
                    tick <- readIORef ticking
                    unless tick $ do
                        writeIORef ticking True
                        void $ addAnimation handleUpdate

                handleUpdate = do
                    Responsive_ {..} <- ask self
                    RS {..} <- get self
                    writeIORef ticking False
                    w <- innerWidth
                    modify self $ \_ RS {..} -> RS { width = w, .. }
                    onUpdate

            in def
                { construct = RS <$> innerWidth <*> newIORef def <*> newIORef def

                , mounted = do
                    Responsive_ {..} <- ask self
                    RS {..} <- get self
                    Win w <- getWindow
                    h <- onRaw (Node w) "resize" def (\_ _ -> handleResize)
                    writeIORef handler h
                    fireOnMount # handleUpdate

                , unmounted = do
                    RS {..} <- get self
                    join $ readIORef handler
                    writeIORef handler def

                , render = \Responsive_ {..} RS {..} ->
                     (width <= maxWidth && width >= minWidth) #
                        as features children

                }

instance HasProp As Responsive where
    type Prop As Responsive = Features -> [View] -> View
    getProp _ = as
    setProp _ a r = r { as = a }

instance HasFeatures Responsive where
    getFeatures = features
    setFeatures as r = r { features = as }

instance HasChildren Responsive where
    getChildren = children
    setChildren cs r = r { children = cs }

instance HasProp FireOnMount Responsive where
    type Prop FireOnMount Responsive = Bool
    getProp _ = fireOnMount
    setProp _ fom r = r { fireOnMount = fom }

instance HasProp MaxWidth Responsive where
    type Prop MaxWidth Responsive = Int
    getProp _ = maxWidth
    setProp _ mw r = r { maxWidth = mw }

instance HasProp MinWidth Responsive where
    type Prop MinWidth Responsive = Int
    getProp _ = minWidth
    setProp _ mw r = r { minWidth = mw }

instance HasProp OnUpdate Responsive where
    type Prop OnUpdate Responsive = IO ()
    getProp _ = onUpdate
    setProp _ ou r = r { onUpdate = ou }
