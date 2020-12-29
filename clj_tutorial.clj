(ns clojure-tutorial
  (:require [clojure.spec.alpha :as s]
            [clojure.spec.test.alpha :as stest]))

;;;;;;;;;; Fun facts ;;;;;;;;;;

; Clojure was invented in 2007 by Rich Hickley
; - Worked on it for 2.5 years
; - Almost 50 years since the first Lisps were created
; 
; A dialect of Lisp, which is a language family, not a single PL
; - Other dialects include Common Lisp and Scheme
; - Characterized by prefix notation and a s**t-ton of parentheses
; 
; Clojure compiles to the JVM (Java Virtual Machine)
; - Similar to Java (duh), Kotlin, and Scala
; - Can perform Java interop in Clojure
; - There's also ClojureScript, which is Clojure built on JavaScript
; 
; How to use Clojure on Visual Studio Code
; 1. Install Java
; 2. Install Clojure
; 3. Install Calva extension (this is what we're using)
; 
; Clojure is generally developed on the REPL
; - REPL = Read Eval Print Loop
; - Literally a toploop
; - In the terminal, activated using the `clojure` or `clj` commands
; - In VSCode, connect to an nREPL server, then use ctrl-Enter to eval

;;;;;;;;;; The basics (incl. functions) ;;;;;;;;;;

; Simple computation: two plus two
; - `+` is technically a function (think Int.(+) from OCaml)
; - Arguments are separated by spaces, just like in OCaml
(+ 2 2)

; Slightly more complex computation
; Notice the type coercion
(* 3 4 5 (+ 4 5 (/ 8.0 3.0)))

; Defining a variable
(def x 2)
x

; Defining a function
(defn add-two [x y] (+ x y))
(add-two 3 4)

; Function with comments!
(defn mult-two
  "This function multiplies two numbers"
  [a b]
  (* a b))
(mult-two 100 200)

; Multi-arity functions
(defn mult-two-or-three
  ([a b] (* a b))
  ([a b c] (* a b c)))

(mult-two-or-three 2 2)
(mult-two-or-three 2 2 2)

; Partial functions with the `partial` function
; (writing (add-two 100) w/o partial causes a syntax error)
(def add-one (partial add-two 100))
(add-one 1)

; Anonymous functions
((fn [x] (+ x 1)) 2)
(#(+ % 1) 2)

; Under the hood, `defn` is a _macro_ that combines `def` with `fn`
; The macro is desugared after Clojure code is parsed, right before compilation
; to Java bytecode 
; (Note the single quote - need to prevent (defn add1 ...)
; from being evaluated)
(macroexpand '(defn add1 [x] (+ x 1)))

; Note: Macros are easy to use in Clojure because it is a "homoiconic" language,
; i.e. the code itself is made completely out of data structures
; Hence the mantra "code is data"

; Let-binding
(defn add-three
  [x y z]
  (let [yz (+ y z)] (+ x yz)))
(add-three 1 2 3)

; If statements (feat. nils)
; (`nil` can be thought of as OCaml "None" or "unit" or Java "null")
; (also note that predicate fns are conventionally suffixed with "?")
(defn add-if-int
  [x y]
  (if (or (nil? x) (nil? y))
    nil
    (+ x y)))

(add-if-int nil nil)
(add-if-int 200 nil)
(add-if-int nil 300)
(add-if-int 200 300)

; Putting it all together
(defn fib
  "The naive implementation of the Fibonacci function"
  [n]
  (if (or (= n 0) (= n 1))
    n
    (let [a1 (- n 1)
          a2 (- n 2)]
      (+ (fib a1) (fib a2)))))
(fib 0)
(fib 1)
(fib 10)

; Fun fact: `or` and `and` are also macros
(macroexpand '(or (= n 0) (= n 1)))
(macroexpand '(and (= n 0) (= n 1)))

; Threading macros (for pipelining)
; `->` applies value as FIRST argument of each fn
; `->>` applies value as LAST argument of each fn
(defn sub-two [x y] (- x y))
(defn div-two [x y] (/ x y))
(-> 0 (sub-two 20) (div-two 2))
(->> 0 (sub-two 20) (div-two 2))

; And yes, these are indeed macros
(macroexpand '(-> 0 (sub-two 20) (div-two 2)))
(macroexpand '(->> 0 (sub-two 20) (div-two 2)))

;;;;;;;;;; Data structures ;;;;;;;;;;

; List (note the single quote)
'(1 2 3 4 5)

; Vector
[1 2 3 4 5]

; Vector (alternate syntax)
; (Note: "vector" is a varadic function)
(vector 1 2 3)

; The different between lists and vectors:
; - Lists add elements to the _beginning_, vectors to the _end_
; - Lists retrieve n-th element in O(n) time, vectors (almost) in O(1) time

; Unlike OCaml lists, Clojure sequences can have elements of different types
'("this" 13 :fine)
[3.0 :is "this"]

; Sets
#{1 2 3 4 5}

; Maps
; The `:x` and `:y` here are _keywords_, a special Clojure data type
{:x 1 :y 2}

; Consing and conj-ing
; (note that `cons` returns a list)
(cons 1 '(2 3 4))
(cons 1 [2 3 4])

(conj '(2 3 4) 5)
(conj [2 3 4] 5)
(conj #{2 3 4} 5)
(conj #{2 3 4} 4)

; `conj` can take any number of arguments
(conj [2 3 4] 5 6 7)

; Removing items from set
(disj #{2 3 4} 2 3)

; Looking up a set
(#{1 2} 2)
(#{1 2} 3)

; Looking up a map
(def avatars {"Kyoshi" :earth "Roku" :fire "Aang" :air "Korra" :water})
(avatars "Korra")
(avatars "Katara")
(get avatars "Aang")
(get avatars "Sokka" :nonbender)

; Return key-value pair
(find avatars "Roku")

; Check if map contains key
(contains? avatars "Kyoshi")

; Add and remove key-value pairs
(assoc avatars "Kuruk" :water)
(dissoc avatars "Korra")

; Merging maps
(merge {:foo 1 :bar 2} {:bar 3 :baz 4})

; Map (note the use of higher-order functions)
(map (fn [x] (+ x 1)) [1 2 3 4 5])
(map (fn [x] (+ x 1)) #{1 2 3 4 5})

; Fold (aka. `reduce`)
(reduce (fn [accum x] (+ accum x)) [1 2 3 4 5])
(reduce (fn [accum x] (+ accum x)) #{1 2 3 4 5})

; Filter
(filter (fn [x] (> x 2)) [1 2 3 4 5])
(filter (fn [x] (> x 2)) #{1 2 3 4 5})

;;;;;;;;;; Spec ;;;;;;;;;;

; Clojure is _dynamically_ typed
; - Unlike OCaml or Haskell, but like Python or JavaScript
; - No type annotations, type system, or compile-time type checking
; - Makes code much more flexible
; - But what if we **do** want to verify data?
; 
; Introducing: Clojure spec
; - A form of runtime data validation
; - NOT a type system
; - Rather similar to Scheme contracts

; Define the following spec: non-empty string
; - double-colon denotes a "fully-qualified keyword"
;   i.e. ::string is actually :clojure-tutorial/string)
; - seq is "falsy" if passed an empty string
(s/def ::string (s/and string? seq))

; We can check if a value "conforms" to the spec
(s/conform ::string "foo")
(s/conform ::string "")
(s/conform ::string 2)

; Another spec: is the keyword or string an ISO-639 language code?
(def lang-tags #{"en" "es" "fr" "zh"})

(s/def ::language-tag
  (fn [t] (or (and (keyword? t) (->> t name (contains? lang-tags)))
              (and (string? t) (seq t) (contains? lang-tags t)))))

; Final spec: is the data a valid language map?
(s/def ::language-map
       (s/map-of ::language-tag ::string :min-count 1))

; We can print an error message to stdout
(s/explain ::language-map {:en "Hello World!" "zh" "你好世界"})
(s/explain ::language-map {:kr "안년하세요!"})
(s/explain ::language-map {:es ""})

; We can also return error info as a value
(s/explain-data ::language-map {:en "Hello World!" "zh" "你好世界"})
(s/explain-data ::language-map {:kr "안년하세요!"})
(s/explain-data ::language-map {})

; A more complex spec: validate your Assignment 4 output

; Check if string is sanitized by matching it to a regular expression
(s/def ::sanitized-string
       (s/and string? #(re-matches #"[a-zA-Z0-9]+" %)))

; Check if ngram is a collection of sanitized strings (e.g. a vector)
; with n > 0 and all strings being distinct
(s/def ::ngram (s/coll-of ::sanitized-string :min-count 1 :distinct true))

; The frequency has to be an integer
(s/def ::frequency integer?)

; Validate the { "ngram" : [...], "frequency" : ### } association
; `req-un` means that the keys ngrams and frequency are required, and their
; values should conform to their respective specs
; We also don't care about the specs' namespaces
; (otherwise we'd be checking for ::clojure-tutorial/ngram, for example)
(s/def ::frequency-assoc
       (s/keys :req-un [::ngram ::frequency]))

; The output needs to be a collection of the above associations
(s/def ::frequency-list
       (s/coll-of ::frequency-assoc :max-count 10))

(s/explain ::frequency-list
           [{ :ngram ["array" "of" "the"] :frequency 1092}
            { :ngram ["of" "the" "strings"] :frequency 1091 }])

(s/explain ::frequency-list
           [{ :ngram ["foo!!!"] :frequency 129 }])

(s/explain ::frequency-list
           [{ :ngram [] :frequency 1000 }])

; This isn't the most comprehensive spec possible
; - Doesn't check if frequencies are sorted
; - Doesn't check that ngrams all have the same length
; Creating a fuller spec can become quite complex!

; We can even use spec to enforce function pre- and post-conditions
; (remember Assignment 3?)

; Example taken from the offical Clojure website

(defn ranged-rand
  "Returns random int in range start <= rand < end"
  [start end]
  (+ start (long (rand (- end start)))))

; Check that
; - Both arguments are ints, and that start < end
; - The return value is an int and that start <= ret < end
(s/fdef ranged-rand
  :args (s/and (s/cat :start int? :end int?)
               #(< (:start %) (:end %)))
  :ret int?
  :fn (s/and #(>= (:ret %) (-> % :args :start))
             #(< (:ret %) (-> % :args :end))))

; Once we spec-ed the function, we can test it
; Think back to quickcheck
; (Note: the backtick is similar to single quote in preventing evaluation,
; but is fully-qualified, i.e. it expands to clojure-tutorial/ranged-rand)
(stest/check `ranged-rand)

; We can also exercise the function
(s/exercise-fn `ranged-rand)

; Note: You need to include test.check as a dependency if you want to use
; stest and s/exercise-fn

; What if the function fails our assertions?
(defn bad-ranged-rand
  "This version of ranged-rand returns one less than the correct result"
  [start end]
  (- (+ start (long (rand (- end start)))) 1))

(s/fdef bad-ranged-rand
  :args (s/and (s/cat :start int? :end int?)
               #(< (:start %) (:end %)))
  :ret int?
  :fn (s/and #(>= (:ret %) (-> % :args :start))
             #(< (:ret %) (-> % :args :end))))

(-> `bad-ranged-rand stest/check first stest/abbrev-result)