module Semantic.Elements.Loader where

import GHC.Generics as G
import Pure.View hiding (active,verticalAlign)

import Semantic.Utils

import Semantic.Extensions.Active
import Semantic.Extensions.As
import Semantic.Extensions.Attributes
import Semantic.Extensions.Children
import Semantic.Extensions.Classes

data Loader ms = Loader_ 
    { as :: [Feature ms] -> [View ms] -> View ms
    , attributes :: [Feature ms]
    , children :: [View ms]
    , classes :: [Txt]
    , active :: Bool
    , disabled :: Bool
    , indeterminate :: Bool
    , inline :: Maybe Txt
    , inverted :: Bool
    , size :: Txt
    } deriving (Generic)

instance Default (Loader ms) where
    def = (G.to gdef) { as = Div }

pattern Loader :: Typeable ms => Loader ms -> View ms
pattern Loader l = View l

instance Typeable ms => Pure Loader ms where
    render Loader_ {..} =
        let
            cs =
                ( "ui"
                : size
                : active # "active"
                : disabled # "disabled"
                : indeterminate # "indeterminate"
                : inverted # "inverted"
                : children # "text"
                : may (<>> "inline") inline
                : "loader"
                : classes
                )
        in
            as
                ( ClassList cs
                : attributes
                )
                children

instance HasActive (Loader ms) where
    getActive = active
    setActive a l = l { active = a }

instance HasAs (Loader ms) where
    type Constructor (Loader ms) = [Feature ms] -> [View ms] -> View ms
    getAs = as
    setAs f l = l { as = f }

instance HasAttributes (Loader ms) where
    type Attribute (Loader ms) = Feature ms
    getAttributes = attributes 
    setAttributes cs l = l { attributes = cs }

instance HasChildren (Loader ms) where
    type Child (Loader ms) = View ms
    getChildren = children
    setChildren cs l = l { children = cs }

instance HasClasses (Loader ms) where
    getClasses = classes
    setClasses cs l = l { classes = cs }