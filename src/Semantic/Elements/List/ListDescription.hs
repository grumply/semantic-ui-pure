module Semantic.Elements.List.ListDescription where

import GHC.Generics as G
import Pure.View

import Semantic.Utils

import Semantic.Extensions.As
import Semantic.Extensions.Attributes
import Semantic.Extensions.Children
import Semantic.Extensions.Classes

data ListDescription ms = ListDescription_
    { as :: [Feature ms] -> [View ms] -> View ms
    , attributes :: [Feature ms] 
    , children :: [View ms]
    , classes :: [Txt]
    } deriving (Generic)

instance Default (ListDescription ms) where
    def = (G.to gdef) { as = Div }

pattern ListDescription :: Typeable ms => ListDescription ms -> View ms
pattern ListDescription ld = View ld

instance Typeable ms => Pure ListDescription ms where
    render ListDescription_ {..} =
        as ( ClassList (classes ++ [ "description" ]) : attributes ) children

instance HasAs (ListDescription ms) where
    type Constructor (ListDescription ms) = [Feature ms] -> [View ms] -> View ms
    getAs = as
    setAs f ld = ld { as = f }

instance HasAttributes (ListDescription ms) where
    type Attribute (ListDescription ms) = Feature ms
    getAttributes = attributes 
    setAttributes cs ld = ld { attributes = cs }

instance HasChildren (ListDescription ms) where
    type Child (ListDescription ms) = View ms
    getChildren = children
    setChildren cs ld = ld { children = cs }

instance HasClasses (ListDescription ms) where
    getClasses = classes
    setClasses cs ld = ld { classes = cs }