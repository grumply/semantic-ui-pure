module Semantic.Addons.Responsive where

import Data.IORef
import GHC.Generics as G
import Pure.View hiding (minWidth,maxWidth)
import Pure.DOM (addAnimation)
import Pure.Lifted (Win(..),Node(..),getWindow)

import Semantic.Utils

import Semantic.Properties.As
import Semantic.Properties.Attributes
import Semantic.Properties.Children
import Semantic.Properties.Classes
import Semantic.Properties.MinWidth
import Semantic.Properties.MaxWidth
import Semantic.Properties.FireOnMount
import Semantic.Properties.OnUpdate

data Responsive ms = Responsive_ 
    { as :: [Feature ms] -> [View ms] -> View ms
    , attributes :: [Feature ms]
    , children :: [View ms]
    , classes :: [Txt]
    , fireOnMount :: Bool
    , maxWidth :: Int
    , minWidth :: Int
    , onUpdate :: Ef ms IO ()
    } deriving (Generic)

instance Default (Responsive ms) where
    def = (G.to gdef) { as = Div }

pattern Responsive :: Typeable ms => Responsive ms -> View ms
pattern Responsive r = View r

pattern OnlyMobile :: Typeable ms => Responsive ms -> View ms
pattern OnlyMobile r = View (MinWidth 320 (MaxWidth 767 r))

pattern OnlyTablet :: Typeable ms => Responsive ms -> View ms
pattern OnlyTablet r = View (MinWidth 768 (MaxWidth 991 r))

pattern OnlyComputer :: Typeable ms => Responsive ms -> View ms
pattern OnlyComputer r = View (MinWidth 992 r)

pattern OnlyLargeScreen :: Typeable ms => Responsive ms -> View ms
pattern OnlyLargeScreen r = View (MinWidth 1200 (MaxWidth 1919 r))

pattern OnlyWidescreen :: Typeable ms => Responsive ms -> View ms
pattern OnlyWidescreen r = View (MinWidth 1920 r)

data ResponsiveState = RS
    { width :: Int
    , handler :: IORef (IO ())
    , ticking :: IORef Bool
    }

instance Typeable ms => Pure Responsive ms where
    render r =
        Component "Semantic.Addons.Responsive" r $ \self -> 
            let 
                handleResize = liftIO $ do
                    RS {..} <- getState self
                    tick <- readIORef ticking
                    unless tick $ do
                        writeIORef ticking True
                        void $ addAnimation handleUpdate

                handleUpdate = do
                    Responsive_ {..} <- getProps self
                    RS {..} <- getState self
                    writeIORef ticking False
                    w <- innerWidth
                    setState self $ \_ RS {..} -> RS { width = w, .. }
                    void $ parent self onUpdate 

            in def
                { construct = RS <$> innerWidth <*> newIORef def <*> newIORef def
                
                , mounted = do
                    Responsive_ {..} <- getProps self
                    RS {..} <- getState self
                    Win w <- getWindow
                    h <- onRaw (Node w) "resize" def (\_ _ -> handleResize)
                    writeIORef handler h
                    fireOnMount # handleUpdate

                , unmount = do
                    RS {..} <- getState self
                    join $ readIORef handler
                    writeIORef handler def

                , renderer = \Responsive_ {..} RS {..} ->
                     (width <= maxWidth && width >= minWidth) # 
                        as attributes children

                }

instance HasAsProp (Responsive ms) where
    type AsProp (Responsive ms) = [Feature ms] -> [View ms] -> View ms
    getAs = as
    setAs a r = r { as = a }

instance HasAttributesProp (Responsive ms) where
    type Attribute (Responsive ms) = Feature ms
    getAttributes = attributes
    setAttributes as r = r { attributes = as }

instance HasChildrenProp (Responsive ms) where
    type Child (Responsive ms) = View ms
    getChildren = children
    setChildren cs r = r { children = cs }

instance HasClassesProp (Responsive ms) where
    getClasses = classes
    setClasses cs r = r { classes = cs }

instance HasFireOnMountProp (Responsive ms) where
    getFireOnMount = fireOnMount
    setFireOnMount fom r = r { fireOnMount = fom }

instance HasMaxWidthProp (Responsive ms) where
    getMaxWidth = maxWidth
    setMaxWidth mw r = r { maxWidth = mw }

instance HasMinWidthProp (Responsive ms) where
    getMinWidth = minWidth
    setMinWidth mw r = r { minWidth = mw }

instance HasOnUpdateProp (Responsive ms) where
    type OnUpdateProp (Responsive ms) = Ef ms IO ()
    getOnUpdate = onUpdate
    setOnUpdate ou r = r { onUpdate = ou }