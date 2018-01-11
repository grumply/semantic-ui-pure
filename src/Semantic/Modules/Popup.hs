{-# LANGUAGE UndecidableInstances #-}
module Semantic.Modules.Popup (module Semantic.Modules.Popup, module Export) where

import Control.Arrow ((&&&))
import Control.Concurrent
import Data.IORef
import Data.Maybe
import GHC.Generics as G
import Pure.Data.Txt (isInfixOf)
import Pure.View hiding (position,offset,round,trigger,OnClose)
import Pure.Lifted (JSV,Node(..),Element(..),(.#),window,IsJSV(..))

import Semantic.Utils hiding (on)

import Semantic.Modules.Popup.PopupContent as Export
import Semantic.Modules.Popup.PopupHeader as Export

import Semantic.Addons.Portal hiding (PS)

import Semantic.Properties.Children
import Semantic.Properties.OnMount
import Semantic.Properties.OnUnmount
import Semantic.Properties.OnOpen
import Semantic.Properties.OnClose
import Semantic.Properties.Trigger
import Semantic.Properties.CloseOnPortalMouseLeave
import Semantic.Properties.CloseOnTriggerBlur
import Semantic.Properties.CloseOnTriggerClick
import Semantic.Properties.CloseOnTriggerMouseLeave
import Semantic.Properties.CloseOnDocumentClick
import Semantic.Properties.OpenOnTriggerClick
import Semantic.Properties.OpenOnTriggerFocus
import Semantic.Properties.OpenOnTriggerMouseEnter
import Semantic.Properties.MouseEnterDelay
import Semantic.Properties.MouseLeaveDelay

positions = 
    [ "top left"
    , "top right"
    , "top center"
    , "bottom left"
    , "bottom right"
    , "bottom center"
    , "right center"
    , "left center"
    ]

data Popup ms = Popup_
    { as :: [Feature ms] -> [View ms] -> View ms
    , attributes :: [Feature ms]
    , children :: [View ms]
    , classes :: [Txt]
    , basic :: Bool
    , flowing :: Bool
    , hideOnScroll :: Bool
    , hoverable :: Bool
    , inverted :: Bool
    , offset :: Double
    , onClose :: Ef ms IO ()
    , onMount :: Ef ms IO ()
    , onOpen :: Ef ms IO ()
    , onUnmount :: Ef ms IO ()
    , position :: Txt
    , size :: Txt
    , styles :: [(Txt,Txt)]
    , trigger :: View ms
    , triggerOn :: [Txt]
    , wide :: Maybe Txt
    , withPortal :: Portal ms -> Portal ms
    } deriving (Generic)

instance Default (Popup ms) where
    def = (G.to gdef) 
        { as = Div
        , position = "top left"
        , triggerOn = [ "hover" ] 
        }

pattern Popup :: VC ms => Popup ms -> View ms
pattern Popup p = View p

data PopupState = PS
    { closed :: Bool
    , currentStyles :: [(Txt,Txt)]
    , currentPosition :: Txt
    , coords :: IORef BoundingRect
    , popupCoords :: IORef BoundingRect
    , scrollHandler :: IORef (IO ())
    }

instance VC ms => Pure Popup ms where
    render p =
        Component "Semantic.Modules.Popup" p $ \self ->
            let
                bounds = do
                    let fi = fromIntegral :: Int -> Double
                    (fi -> pxo,fi -> pyo,fi -> cw,fi -> ch) 
                        <- (,,,) <$> pageXOffset 
                                 <*> pageYOffset 
                                 <*> clientWidth 
                                 <*> clientHeight
                    return (pxo,pyo,cw,ch)

                computePopupStyle offset pbr cbr (pxo,pyo,cw,ch) p =
                    let xOff = brWidth pbr + 8

                        isLeft   = left   `isInfixOf` p
                        isRight  = right  `isInfixOf` p
                        isTop    = top    `isInfixOf` p
                        isBottom = bottom `isInfixOf` p

                        centerV = not (isTop  || isBottom)

                        leftStyle
                            | isRight           = Nothing
                            | isLeft            = Just 0
                            | otherwise         = Just $ (brWidth cbr - brWidth pbr) / 2

                        leftStyle' = fmap (\l -> l + pxo + brLeft cbr - offset) leftStyle

                        leftStyle''
                            | centerV   = fmap (subtract xOff) leftStyle'
                            | otherwise = leftStyle'

                        rightStyle
                            | isRight   = Just 0
                            | otherwise = Nothing

                        rightStyle' = fmap (\r -> r + cw - (brRight cbr + pxo) - offset) rightStyle

                        rightStyle''
                            | centerV   = fmap (subtract xOff) rightStyle'
                            | otherwise = rightStyle

                        topStyle
                            | isTop     = Nothing
                            | isBottom  = Just 0 
                            | otherwise = Just $ negate $ (brHeight cbr + brHeight pbr) / 2

                        topStyle' = fmap (\t -> t + brBottom cbr + pyo) topStyle

                        bottomStyle
                            | isTop     = Just 0
                            | otherwise = Nothing

                        bottomStyle' = fmap (\b -> b + ch - (brTop cbr + pyo)) bottomStyle

                    in (leftStyle'',rightStyle'',topStyle',bottomStyle')

                isStyleInViewport BR {..} (pxo,pyo,cw,ch) (l,r,t,b) =
                    let 
                        leftValue 
                            | isJust r  = maybe 0 (\_ -> cw - fromJust r - brWidth) l
                            | otherwise = fromMaybe 0 l

                        topValue
                            | isJust b  = maybe 0 (\_ -> ch - fromJust b - brHeight) t
                            | otherwise = fromMaybe 0 t

                        visibleTop    = topValue >= pyo 
                        visibleBottom = topValue + brHeight <= pyo + ch
                        visibleLeft   = leftValue >= pyo
                        visibleRight  = leftValue + brWidth <= pxo + cw

                    in visibleTop && visibleBottom && visibleLeft && visibleRight
                
                setPopupStyles = do
                    PS {..} <- getState self
                    Popup_ {..} <- getProps self
                    cbr <- readIORef coords
                    pbr <- readIORef popupCoords
                    bs  <- bounds

                    (cbr /= def && pbr /= def) #
                        let 
                            render d x = (d,maybe auto (pxs . round) x)

                            compute = computePopupStyle offset pbr cbr bs

                            s = compute position

                            ps = (position,s) : map (id &&& compute) (filter (/= position) positions)

                            findValid [] = (position,s)
                            findValid ((p,c) : cs)
                                | isStyleInViewport pbr bs c = (p,c)
                                | otherwise                  = findValid cs

                            (p,(l,r,t,b)) = findValid ps

                        in 
                            setState self $ \_ PS {..} -> 
                                PS { currentStyles    = [render left l,render right r,render top t,render bottom b]
                                   , currentPosition = p
                                   , .. 
                                   }

                scrollHide = do
                    Popup_ {..} <- getProps self
                    PS {..} <- getState self
                    setState self $ \_ PS {..} -> PS { closed = True, .. }
                    join $ readIORef scrollHandler
                    forkIO $ do 
                        threadDelay 50000
                        void $ setState self $ \_ PS {..} -> PS { closed = False, .. }
                    void $ parent self onClose

                handleOpen (evtObj -> o) = do
                    Popup_ {..} <- getProps self
                    PS {..} <- getState self
                    br <- boundingRect (Element $ fromJust $ o .# "currentTarget")
                    liftIO $ writeIORef coords br
                    onOpen

                handlePortalMount = do
                    Popup_ {..} <- getProps self
                    PS {..} <- getState self
                    sh <- liftIO $ onRaw (Node $ toJSV window) "scroll" def (\_ _ -> liftIO scrollHide)
                    liftIO $ writeIORef scrollHandler sh
                    onMount

                handlePortalUnmount = do
                    Popup_ {..} <- getProps self
                    PS {..} <- getState self
                    liftIO $ join $ readIORef scrollHandler
                    onUnmount

                handlePopupRef (Node n) = do
                    br <- boundingRect (Element n)
                    PS {..} <- getState self
                    liftIO $ writeIORef popupCoords br
                    liftIO setPopupStyles
                    return Nothing

            in def
                { construct = PS def def "absolute" <$> newIORef def <*> newIORef def <*> newIORef def
                , renderer = \Popup_ {..} PS {..} -> 
                    let
                        applyPortalProps =
                            let
                                hoverableProps = hoverable ? (CloseOnPortalMouseLeave . MouseLeaveDelay 300) $ id
                                clickProps = ("click" `elem` triggerOn) ? (OpenOnTriggerClick . CloseOnTriggerClick . CloseOnDocumentClick) $ id
                                focusProps = ("focus" `elem` triggerOn) ? (OpenOnTriggerFocus . CloseOnTriggerBlur) $ id
                                hoverProps = ("hover" `elem` triggerOn) ? (OpenOnTriggerMouseEnter . CloseOnTriggerMouseLeave . MouseLeaveDelay 70 . MouseEnterDelay 50) $ id
                            in
                                hoverProps . focusProps . clickProps . hoverableProps

                        cs =
                            ( "ui"
                            : position
                            : size
                            : wide # "wide"
                            : basic # "basic"
                            : flowing # "flowing"
                            : inverted # "inverted"
                            : "popup transition visible"
                            : classes
                            )
                    in
                        closed 
                            ? trigger
                            $ Portal $ withPortal $ applyPortalProps $ def 
                                & OnClose onClose
                                & OnMount handlePortalMount 
                                & OnOpen handleOpen 
                                & OnUnmount handlePortalUnmount
                                & Trigger trigger
                                & Children
                                    [ as
                                        ( mergeClasses $ ClassList cs
                                        : StyleList styles
                                        : HostRef handlePopupRef
                                        : attributes
                                        )
                                        children
                                    ]
                }
