{-# OPTIONS_GHC -fth #-}
module Data.Derive.Eq(eq) where

import Data.Derive
import Data.List
import Language.Haskell.TH

eq = Derivation eq' "Eq"
eq' dat@(DataDef _ _ ctors) = simple_instance ''Eq dat [FunD '(==) (cases ++ [end])]
    where
        cases = map (\ctor -> rule (ctorName ctor) (ctorArity ctor)) ctors
        end = defclause 2 false

rule (CtorDef nam arity _) = clause pats (if arity == 0 then ConE 'True else body)
    where
        na c = map (vr . (c:) . show) [1..arity]
        pats = map (lK nam . na c) "ab"
        body = foldr1 (&&:) (zipWith (==:) (na 'a') (na 'b'))

-- | A simple clause, without where or guards
clause pats body = Clause pats (NormalB body) []

-- | A default clause with N arguments
defclause num = clause (replicate num WildP)

class Valcon a where
      lK :: String -> [a] -> a
      vr :: String -> a
instance Valcon Exp where
      lK nm@(x:_) | isLower x = foldl AppE (VarE (mkName nm))
      lK nm = foldl AppE (ConE (mkName nm))
      vr = VarE . mkName
instance Valcon Pat where
      lK = ConP . mkName
      vr = VarP . mkName

l0 s     = lK s []
l1 s a   = lK s [a]
l2 s a b = lK s [a,b]

-- lifting
true = l0 "True"
false = l0 "False"

(==:) = l2 "=="
(&&:) = l2 "&&"

-- | Build an instance of a class for a data type, using the heuristic
-- that the type is itself required on all type arguments.
simple_instance cls (DataDef name arity _) defs = [InstanceD ctx hed defs]
    where
        vars = map (VarT . mkName . ('t':) . show) [1..arity]
        hed = ConT cls `AppT` (foldl1 AppT (ConT (mkName name) : vars))
        ctx = map (ConT cls `AppT`) vars
