module Types.Signature
    ( Signature
    , empty
      -- * Definitions
    , getDefinition
    , addDefinition
      -- * MetaVars
    , MetaInst(..)
    , getMetaInst
    , addFreshMetaVar
    , instantiateMetaVar
    ) where

import qualified Data.Map                         as Map

import           Syntax.Abstract                  (Name)
import           Types.Definition
import           Types.Var

data Signature t = Signature
    { sDefinitions :: Map.Map Name (Definition t)
    , sMetaStore   :: Map.Map MetaVar (MetaInst t)
    }

empty :: Signature t
empty = Signature Map.empty Map.empty

getDefinition :: Signature t -> Name -> Definition t
getDefinition sig name =
    case Map.lookup name (sDefinitions sig) of
      Nothing  -> error $ "impossible.getDefinition: not found " ++ show name
      Just def -> def

addDefinition :: Signature t -> Name -> Definition t -> Signature t
addDefinition sig name def =
    sig{sDefinitions = Map.insert name def (sDefinitions sig)}

data MetaInst t
    = Open (Closed t) -- Type
    | Inst (Closed t) -- Type
           (Closed t) -- Body

getMetaInst :: Signature t -> MetaVar -> MetaInst t
getMetaInst sig name =
    case Map.lookup name (sMetaStore sig) of
      Nothing -> error $ "impossible.getMetaInst: not found " ++ show name
      Just d -> d

addFreshMetaVar :: Signature t -> Closed t -> (MetaVar, Signature t)
addFreshMetaVar sig type_ =
    (mv, sig{sMetaStore = Map.insert mv (Open type_) (sMetaStore sig)})
  where
    mv = case Map.maxViewWithKey (sMetaStore sig) of
        Nothing                  -> MetaVar 0
        Just ((MetaVar i, _), _) -> MetaVar (i + 1)

instantiateMetaVar :: Signature t -> MetaVar -> Closed t -> Signature t
instantiateMetaVar sig mv term =
    sig{sMetaStore = Map.insert mv (Inst type_ term) (sMetaStore sig)}
  where
    type_ = case getMetaInst sig mv of
      Inst _ _   -> error "Types.Signature.instantiateMetaVar: already instantiated"
      Open type' -> type'
