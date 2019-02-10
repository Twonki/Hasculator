import Test.HUnit
import Terms 
import Parser
import Solver

import Control.Exception

allTests = TestList [
     TestLabel "ParserTests" coreParserTests
    ,TestLabel "OperatorTests" operatorTests
    ,TestLabel "TokenizerTests" tokenizerTests
    ,TestLabel "PrecedenceTests" precedenceTests
    ,TestLabel "VariableTests" variableTests
--    ,TestLabel "SolverTests" solverTests --TODO: These sometimes do not stop?
    ,TestLabel "SpecialTests" specialTests
    ]
    

coreParserTests = TestList [
     TestLabel "Single Number Parsing" parSingleNumb 
    ,TestLabel "Single Variable Parsing" parSingleVar
    ,TestLabel "Longer Variable Parsing" parLongerVar
    ,TestLabel "SingleBrackets" parBracketedNumb
    ,TestLabel "DoubleBrackets" parDoubleBracketedNumb
    ,TestLabel "Constant" parConst
    ,TestLabel "NoConst" parConstExtra

    ,TestLabel "Lost Bracket" lostBracket
    ,TestLabel "Missing Operator" tooManyTerms
    ,TestLabel "Missing Arguments" missingArgs
    ,TestLabel "Empty Term" emptyTerm
    ,TestLabel "Empty Term (Empty Brackets)" emptyBrackets
    ]

--Simple Parsing
parSingleNumb = 1 ~=? (simParSolv "1")
parSingleNumb2 =  (simParSolv "1") ~=? 1 
parSingleVar  = 0 ~=? (simParSolv "a")
parLongerVar  = 0 ~=? (simParSolv "long")
parConst      = exp(1) ~=? (simParSolv "e")
parConstExtra = 0 ~=? (simParSolv "ee")

parBracketedNumb = 1 ~=? (simParSolv "( 1 )")
parDoubleBracketedNumb = 1 ~=? (simParSolv "( ( 1 ) )")

-- ErrorHandling
lostBracket = 1 ~=? (parSolv "1 )" [("LostClosingBracketErr",1)])
tooManyTerms = 1 ~=? (parSolv "1 a" [("MissingOperatorErr",1)]) 
missingArgs = 1 ~=? (parSolv "+" [("LostOperatorErr",1)])
emptyTerm = 1 ~=? (parSolv " " [("EmptyTermErr",1)])
emptyBrackets = 1 ~=? (parSolv "( )" [("EmptyTermErr",1)])

tokenizerTests = TestList [
    TestLabel "NoSpaces I" testNsp1
    ,TestLabel "NoSpaces II" testNsp2
    ,TestLabel "NoSpaces III" testNsp3
    ,TestLabel "MixedSpaces I" testMsp1
    ,TestLabel "MixedSpaces II" testMsp2
    ,TestLabel "FullSpaces I" testFsp1
    ,TestLabel "Overfull Spaces I" testOfsp1
    ,TestLabel "Overfull Spaces II" testOfsp2
    ]

testNsp1 = 3 ~=? (simParSolv "1+2")
testNsp2 = 10 ~=? (simParSolv "(1+2*4)+1")
testNsp3 = 16 ~=? (simParSolv "3*2+2*5")
testMsp1 = 3 ~=? (simParSolv "1 +2")
testMsp2 = 10 ~=? (simParSolv "(1+ 2* 4)+1 ")
testFsp1 = 6 ~=? (simParSolv " 3 * 2 ")
testOfsp1 = 10 ~=? (simParSolv "(1  + 2*  4) +1   ")
testOfsp2 = 10 ~=? (simParSolv "   (    1+    2* 4   )    +1 ")

operatorTests = TestList [
    TestLabel "Addition" testAdd 
    ,TestLabel "Substraction" testSub
    ,TestLabel "Multiplication" testMul 
    ,TestLabel "Divion" testDiv 
    ,TestLabel "NaturalLog" testLn
    ,TestLabel "Power" testPow
    ,TestLabel "SmallerPow" testPowLow
    ,TestLabel "NegativePow" testNegPow
    ,TestLabel "Exp" testExp 
    ]

testAdd = 3 ~=? (simParSolv "1 + 2")
testSub = 1 ~=? (simParSolv "2 - 1")
testMul = 6 ~=? (simParSolv "3 * 2")
testDiv = 5 ~=? (simParSolv "10 / 2")
testPow = 4 ~=? (simParSolv "2 ^ 2")
testPowLow = 2 ~=? (simParSolv "4 ^ ( 1 / 2 )")
testNegPow = 0.5 ~=? (simParSolv "2 ^ ( 0 - 1 ) ")
--Exp was a little Bitchy, so i rounded it to 8 digits after
testExp = truncate' (exp 3) 8 ~=? truncate' (simParSolv "Exp 3") 8
testLn = log 10 ~=? (simParSolv "Ln 10")


precedenceTests = TestList [
    TestLabel " Point > Stick"      testPS
    ,TestLabel " Power > Point"     testPP
    ,TestLabel "Fns > Point"        testFPoi
    ,TestLabel "Fns > Power"        testFPow
    ,TestLabel "Brackets Unary"     testBU
    ,TestLabel "Brackets Binary"    testBB
    ,TestLabel "Stick = Stick"      testSES
    ,TestLabel "Power = Power"      testPEP
    ]

testPS = 5 ~=? (simParSolv "1 + 2 * 2")
testPP = 12 ~=? (simParSolv "3 * 2 ^ 2 ")
testFPoi = (truncate' ((exp 3) * 3) 8) ~=? truncate' (simParSolv "Exp 3 * 3") 8
testFPow = (truncate' ((exp 3) ** 2) 8) ~=? truncate' (simParSolv "Exp 3 ^ 2 ") 8
testBU = truncate' (exp 3) 8 ~=? truncate' (simParSolv "Exp ( 1 + 2 )") 8
testBB = 6 ~=? (simParSolv "( 1 + 1 ) * 3")
testSES = 3 ~=? (simParSolv "2 + 2 - 1")
testPEP = 8 ~=? (simParSolv "( 1 * 2 ) + ( 2 * 3 )")

variableTests = TestList [
    TestLabel "Insert One Variable " testVar1
    ,TestLabel "Insert two Variables " testVar2
    ,TestLabel "One Missing Var" testOneMissing
    ,TestLabel "Too Many Vars" testOneTooMuch
    ,TestLabel "Too Many Vars II" testTooMuch
    ]

testVar1 = 1 ~=? (parSolv "x" [("x",1)])
testVar2 = 6 ~=? (parSolv "x * y" [("x",2),("y",3)])
testOneMissing = 2 ~=? (parSolv "x + y" [("x",2)])
testOneTooMuch = 3 ~=? (parSolv "x + y" [("x",2),("y",1),("z",2)])
testTooMuch = 5 ~=? (parSolv "5" [("x",2),("y",1),("z",2)])

solverTests = TestList[
    TestLabel "Regula Falsi I " testRegula1
    ,TestLabel "Regula Falsi II " testRegula2
--    ,TestLabel "Regula Falsi Square" testRegulaSqr
--    ,TestLabel "Regula Wrong input" testRegulaWIP
    ,TestLabel "Regula Falsi x^3" testRegulaPol
    ]

testRegula1 =  (-2) ~=? round (regulaFalsi (parse "x + 2") 100 (-4) 4 )
testRegula2 =  (2) ~=? round (regulaFalsi (parse "x - 2") 100 (-5) 5 ) --TODO: Something is Wrong here!
testRegulaPol =  (1) ~=? round (regulaFalsi (parse "x^3 -1") 100 (-2) 2 )
--TODO: How do i check for error messages?
--testRegulaSqr =  assertFailure "InvalidInput - a < b required"  (round (regulaFalsi (parse "x**2 + 2") 100 (-10) 10 ))
--testRegulaWIP =  FAILURE ~=? round (regulaFalsi (parse "x**2 + 2") 100 10 (-10) )

-- These Special Testcases originate from special bugs i've encountered and worked through,
-- They should be therefore checked forever after so i will hopefully never see them again
specialTests = TestList [
     TestLabel "Greedy Functions I " testGF1
    ,TestLabel "Greedy Functions II " testGF2
    ,TestLabel "Unnecessary Brackets" testUnBr
    ,TestLabel "Long Lost Bracket" testLongLostBR
    ]

-- All Originate from problems with the brackets
-- The first two usually resolved as follows ( Exp (1 + 2 ) + 3 ) = Exp 6 (Which is wrong btw)
testGF1 = (truncate' ((exp 3) + 3) 8) ~=? truncate' (simParSolv "( Exp ( 1 + 2 ) + 3 )") 8
testGF2 = (truncate' ((log 3) * 3) 8) ~=? truncate' (simParSolv "( ( Ln ( 1 + 2 ) ) * 3 ) ") 8
testUnBr = 5 ~=? simParSolv "( ( 1 + ( 2 ) ) ) + ( 1 + ( ( 1 ) + ( 0 ) ) )"
testLongLostBR = 1 ~=? (parSolv "( ( ( 1 + ( 1 + 0 ) ) ) + ( 2 ) ) )" [("LostClosingBracketErr",1)])

------------------------------------
-- Helpers
------------------------------------ 

--These methods shorthand some tests
parSolv :: String -> [(String, Double)] -> Double
parSolv str vars = solve (parse str) vars
--Solves the Term for no-Variables (or every Variable 0)
simParSolv :: String -> Double 
simParSolv str = (parSolv str []) 

truncate' :: Double -> Int -> Double
truncate' x n = (fromIntegral (floor (x * t))) / t
    where t = 10^n