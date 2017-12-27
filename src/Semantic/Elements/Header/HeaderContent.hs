module Semantic.Elements.Header.HeaderContent where

import GHC.Generics as G
import Pure.View

import Semantic.Utils

import Semantic.Extensions.As
import Semantic.Extensions.Attributes
import Semantic.Extensions.Children
import Semantic.Extensions.Classes

data HeaderContent ms = HeaderContent_
    { as :: [Feature ms] -> [View ms] -> View ms
    , attributes :: [Feature ms]
    , children :: [View ms]
    , classes :: [Txt]
    } deriving (Generic)

instance Default (HeaderContent ms) where
    def = (G.to gdef) { as = Div }

pattern HeaderContent :: Typeable ms => HeaderContent ms -> View ms
pattern HeaderContent hc = View hc

instance Typeable ms => Pure HeaderContent ms where
    render HeaderContent_ {..} =
        as 
            ( ClassList ( "content" : classes) 
            : attributes 
            ) 
            children

instance HasAs (HeaderContent ms) where
    type Constructor (HeaderContent ms) = [Feature ms] -> [View ms] -> View ms
    getAs = as
    setAs f hc = hc { as = f }

instance HasAttributes (HeaderContent ms) where
    type Attribute (HeaderContent ms) = Feature ms
    getAttributes = attributes 
    setAttributes cs hc = hc { attributes = cs }

instance HasChildren (HeaderContent ms) where
    type Child (HeaderContent ms) = View ms
    getChildren = children
    setChildren cs hc = hc { children = cs }

instance HasClasses (HeaderContent ms) where
    getClasses = classes
    setClasses cs hc = hc { classes = cs }