module Semantic.Views.Comment.CommentAuthor where

import GHC.Generics as G
import Pure.View

import Semantic.Utils

import Semantic.Properties.As
import Semantic.Properties.Attributes
import Semantic.Properties.Children
import Semantic.Properties.Classes

data CommentAuthor ms = CommentAuthor_
    { as :: [Feature ms] -> [View ms] -> View ms
    , attributes :: [Feature ms]
    , children :: [View ms]
    , classes :: [Txt]
    } deriving (Generic)

instance Default (CommentAuthor ms) where
    def = (G.to gdef) { as = Div }

pattern CommentAuthor :: Typeable ms => CommentAuthor ms -> View ms
pattern CommentAuthor ca = View ca

instance Typeable ms => Pure CommentAuthor ms where
    render CommentAuthor_ {..} =
        let
            cs =
                ( "author"
                : classes
                )
        in
            as
                ( ClassList cs
                : attributes
                )
                children

instance HasAsProp (CommentAuthor ms) where
    type AsProp (CommentAuthor ms) = [Feature ms] -> [View ms] -> View ms
    getAs = as
    setAs a ca = ca { as = a }

instance HasAttributesProp (CommentAuthor ms) where
    type Attribute (CommentAuthor ms) = Feature ms
    getAttributes = attributes
    setAttributes as ca = ca { attributes = as }

instance HasChildrenProp (CommentAuthor ms) where
    type Child (CommentAuthor ms) = View ms
    getChildren = children
    setChildren cs ca = ca { children = cs }

instance HasClassesProp (CommentAuthor ms) where
    getClasses = classes
    setClasses cs ca = ca { classes = cs }