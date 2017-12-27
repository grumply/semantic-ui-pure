{-# LANGUAGE UndecidableInstances #-}
module Semantic.Elements.List (module Semantic.Elements.List, module Export) where

import GHC.Generics as G
import Pure.View hiding (horizontal,onClick)

import Semantic.Utils

import Semantic.Elements.List.ListContent as Export
import Semantic.Elements.List.ListDescription as Export
import Semantic.Elements.List.ListHeader as Export
import Semantic.Elements.List.ListIcon as Export
import Semantic.Elements.List.ListItem as Export
import Semantic.Elements.List.ListList as Export

import Semantic.Properties.Animated
import Semantic.Properties.As
import Semantic.Properties.Attributes
import Semantic.Properties.Bulleted
import Semantic.Properties.Celled
import Semantic.Properties.Children
import Semantic.Properties.Classes
import Semantic.Properties.Divided
import Semantic.Properties.Floated
import Semantic.Properties.Horizontal
import Semantic.Properties.Inverted
import Semantic.Properties.Link
import Semantic.Properties.OnClick

data List ms = List_
    { as :: [Feature ms] -> [View ms] -> View ms
    , attributes :: [Feature ms]
    , children :: [View ms]
    , classes :: [Txt]
    , animated :: Bool
    , bulleted :: Bool
    , celled :: Bool
    , divided :: Bool
    , floated :: Txt
    , horizontal :: Bool
    , inverted :: Bool
    , link :: Bool
    , onItemClick :: ListItem ms -> Ef ms IO ()
    , ordered :: Bool
    , relaxed :: Maybe Txt
    , selection :: Bool
    , size :: Txt
    , verticalAlign :: Txt
    } deriving (Generic)

instance Default (List ms) where
    def = (G.to gdef) { as = Div }

pattern List :: VC ms => List ms -> View ms
pattern List l = View l

instance VC ms => Pure List ms where
    render List_ {..} =
        let
            children' =
                mapPures (\li@(ListItem_ {}) -> li { onClick = onClick li >> onItemClick li }) children

            cs =
                ( "ui"
                : size
                : animated # "animated"
                : bulleted # "bulleted"
                : celled # "celled"
                : divided # "divided"
                : horizontal # "horizontal"
                : inverted # "inverted"
                : link # "link"
                : ordered # "ordered"
                : selection # "selection"
                : may (<>> "relaxed") relaxed
                : floated # (floated <>> "floated")
                : verticalAlign # (verticalAlign <>> "aligned")
                : "list"
                : classes
                )
        in
            as
                ( ClassList cs
                : attributes
                )
                children'

instance HasAnimatedProp (List ms) where
    type AnimatedProp (List ms) = Bool
    getAnimated = animated
    setAnimated anim l = l { animated = anim }

instance HasAsProp (List ms) where
    type AsProp (List ms) = [Feature ms] -> [View ms] -> View ms
    getAs = as
    setAs f l = l { as = f }

instance HasAttributesProp (List ms) where
    type Attribute (List ms) = Feature ms
    getAttributes = attributes 
    setAttributes cs l = l { attributes = cs }

instance HasBulletedProp (List ms) where
    getBulleted = bulleted
    setBulleted b l = l { bulleted = b }

instance HasCelledProp (List ms) where
    getCelled = celled
    setCelled c l = l { celled = c }

instance HasChildrenProp (List ms) where
    type Child (List ms) = View ms
    getChildren = children
    setChildren cs l = l { children = cs }

instance HasClassesProp (List ms) where
    getClasses = classes
    setClasses cs l = l { classes = cs }

instance HasDividedProp (List ms) where
    getDivided = divided
    setDivided d l = l { divided = d }

instance HasOnClickProp (List ms) where
    type OnClickProp (List ms) = ListItem ms -> Ef ms IO ()
    getOnClick = onItemClick
    setOnClick oc l = l { onItemClick = oc }

instance HasFloatedProp (List ms) where
    getFloated = floated
    setFloated f l = l { floated = f }

instance HasHorizontalProp (List ms) where
    getHorizontal = horizontal
    setHorizontal h l = l { horizontal = h }

instance HasInvertedProp (List ms) where
    getInverted = inverted
    setInverted i l = l { inverted = i }

instance HasLinkProp (List ms) where
    getLink = link
    setLink lnk l = l { link = lnk }