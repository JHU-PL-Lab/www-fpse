module Main where

import Data.Foldable
import Data.Function
import Data.Functor
import Data.List
import Data.Monoid
import Control.Monad
import Control.Monad.State
import Control.Monad.Except
import Control.Comonad
import Control.Arrow







main :: IO ()
main = do
    putStrLn "Hello"


    

{-

    The most prevalent features in Haskell which affect
    how the language is used are

    - Laziness
    - Typeclasses 
	- Monads

-}


fib0 n =
    if n == 0 then 0 else
    if n == 1 then 1 else
    fib0 (n - 1) + fib0 (n - 2)



fib1 n = case n of
    0 -> 0
    1 -> 1
    n -> fib1 (n - 1) + fib1 (n - 2)



fib2 0 = 0
fib2 1 = 1
fib2 n = fib2 (n - 1) + fib2 (n - 2)



fib3 n
    | n < 2     = n
    | otherwise = 
        fib3 (n - 1) + fib3 (n - 2)




-- pretty normal list syntax
someList = [1, 2, 3, 4, 5]

-- some convenient range shorthands
rangedList = [1 .. 100]


-- list comprehensions!
comprehensive =
    [ x | x <- rangedList, even x, x*x < 100 ]

comprehensive' =
    [ x * y
    | x <- map (3 *) naturals
    , y <- map (2 *) naturals
    ]

comprehensive'' =
    [ (x, y, z)
    | z <- [1 .. 3]
    , y <- [1 .. z]
    , x <- [1 .. y]
    ]


sumList :: [Integer] -> Integer
sumList [] = 0
sumList (x:xs) = x + sumList xs


sumList' :: [Integer] -> Integer
sumList' = foldr (+) 0


totalOddGt50 l = sumList (filter odd l) > 50

totalOddGt50' = (> 50) . sumList . filter odd

totalOddGt50'' = 
    filter odd
    >>> sumList
    >>> (> 50)



-- laziness means data structures can be infinite.
naturals = [1 ..]






-- slow! but, still cool.
fibs0 = map fib1 naturals



-- very fast!!
fibs1 = 0 : 1 : zipWith (+) fibs1 (tail fibs1)



-- also fast
fibs2 = 0 : scanl (+) 1 fibs2




primes = 2 : filter isPrime [3..]

isPrime n =
    not . any (\p -> n `mod` p == 0) $ 
        takeWhile (\p -> n >= p*p) primes




isPrime' n =
    let smallPrimes = takeWhile (\p -> n >= p*p) primes in
    not . any (\p -> n `mod` p == 0) $ smallPrimes

isPrime'' n = not . any (\p -> n `mod` p == 0) $ smallPrimes
    where
        smallPrimes = takeWhile (\p -> n >= p*p) primes




-- but what is this "Eq a" and "Foldable t" and "Num p" business..?


data Money
    = USD Integer
    | JPY Integer
    deriving (Eq, Show)

-- make example instances of Eq, Show


data BTree a
    = Leaf
    | Branch (BTree a) a (BTree a)
    deriving (Eq, Ord, Show)

-- powerful deriving ability in general
deriving instance Functor BTree




data Rectangle = Rect { x0, y0, x1, y1 :: Double }
    deriving (Eq, Show)

enclose :: Rectangle -> Rectangle -> Rectangle
enclose r1 r2 = Rect 
    { x0 = min (x0 r1) (x0 r2)
    , y0 = min (y0 r1) (y0 r2)
    , x1 = max (x1 r1) (x1 r2)
    , y1 = max (y1 r1) (y1 r2)
    }


data Circle = Circle { radius :: Double }
    deriving (Eq, Show)

scale :: Double -> Circle -> Circle
scale d (Circle r) = Circle (r * d)


class Shape s where
    area :: s -> Double
    perimeter :: s -> Double


instance Shape Rectangle where
    area (Rect x0 y0 x1 y1) = (x1 - x0) * (y1 - y0)
    perimeter Rect{..} =
        2*(x1 - x0) + 2*(y1 - y0)

instance Shape Circle where
    area (Circle r) = pi * r**2
    perimeter (Circle r) = 2 * pi * r


smaller :: Shape s => s -> s -> s
smaller s1 s2
    | area s1 < area s2 = s1
    | otherwise = s2

smaller' :: (Shape s, Shape t) => s -> t -> Bool
smaller' s t = (area s < area t)



data Zipper a = Zipper 
    { backwards :: [a]
    , here      ::  a
    , forwards  :: [a]
    }
    deriving (Eq, Ord, Show, Functor, Traversable)


instance Foldable Zipper where
    foldMap f (Zipper ls a rs) =
        getDual (foldMap (Dual . f) ls) <> f a <> foldMap f rs


left :: Zipper a -> Zipper a
left (Zipper (l:ls) a rs) = Zipper ls l (a:rs)

right :: Zipper a -> Zipper a
right (Zipper ls a (r:rs)) = Zipper (a:ls) r rs

zipper :: [a] -> Zipper a
zipper (x:xs) = Zipper [] x xs

-- but these are not total functions!
-- we can fix that with Maybe (aka Option in ocaml)


left' :: Zipper a -> Maybe (Zipper a)
left' (Zipper (l:ls) a rs) = Just $ Zipper ls l (a:rs)
left' _ = Nothing

right' :: Zipper a -> Maybe (Zipper a)
right' (Zipper ls a (r:rs)) = Just $ Zipper (a:ls) r rs
right' _ = Nothing

zipper' :: [a] -> Maybe (Zipper a)
zipper' (x:xs) = Just $ Zipper [] x xs
zipper' [] = Nothing


-- now it's safe to compose these!
right3 = right' >=> right' >=> right'

left3 = left' >=> left' >=> left'


-- this is just regular monad business:

right3' :: Zipper a -> Maybe (Zipper a)
right3' zip = do
    zip'   <- right' zip   -- let%bind zip' = right' zip in
    zip''  <- right' zip'
    zip''' <- right' zip''
    return zip'''


left3' :: Zipper a -> Maybe (Zipper a)
left3' zip = do
    zip'  <- left' zip
    zip'' <- left' zip'
    left' zip''


addFirstAndThird z = do
    z''' <- right3' z
    return (extract z + extract z''')


sumNeighbors z =
    here z
    + maybe 0 here (left' z)
    + maybe 0 here (right' z)


integers = Zipper [-1, -2..] 0 [1, 2..]



instance Comonad Zipper where
    extract = here
    duplicate z = Zipper lls z rrs where
        pair x = (x, x)
        lls = unfoldr (fmap pair . left') z
        rrs = unfoldr (fmap pair . right') z 


integers' = (integers =>> sumNeighbors)

integers'' = fmap show integers'





promptName :: IO String
promptName = do
    putStr "Enter your name: "
    name <- getLine
    putStrLn $ "Hello, " ++ name
    return name

promptName' = 
    putStr "Enter your name: " >>
    getLine >>= \name ->
    putStrLn ("Hello, " ++ name) >>
    return name

promptName'' = 
    putStr "Enter your name: " >>= \_ ->
    getLine >>= \name ->
    putStrLn ("Hello, " ++ name) >>= \_ ->
    return name


composedStuff = do
    name <- promptName
    putStr "Your name has "
    print (length name)
    putStr " letters."



stateful n = do
    s <- get
    put (n : s)
    when (n > 0) do
        stateful (n - 1)


statefulIO = do
    lift $ putStr "Enter value for n: "
    n <- read <$> lift getLine
    stateful n
    s <- get
    lift $ putStrLn ("Result state: " ++ show s)
    return (sum s)
    

runStateful n =
    execState (stateful n) []

runStatefulIO =
    evalStateT statefulIO []



data MyError
    = InputTooBig
    | NetworkingError
    | InputNotPrime
    deriving (Eq, Show)


errorIO :: ExceptT MyError IO Integer
errorIO = do
    liftIO $ putStr "Enter a small prime: "
    n <- read <$> liftIO getLine
    
    liftIO $ putStrLn "This could fail... "
    
    when (n > 100) $ throwError InputTooBig
    when (not $ isPrime n) do
        liftIO $ putStrLn "Number was not prime!"
        throwError InputNotPrime
    
    liftIO $ putStrLn "Integer approved."
    return n





main' :: IO ()
main' = do
    n <- runExceptT errorIO

    case n of
        Right n -> do
            print $ "Success: " ++ show n
            main'

        Left err -> do
            putStrLn "Encountered error: "
            print err

