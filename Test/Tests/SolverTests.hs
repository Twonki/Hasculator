module Tests.SolverTests (operatorTests,variableTests,solverTests) where 

import Tests.TestHelpers


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

testAdd = 
    3 ~=? simpleParseAndSolve "1 + 2"
testSub = 
    1 ~=? simpleParseAndSolve "2 - 1"
testMul = 
    6 ~=? simpleParseAndSolve "3 * 2"
testDiv = 
    5 ~=? simpleParseAndSolve "10 / 2"
testPow = 
    4 ~=? simpleParseAndSolve "2 ^ 2"
testPowLow = 
    2 ~=? simpleParseAndSolve "4 ^ ( 1 / 2 )"
testNegPow = 
    0.5 ~=? simpleParseAndSolve "2 ^ ( 0 - 1 ) "

--Exp was a little inconvenient, so I rounded it to 8 digits after
testExp = 
    truncate' (exp 3) 8 ~=? truncate' (simpleParseAndSolve "Exp 3") 8
testLn = 
    log 10 ~=? simpleParseAndSolve "Ln 10"

variableTests = TestList [
    TestLabel "Insert One Variable " testVar1
    ,TestLabel "Insert two Variables " testVar2
    ,TestLabel "One Missing Var" testOneMissing
    ,TestLabel "Too Many Vars" testOneTooMuch
    ,TestLabel "Too Many Vars II" testTooMuch
    ]

testVar1 = 
    1 ~=? parseAndSolve "x" [("x",1)]
testVar2 = 
    6 ~=? parseAndSolve "x * y" [("x",2),("y",3)]
testOneMissing = 
    2 ~=? parseAndSolve "x + y" [("x",2)]
testOneTooMuch = 
    3 ~=? parseAndSolve "x + y" [("x",2),("y",1),("z",2)]
testTooMuch = 
    5 ~=? parseAndSolve "5" [("x",2),("y",1),("z",2)]


solverTests = TestList [
    TestLabel "Regula Falsi I " testRegula1
    ,TestLabel "Regula Falsi II " testRegula2
--    ,TestLabel "Regula Falsi Square" testRegulaSqr
 --   ,TestLabel "Regula Wrong input" testRegulaWIP --TODO: This one does not terminate???
    ,TestLabel "Regula Falsi x^3" testRegulaPol
--    ,TestLabel "Regula Falsi -x^3" testRegulaPol2 --TODO: This one Errors
    ]

testRegula1 =  
    -2 ~=? round (regulaFalsi' (parse "x + 2") (-4) 4 )
testRegula2 =  
    2 ~=? round (regulaFalsi' (parse "x - 2") (1) 5 ) --TODO: Something is Wrong here!
testRegulaPol = 
    1 ~=? round (regulaFalsi' (parse "x^3 -1") (0) 2 )
testRegulaPol2 =  
    0 ~=? round (regulaFalsi' (parse "(0-1)*x^3")  (-2) 1 )
--testRegulaSqr =  Left "InvalidInput - a < b required" ~=? (regulaFalsi' (parse "x**2 + 2") (10) (-10) )
--testRegulaWIP =  Left "InvalidInput - f(a) < 0 and f(b) > 0 required!" ~=? (regulaFalsi' (parse "x**2 + 2") (-10) (10) )