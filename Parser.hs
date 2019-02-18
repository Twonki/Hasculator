-- This module parses Strings to Terms
module Parser 
where 

import Data.Maybe (fromJust,isJust)
import Data.Either
import Numeric.Natural
import Terms
import Data.List
import Data.List.Split (splitOn)


parse :: String -> Term
parse = catchErrorTerms . termify . detectVarsAndNumbers . (map tokenToOperator) . tokenize'  

type Token = String 
type Parsable = Either Operator Term --For Readability - some declarations where wild
type Parsed = Either Term String -- TODO: Maybe use ErrorMonad?

data Operator = Plus
                | StarStar
                | Star
                | DivSlash
                | LnE
                | ExpFn
                | Minus
                | Neg
                | Lbr
                | Rbr
                deriving (Eq,Show)           

--TODO: Maybe use different datatype? Map? Array?
dictionary :: [(Token,Operator,Natural)]
dictionary = [("(",Lbr,2),(")",Rbr,2),("!",Neg,3),("Ln",LnE,3),("Exp",ExpFn,3),("^",StarStar,3),("*",Star,6),("/",DivSlash,6),("+",Plus,9),("-",Minus,9)]

-- This Function takes Either Term String and makes an errorterm if there was an error
catchErrorTerms :: Parsed -> Term
catchErrorTerms (Left err) = ErrorTerm err 
catchErrorTerms (Right t)  = t 

termify :: [Parsable] -> Parsed
termify [] = Left "EmptyTermErr"
termify [Left op] = Left "LostOperatorErr"
-- I've reached a single core term, such as a Variable or a Number (Or an already calculated Term)
termify [Right t] = Right t
-- I've got something bigger
termify toks
    | (isRight next)= Left "MissingOperatorErr" -- I've got a Term in a List of Tokens as next - this should never be possible! Happens if i put (1 + 2 2 3)
    | (isLeft next) =
        let 
            op = safeLeft next 
        in 
            -- I match the operators...
            case op of 
                -- If i got an opening bracket, I first go right from the bracket and termify that
                Lbr -> (termify (lhs ++ (applyBracket rhs)))
                -- Rbr -> termify ((applyBracket op lhs) ++ rhs) --This should not ever be the case?
                Rbr -> Left "LostClosingBracketErr"
                -- I've got an operator i've declared unary (unaries are below)
                _ | (elem op unaries) ->
                    let 
                        -- Get the right Term and apply the Operator to form new Term
                        rnb = safeRight (head rhs)  -- right neighboor 
                        rhs' = tail rhs
                        step = applyUnary op rnb
                    in 
                        -- Recursive step further with one Operator less
                        termify (lhs ++ (Right step) : rhs')
                -- I've got an Operator i've declared binary (such as +)
                _ | (elem op binaries) -> 
                    let
                        -- get Both Neighboors as Terms
                        rnb  = safeRight (head rhs) 
                        rhs' = tail rhs
                        lnb  = safeRight (last lhs) 
                        lhs' = init lhs
                        -- Apply the Operator to form a new Term
                        step = applyBinary lnb op rnb 
                    in
                        -- Recursive Step further with one Operator less
                        termify (lhs' ++ [Right step] ++ rhs')
    where 
       binaries = [Plus,Minus,Star,StarStar,DivSlash] 
       unaries  = [Neg,LnE,ExpFn]
       -- I split the List by the Lefthandside (LHS), Operator and Righthandside (RHS)
       (lhs,next,rhs) = splitByFirst toks

applyBracket :: [Parsable] -> [Parsable]
applyBracket toks
    | isLeft o =
        let 
            op = safeLeft o
        in
            case op of 
                Lbr         -> applyBracket (l ++ (applyBracket r))
                Rbr         -> (Right (safeRight (termify l))) : r
                otherwise   -> toks -- I've got every Bracket processed!
    | isRight o = toks
    where (l,o,r) = splitByFirst toks


applyUnary :: Operator -> Term -> Term 
applyUnary op t = 
    case op of 
        Neg     -> (negateTerm t) 
        LnE     -> Ln  t 
        ExpFn   -> Exp t
        -- Additional Unary Operators

applyBinary :: Term -> Operator -> Term -> Term 
applyBinary a op b =
    case op of 
        StarStar    -> Pow a b
        Star        -> Mul a b 
        DivSlash    -> Div a b 
        Plus        -> Add a b
        Minus       -> Sub a b
        -- Additional Binary Operators 

tokenToOperator :: Token -> Either Operator Token
tokenToOperator t = 
    let mop = lookup t ( map (\(a,b,c) -> (a,b)) dictionary)
    in 
        if mop == Nothing
        then Right t 
        else Left (fromJust mop)

detectVarsAndNumbers :: [Either Operator Token] -> [Parsable]
detectVarsAndNumbers lst = map f lst 
            where f (Right e) = Right (tokenToTerm e )
                  f (Left e) = Left e   

tokenToTerm :: Token -> Term 
tokenToTerm tok@(s:ss) 
            | not (elem s ['a'..'z'])       = Numb (read tok :: Double)
            | elem tok (map fst constants)  = Const tok
            | otherwise                     = Var tok

-- Assings the priority of each Term or Operator to it
precedence :: Parsable -> (Natural, Parsable)
precedence o = (priorityOf o,o)
    where 
        priorityOf (Right x) =  15
        priorityOf (Left x) = fromJust (lookup x ( map (\(a,b,c) -> (b,c)) dictionary))

splitByFirst :: [Parsable] -> ([Parsable],Parsable,[Parsable])
splitByFirst toks = splitBy (firstOperator toks) toks

splitBy :: Parsable -> [Parsable] -> ([Parsable],Parsable,[Parsable])
splitBy ops toks= 
                let (p:ps) = splitOn [ops] toks
                in (p, ops, intercalate [ops] ps)

firstOperator :: [Parsable] -> Parsable
firstOperator os = snd (foldl step (17,Right (ErrorTerm "PriorityErr")) (map precedence os))
                        where 
                            step old@(a,b) new@(c,d) 
                                | a > c= new
                                | otherwise = old

tokenize' :: String -> [String]
tokenize' s = filter (\n -> not (n==[])) (applySeps seps (words s))
    where 
        seps = (map (\(a,b,c) -> a :: String ) dictionary)
        applySep sep s' = concat (map (split' sep) s')
        applySeps [] s' = s'
        applySeps (x:xs) s' = applySeps xs (applySep x s')

split' :: String -> String -> [String]
split' sep str = intersperse sep (splitOn sep str) 

safeRight = fromRight (ErrorTerm "SafeRightErr")
safeLeft = fromLeft Minus