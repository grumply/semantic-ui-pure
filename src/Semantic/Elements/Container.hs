module Semantic.Elements.Container where

import GHC.Generics as G
import Pure.View

import Semantic.Utils

data Container ms = Container_
  { as :: [Feature ms] -> [View ms] -> View ms
  , children :: [View ms]
  , attributes :: [Feature ms]
  , classes :: [Txt]
  , fluid :: Bool
  , text :: Bool
  , textAlign :: Maybe TextAlignment
  } deriving (Generic)

instance Default (Container ms) where
    def = (G.to gdef) { as = Div }

pattern Container :: Typeable ms => Container ms -> View ms
pattern Container c = View c

instance Typeable ms => Pure Container ms where
    render Container_ {..} =
        let cs = 
              ( "ui"
              : text # "text"
              : fluid # "fluid"
              : textAlign # textAlignClass textAlign
              : "container"
              : classes
              )
        in as (ClassList cs : attributes) children