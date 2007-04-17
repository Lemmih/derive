-- | The main TH driver module.  It is intended that this need be the
-- only module imported by user code; it takes care of all data
-- threading issues such that all one needs to do is:
--
-- @
--   data Foo = Foo ; $( derive 'Data.Derive.StdDerivations.eq' ''Foo )
-- @
module Data.DeriveTH
       (derive,
        -- * Convienience re-exports
        Derivation, -- abstract!
        -- * Internal
        _derive_string_instance
       ) where

import Data.List
import Control.Monad (liftM)

import Language.Haskell.TH.All


-- | Derive an instance of some class. @derive@ only derives instances
-- for the type of the argument.
derive :: Derivation -> Name -> Q [Dec]
derive (Derivation f _) = liftM f . deriveOne

-- | Derive for a type and print the code to standard output.  This is
-- a internal hook for the use of the Derive executable.
_derive_string_instance :: Derivation -> Name -> Q Exp
_derive_string_instance (Derivation f _) nm =
    return . LitE . StringL . (++"\n\n") . show . ppr . peephole . f =<< deriveOne nm
    

-- | Extract a 'DataDef' value from a type using the TH 'reify'
-- framework.
deriveOne :: Name -> Q DataDef
deriveOne x = liftM extract (reify x)

extract (TyConI decl) = normData decl
extract _ = error $ "Data.Derive.TH.deriveInternal: not a type!"
