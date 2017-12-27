{-# LANGUAGE ScopedTypeVariables #-}
module Semantic.Elements.Input where

import GHC.Generics as G
import Pure.View as View hiding (Button,Label,Input)
import qualified Pure.View as HTML

import Semantic.Utils

import Semantic.Elements.Button
import Semantic.Elements.Icon
import Semantic.Elements.Label

import Semantic.Extensions.As
import Semantic.Extensions.Attributes
import Semantic.Extensions.Children
import Semantic.Extensions.Classes

data Input ms = Input_
    { as :: [Feature ms] -> [View ms] -> View ms
    , attributes :: [Feature ms]
    , children :: [View ms]
    , classes :: [Txt]
    , disabled :: Bool
    , error :: Bool
    , fluid :: Bool
    , focus :: Bool
    , focused :: Bool
    , inverted :: Bool
    , loading :: Bool
    , onChange :: Txt -> Ef ms IO ()
    , size :: Txt
    , tabIndex :: Maybe Int
    , transparent :: Bool
    , _type :: Txt
    } deriving (Generic)

instance Default (Input ms) where
    def = (G.to gdef) { as = Div, _type = "text" }

pattern Input :: Typeable ms => Input ms -> View ms
pattern Input i = View i

data InputFormatter = IF
  { inputSeen :: Bool
  , labelPosition :: Maybe Txt
  , iconPosition :: Maybe Txt
  , actionPosition :: Maybe Txt
  } deriving (Generic,Default)

calculatePositions :: forall ms. Typeable ms => [View ms] -> InputFormatter
calculatePositions = foldr analyze def
    where
        analyze :: View ms -> InputFormatter -> InputFormatter
        analyze (HTML.Input _ _) state = state { inputSeen = True }
        analyze (View Label{}) state
            | inputSeen state          = state { labelPosition = Just "" }
            | otherwise                = state { labelPosition = Just "left" }
        analyze (View Icon{}) state
            | inputSeen state          = state { iconPosition = Just "" }
            | otherwise                = state { iconPosition = Just "left" }
        analyze (View Button{}) state
            | inputSeen state          = state { actionPosition = Just "" }
            | otherwise                = state { actionPosition = Just "left" }
        analyze _ state                = state

instance Typeable ms => Pure Input ms where
    render Input_ {..} =
        let
            _focus e = do
                focusNode e
                return Nothing

            addInputProps :: View ms -> View ms
            addInputProps (HTML.Input fs cs) =
                HTML.Input 
                    (( HostRef ((focused #) . _focus)
                    : Disabled disabled 
                    : Type _type 
                    : index 
                    : onInput onChange 
                    : inputAttrs
                    ) ++ fs)
                    cs
            
            addInputProps c = c

            (inputAttrs,otherAttrs) = extractInputAttrs attributes

            index = maybe (disabled # Tabindex (-1)) Tabindex tabIndex

            IF {..} = calculatePositions children

            cs =
                ( "ui"
                : size
                : disabled # "disabled"
                : error # "error"
                : fluid # "fluid"
                : focus # "focus"
                : inverted # "inverted"
                : loading # "loading"
                : transparent # "transparent"
                : may (<>> "action")  actionPosition
                : may (<>> "icon")    iconPosition
                : may (<>> "labeled") labelPosition
                : "input"
                : classes
                )
        in
            as
                ( ClassList cs
                : otherAttrs
                )
                ( map addInputProps children )

instance HasAs (Input ms) where
    type Constructor (Input ms) = [Feature ms] -> [View ms] -> View ms
    getAs = as
    setAs f i = i { as = f }

instance HasAttributes (Input ms) where
    type Attribute (Input ms) = Feature ms
    getAttributes = attributes 
    setAttributes cs i = i { attributes = cs }

instance HasChildren (Input ms) where
    type Child (Input ms) = View ms
    getChildren = children
    setChildren cs i = i { children = cs }

instance HasClasses (Input ms) where
    getClasses = classes
    setClasses cs i = i { classes = cs }