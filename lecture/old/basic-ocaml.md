
## Basic OCaml Programming

* To start with we will use the top loop as a simple calculator.
* Top loop is also called a "read-eval-print" loop - write and run small code snippets. 
* Invented for Lisp; found in JavaScript, Python, Scheme, Ruby, OCaml, Perl, etc

#### Simple integer operations in the top loop

```ocaml
3;; (* use ;; to end input. *)
3 + 4;; (* notice how types are inferred in output *)
let x = 3 + 4;; (* give the value a name via let keyword. *)
x + 5;;
let y = 5 in x + y;; (* this makes y a local variable: think C's { int y; return(x+y); }  *)
(* y + 6 ;; *) (* errors because y was only defined *locally* in previous line *)
```

#### Boolean operations

```ocaml
true && false;;
true || false;;
1 = 2;; (* = not == for equality comparison *)
1 <> 2;;  (* <> not != for not equal *)
```

`int` and `float` cannot be mixed without being explicit - a wonky OCaml-ism
```ocaml
1;;
1.;;
4 * 5;;
4.0 * 1.5;; (* errors -- '*' operator is only for integers *)
4.0 *. 1.5;;      (* works -- '*.' is for floats *)
(float 4) *. 1.5;; (* use an explicit cast when you want to mix *)
```

### Lists

Lists are pervasive in OCaml; easy to create and manipulate

```ocaml
[1; 2; 3];;
[1; 1+1; 1+1+1];;
["a"; "b"; "c"];;
[1; "a"];; (* errors - All elements must have same type - HOMOGENEOUS *)
[];; (* empty list *)
```

#### Operations on lists.  

Lists are represented internally as BINARY TREES with left child a leaf.
```ocaml
0 :: [1; 2; 3];; (* "::" is 'consing' an element to the front - fast *)
0 :: (1 :: (2 :: (3 :: [])));; (* equivalent to the above *)
[1; 2; 3] @ [4; 5];; (* appending lists - slower *)
let z = [2; 4; 6];;
let y = 0 :: z;;
z;; (* Observe z itself did not change -- lists are immutable in OCaml *)
```

Everything in OCaml returns values (i.e. is an 'expression') - no commands
```ocaml
if (x = 3) then (5 + 35) else 6;; (* ((x==3)?5:6)+1 in C *)
(if (x = 3) then 5 else 6) * 2;;
(if (x = 3) then 5.4 else 6) * 2;; (* type errors:  two branches of if must have same type *)
```

## Basic Ocaml II

Tuples - fixed length lists, but types of each element CAN differ, unlike lists *)

```ocaml
(2, "hi");;        (* type is int * string -- '*' is like "x" of set theory, a product *)
let tuple = (2, "hi");;
(1,1.1,'c',"cc");;
```

#### Defining and using functions

To declare a function `squared` with `x` its one parameter.  `return` is  implicit.
```ocaml
let squared x = x * x;; 
squared 4;; (* to call a function -- separate arguments with S P A C E S *)
```
 *  OCaml has no return statement; value of the whole body-expression is what gets returned
 *  type is printed as domain -> range
 *  "officially", OCaml functions take only one argument - !  multiple arguments can be encoded by some tricks (later)

Fibonacci series - `0 1 1 2 3 5 8 13 ...` 

```ocaml
let rec fib n =     (* the "rec" keyword needs to be added to allow recursion (ugh) *)
  if n <= 0 then 0
  else if n = 1 then 1
  else
    fib (n - 1) + fib (n - 2);; (* notice again everything is an expression, no "return" *)

fib 10;;
```

#### Anonymous functions

* Lets users define a function as an expression
* Similar to lambdas in Python, Java, C++, etc - all are based on the lambda calculus *)

```ocaml
let add1 x = x + 1;; (* normal add1 definition *)
let funny_add1 = (function x -> x + 1);; (* "x" is (sole) argument here *)
funny_add1 3;;
(funny_add1 4) + 7;; 
((function x -> x + 1) 4) + 7;; (*  a "->" function is an expression and can be used anywhere *)
((fun x -> x + 1) 4) + 7;; (*  shorthand notation -- cut off the "ction" *)
```

Multiple arguments - just leave spaces between multiple arguments in definition and use

```ocaml
let add x y = x + y;;
add 3 4;;
(add 3) 4;; (* same meaning as previous application -- two applications, " " associates LEFT *)
let add3 = add 3;; (* No need to give all arguments at once!  Type of add is int -> (int -> int) - "CURRIED" *)
add3 4;;
add3 20;;
```

Conclusion: add is a function taking an integer, and returning a **function** which takes ints to ints.
So, add is a **higher-order function**: it either takes a function as an argument, or returns a function as result.

Observe `int -> int -> int` is parenthesized as `int -> (int -> int)` -- unusual **right** associativity


Be careful on operator precedence with this goofy way that function application doesn't need parens!
```ocaml
add3 (3 * 2);;
add3 3 * 2;; (* NOT the previous - this is the same as (add3 3) * 2 - application binds tighter than * *)
add3 @@ 3 * 2;; (* LIKE the original - @@ is like the " " for application but binds LOOSER than other ops *)
```

### Pattern matching

 * Switch or case on steroids
 * A very cool and useful but not so common language feature
 * Haskell and Scala also have it, JavaScript and Python should be getting it 

Basic pattern match with numbers, looks like switch more or less:

```ocaml
let mixemup n =
    match n with
    | 0 -> 4
    | 5 -> 0
    | y -> y + 1;; (* default case giving a name to the matched number, x *)

mixemup 3;; (* matches last case and x is bound to the value 3 *)
```

```ocaml
let five_oh y =
"Hawaii " ^ (match y with
    | 0 -> "Zero"
    | 5 -> "Five"  (* notice the "|" separator between multiple patterns *)
    | _ -> "Nothing") ^ "-O";; (* default case -- _ is a pattern matching anything *)

five_oh 5;;
```

List pattern matching - we can finally take apart lists!

```ocaml
match ['h';'o'] with      (* recall ['h';'o'] is really 'h' :: ('o' :: []) *)
      | x :: y -> "first clause"
      | _ -> "second clause";;

match [] with
      | x :: y -> "first clause"
      | _ -> "second clause";;

match ['h';'o';'p';' ';'h';'o';'p'] with
      | x :: y -> y
      | _ -> ['0'];;

match ["hi"] with (* ["hi"] is "hi" :: [] *)
      | x :: (y :: z) -> "first"
      | x :: y -> "second"
      | _ -> "third";;

let mm l = match l with
      | [] -> "empty"
      | x :: y -> "non-empty";;
```

Tuple pattern matching
```ocaml
let tuple = (2, "hi", 1.2);;

match tuple with
  (f, s, th) -> s
;;
```

Let pattern shorthand: a single pattern match to assign multiple values

```ocaml
let mypair = (2.2, 3.3);;
let (f, s) = mypair in f +. s;;
match mypair with (f,s) -> f +. s;; (* same behavior as above let *)
```

```ocaml
let getSecond t =
  match t with
    (f, s) -> s
;;
let s = getSecond (2, "hi");;
let s = getSecond mypair;;

let getSec t =
  match t with
    (f, s) -> (s :: [],4)
;;
```

Warning - non-exhaustive pattern matching; avoid this

```ocaml
let getHead l =
  match l with
    head :: tail -> head;;

getHead [];;  (* OCaml gives uncaught runtime exception *)
```

An error-free version

```ocaml
let getHead l =
  match l with
    | [] -> failwith "you dodo"
  |  head :: tail -> head
;;
```

Using patterns in recursive functions: a function to reverse a list
 * Note this does not mutate the list, it makes a new list
 * We also want to study this function to show how its correctness is justified by an induction argument

```ocaml
let rec rev l =
  match l with
  |  [] -> []
  | x :: xs -> rev xs @ [x]
;;
rev [1;2;3];; (* = 1 :: ( 2 :: ( 3 :: [])) *)
```

Let us argue why this works.  First, for this particular list.

We assume we have a notion of "program fragments behaving the same", `~=`.
 -  e.g. `1 + 2 ~= 3`, `1 :: [] ~= [1]`, etc.  
 -  (`~=` is called "operational equivalence", we will define it later in the course)

Lemma. `rev [1;2;3] ~= [3;2;1]`.
Proof.
`rev [1;2;3]` pattern matches with `x ~= 1`, `xs ~= [2;3]`; so the result is `rev [2;3] @ [1]`.  
Thus, `rev [1;2;3] ~= rev [2;3] @ [1]`.
So let us now figure out what `rev [2;3]` is:
`rev [2;3]` pattern matches with `x ~= 2, xs ~= [3]`; so the result is `rev [3] @ [2]`.
Thus, `rev [2;3] ~= rev [3] @ [2]`.
So let us now figure out what `rev [3]` is:
`rev [3]` pattern matches with `x ~= 3`, `xs ~= []` (yes, empty list!); so the result is `rev [] @ [3]`.
Thus, `rev [3] ~= rev [] @ [3]`.
Lastly, `rev [] ~= []` directly from the match.

Given all the above, we can use the usual principle of replacing `~=` with `~=` to get:
```ocaml
rev [1;2;3] 
~= rev [2;3] @ [1]  
~= (rev [3] @ [2]) @ [1] 
~= ((rev [] @ [3]) @ [2]) @ [1]
~= (([] @ [3]) @ [2]) @ [1]
~= [3;2;1]
``` 
by computing out the `@`.

So by transitivity on the above, 

`rev [1;2;3] ~= [3;2;1]`.  QED.

But, what we really want to show is it reverses ANY list.. use induction!

Let P(n) mean "for any list l of length n, `rev l ~=` its reverse".

Recall an induction principle:
To show P(n) for all in, it suffices to show 
  1) P(0), and 
  2) P(k) holds implies P(k+1) holds for any natural number k.

Recal WHY induction is justified:

If we showed 1) and 2) above, 
- P(0) is true by 1)
- P(1) is true because letting k=0 in 2) we have P(0) implies P(1),
    and we just showed we have P(0), so we also have P(1).
- P(2) is true because letting k=1 in 2) we have P(1) implies P(2),
    and we just showed we have P(1), so we also have P(2).
- P(3) is true because letting k=2 in 2) we have P(2) implies P(3),
    and we just showed we have P(2), so we also have P(3).
- ... hopefully you get the pattern here.

In the concrete proof above for `[1;2;3]` we basically unwound the induction backwards.

Let us now prove by induction.

Theorem: For any list `l` of length n, `rev l ~=` the reverse of `l` .
Proof.  Proceed by induction to show this property for any n.
  1) for n = 0, `l ~= []` since that is the only 0-length list.
     `rev [] ~= []` which is `[]` reversed, check!
  2) Assume for any k-length list `l` that `rev l ~= l` reversed.
     Show for any k+1 length list, i.e. for any list `x :: l`
     that `rev (x :: l) ~= (x :: l)` reversed:

OK, by computing, `rev (x :: l) ~= rev l @ [x]`.
Now by the induction hypothesis, `rev l` is `l` reversed.
So, since `(l` reversed`) @ [x]` reverses the whole list `x :: l`,
`rev (x :: l) ~= (x :: l)` reversed.
This completes the induction step.

QED.    

Bonus round: here is a concrete forward-view building up the argument more like the induction.
 * `l ~= [] : rev [] ~= []`, check!
 * `l ~= [3] : rev [3] ~= rev (3 :: []) ~= (rev []) @ [3] ~= (using previous line) [3]`
 * `l ~= [2;3] : rev [2;3] ~= rev (2 :: [3]) ~= (rev [3]) @ [2] ~= (by previous) [3;2]`
 * `l ~= [1;2;3] : rev [1;2;3] ~= rev (1 :: [2;3]) ~= (rev [2;3]) @ [1] ~= (by previous) [3;2;1]`

```ocaml
rev [1;2;3];;
(rev [2;3]) @ [1];;
((rev [3]) @ [2]) @ [1];;
(((rev []) @ [3]) @ [2]) @ [1];;
(([]@[3]) @ [2]) @ [1];;
```

###  OCaml Lecture III

* We are going to cover variant types in detail later but here are a few simple examples 
* Variant types are like unions in C, and generalize enums of Java. Unlike types up to now you need to **declare** them via keyword "type".

```ocaml
type comparison = LessThan | EqualTo | GreaterThan;;

let intcmp x y =
	if x < y then LessThan else
		if x > y then GreaterThan else EqualTo;;
```

Of course we will pattern match to take the data apart:

```ocaml
match intcmp 4 5 with
  | LessThan -> "less!"
  | EqualTo -> "equal!"
  | GreaterThan -> "greater!";;
```

Variants can also wrap arguments: they are more like C unions than Java enums

```ocaml
type 'a nullable = Null | NotNull of 'a;;

match NotNull(4) with
  | Null -> "null!"
  | NotNull(n) -> (string_of_int n)^" is not null!"
;;
```

Built-in version of this for functions with optional result:

```ocaml
type 'a option = None | Some of 'a *)

Some(4);;
None;;
```

Here is a use of it:

```ocaml
let gethead l = match l with
  | [] -> None
  | hd :: tl -> Some hd;;
```

Subtle property of immutable declarations
 * All variable declarations in OCaml are **immutable** -- value will never change
 * helps in reasoning about programs, we know the variable's value is fixed

```ocaml
(let y = 3 in
  ( let x = 5 in
    ( let f z = x + z in
      ( let x = y in  (* this is a re-definition of x, NOT an assignment *)
        (f (y - 1)) + x
            )
        )
    )(* x is STILL 5 in the function body - thats what x was when f defined *)
)
;;
```

This is in the spirit of this C pseudo-code:
```c
 { int y = 3;
   { int x = 5;
     { int (int) f = z -> return(x + z); (* imagining higher-order functions in C *)
       { int x = y; (* shadows previous x in C *)
         return(f(y-1) + x); 
  }}}})
```

The top loop is conceptually an open-ended series of let-ins which never close:
```ocaml
let y = 3;;
let x = 5;;
let f z = x + z;;
let x = y;; (* as in previous example, this is a nested definition, not assignment! *)
f (y-1) + x;;
```
Function definitions are similar, you can't mutate an existing definition.

```ocaml
let f x = x + 1;;
let g x = f (f x);;
let shad = f;; (* make a new name for f above *)
(* lets "change" f, say we made an error in its definition above *)
let f x = if x <= 0 then 0 else x + 1;;
g (-5);; (* g still refers to the initial f - !! *)

assert( g (-5) = 0);; (* example of built-in assert in action - returns () if holds, exception if not *)

let g x = f (f x);; (* FIX to get new f: resubmit (identical) g code *)

assert(g (-5) = 0);; (* now it works as we initially expected *)
```

**Moral**: When interactively editing a group of functions that call each other, re-submit ALL the functions to the top loop when you change any *one* of them.  Otherwise you can have some functions using a now-shadowed version. **Or**, just submit your whole file of functions: `#use "myfile.ml";;`

#### Mutually recursive functions

Warm up to the next function - write a (useless) copy function on lists

```ocaml
let rec copy l =
  match l with
  | [] -> []
  | hd :: tl ->  hd::(copy tl);;

let result = copy [1;2;3;4;5;6;7;8;9;10]
```

List copy is in fact useless because lists are immutable - can share instead

Refine copy to flip back and forth between copying and not

```ocaml
let rec copyodd l = match l with
  | [] -> []
  | hd :: tl ->  hd::(copyeven tl)
and  (* new keyword for declaring mutually recursive functions *)
  copyeven l = match l with
  |  [] -> []
  | x :: xs -> copyodd xs;;

copyodd [1;2;3;4;5;6;7;8;9;10];;
copyeven [1;2;3;4;5;6;7;8;9;10];;
```

### Using `let .. in` to define local functions

Here is a version that hides the `copyeven` function -- make both internal and export one

```ocaml
let copyodd ll =
    ( let rec
     copyoddlocal l = match l with
      |  [] -> []
      | hd :: tl ->  hd::(copyevenlocal tl)
    and
     copyevenlocal l = match l with
    |        [] -> []
    | x :: xs -> copyoddlocal xs
  in
   copyoddlocal ll
    );;

assert(copyodd [1;2;3;4;5;6;7;8;9;10] = [1;3;5;7;9]);;
```

### Higher Order Functions

Higher order functions are functions that either
 * take other functions as arguments
 * or return functions as results
 * or both of the above

Why?
 * "pluggable" programming by passing in and out chunks of code
 * greatly increases reusability of code since any varying code can be pulled out as a function to pass in

Lets show the power by extracting out some pluggable code

Example: multiply each element of a list by ten

```ocaml
let rec timestenlist l =
  match l with
    []    -> []
  | hd::tl -> (hd * 10) :: timestenlist tl;;

timestenlist [3;2;50];;
```

Example: append gobble to a list of words

```ocaml
let rec appendgobblelist l =
  match l with
    []    -> []
  | hd::tl -> (hd ^"gobble") :: appendgobblelist tl;;

appendgobblelist ["have";"a";"good";"day"];;
("have" ^"gobble") :: ("a"^"gobble") :: appendgobblelist ["good";"day"];;
```

Notice there is a common pattern of "do an operation on each list element".  So lets pull out the "times ten" / "add gobble" as a function parameter! This is in fact a classic example, the map function

```ocaml
let rec map f l =  (* Notice function f is an ARGUMENT here *)
  match l with
    []    -> []
  | hd::tl -> (f hd) :: map f tl;;

map (fun x -> x * 10) [3;2;50];;
```

Note there is a built-in `List.map` since it is so common:

```ocaml
let middle = List.map (function s -> s^"gobble");;
middle ["have";"a";"good";"day"];;
```

Mapping on lists of pairs - shows in and out lists can be different types.
```ocaml
map (fun (x,y) -> x + y) [(1,2);(3,4)];;
let flist = map (fun x -> (fun y -> x + y)) [1;2;4] ;; (* make a list of functions - why not? *)
```

What can you do with a list of functions?  e.g. compose them

```ocaml
(* compose_list [f1;..;fn] v = f1 (... (fn v) ... ) *)
let rec compose_list lf v =
  match lf with
  | [] -> v
  | hd :: tl -> hd(compose_list tl v);;

compose_list flist 0;;
```

### Folds

 * fold_left/right are classic operators on lists 
 * combines a vector of data like the reduce of map/reduce

```ocaml
let rec fold_left f v l = match l with
    | []   -> v
    | hd::tl -> fold_left f (f v hd) tl (* pass down f v hd as new "v" -- accumulating *)
    ;;
```

Summing elements of a list can now be succinctly coded:
```ocaml
fold_left (fun elt -> fun accum -> elt + accum) 0 [1;2;3];; (* = (((0+1)+2)+3) - 0 on LEFT *)
fold_left (+) 0 [1;2;3];; (* equivalent to previous - built-in operator in parens is function *)
```

Compare to manual summate - pulled out the combining operator and zero

```ocaml
let rec summate accum l = match l with
    | []   -> accum
    | hd::tl -> summate (accum + hd) tl (* pass down f v hd as new "v" -- accumulating *)
    ;;
summate 0 [1;2;3];;
```

More examples.  Note this is `List.fold_left` in OCaml library

```ocaml
let length l = List.fold_left (fun accum elt -> accum + 1) 0 l;; (* adds accum, ignores elt *)
let rev l = List.fold_left (fun accum elt -> elt::accum) [] l;; (* e.g. rev [1;2;3] = (3::(2::(1::[]))) *)
```
* Right fold is similar but f is applied "on the way out" of recursion, not "on the way down" like in left fold above.
* also in List.fold_right.
* Args are swapped compared to fold_left, be careful !

```ocaml
let rec fold_right f l v = match l with
  | [] -> v
  | hd::tl -> f hd (fold_right f tl v) (* v not changing on recursion here *)
;;
fold_right (+) [1;2;3] 0;; (* = (1+(2+(3+0))) - 0 on right *)
```

Example where left and right folds produce different result:
```ocaml
fold_left (fun elt -> fun accum -> "("^elt^"+"^accum^")") "0" ["1";"2";"3"] ;; 
fold_right (fun accum -> fun elt -> "("^accum^"+"^elt^")") ["1";"2";"3"] "0" ;; 
```

`map` is a simple right fold - the fold does the recursion work.
```ocaml
let map f l = List.fold_right (fun elt accum -> (f elt)::accum) l [];;
```

Another example of left vs right - left's accumulating maps and reverses
```ocaml
let map_and_rev f l = List.fold_left (fun accum elt -> (f elt)::accum) [] l ;; (* notice how this reverses *)
```

More operations
```ocaml
let filter f l = List.fold_right (fun elt accum -> if f elt then elt::accum else accum) l [];; 
let rev_slow l = List.fold_right (fun elt accum -> accum @ [elt]) l [];; (* can also fold_right rev with @ *)
```

Composition function g o f: take two functions, return their composition
```ocaml
let compose g f = (fun x -> g (f x));;

let plus3 x = x+3;;
let times2 x = x*2;;
let times2plus3 = compose plus3 times2;;
times2plus3 10;;
(* equivalent but with anonymous functions: *)
compose (fun x -> x+3) (fun x -> x*2) 10;;
```

Equivalent notations for compose

```ocaml
let compose g f x =  g (f x);;
let compose = (fun g -> (fun f -> (fun x -> g(f x))));;
```

### Parametric polymorphism
 * A key feature of inferred types

```ocaml
let id = fun x -> x;;
let id x = x;; (* equivalent to above *)
id 3;; (* id applied to int returns an int *)
id true;; (* SAME id applied to bool returns a bool *)
```

Conclusion: the type of id, `'a -> 'a` is **parametric**, i.e. the return type is parameterized by the type of the argument.  Same as Java's generics.

We saw several parametric functions above:

```ocaml
copyodd;;    (* type is 'a list -> 'a list *)
map;;     (* type is ('a -> 'b) -> 'a list -> 'b list *)
compose;; (* type is ('a -> 'b) -> ('c -> 'a) -> 'c -> 'b *)
```

## Self-study topic: only 'let'-defined functions are polymorphic

Background: turning a let-defined function into an argument to a function

```ocaml
let add1 = fun x -> x + 1;;
add1 4;;
```

Equivalent way to do the above: define add1 as an anonymous function and pass in

```ocaml
(function addup -> addup 4)(fun x -> x + 1);;
```

Lets try to do the same refactoring for a polymorphic function

```ocaml
let id = function x -> x;;

match id (true) with
    true -> id (3)
  | false -> id(4);;
```

The below will error - variable mono_id is not defined by let so it can't be polymorphic

```ocaml
(function mono_id ->
    match mono_id(true) with
                true -> mono_id(3)
              | false -> mono_id(4)) (fun x -> x);;
```

If only used at one type its OK:

```ocaml
(function mono_id -> mono_id 4) id;; (* mono_id is solely of type int -> int, thats OK *)
```
### Currying

* One topic left in higher-order functions.
* Currying - idea due to logician Haskell Curry

First lets recall how functions allow incremental arguments to be passed

```ocaml
let addC x y = x + y;;
addC 1 2;; (* recall this is the same as '(addC 1) 2' *)
let tmp = addC 1 in tmp 2;; (* the partial application of arguments - result is a function *)
```

An equivalent way to define addC, clarifying what the above means:

```ocaml
let addC = fun x -> (fun y -> x + y);;
(* yet another identical way .. *)
let addC x = fun y -> x + y;;

(addC 1) 2;; (* same result as above *)
```

Its also the type of the built-in + -- put parens around to see as a fun

```ocaml
let addCagain = (+);;
(addCagain 1) 2;; (* same result as above *)
```

Here is the so-called non-Curried version: use a pair of arguments instead
```ocaml
let addNC p =
    match p with (x,y) -> x+y;;
```

Here is an equivalent abbreviation which looks like a standard C function
```ocaml
let addNC (x, y) = x + y;;
```


Notice how the type of the above differs from addC's type
```ocaml
addNC (3, 4);;
addNC 3;; (* will error, need all or no arguments supplied *)
```
Fact: these two approaches to a 2-argument function are isomorphic:

`'a * 'b -> 'c` === `'a -> 'b -> 'c`

We now define two cool higher-order functions:
* `curry`   - takes in non-curry'ing 2-arg function and returns a curry'ing version
* `uncurry` - takes in curry'ing 2-arg function and returns an non-curry'ing version

Since we can then go back and forth between the two reps, they are **ISOMORPHIC**

```ocaml
let curry fNC = fun x -> fun y -> fNC (x, y);;
let uncurry fC = fun (x, y) -> fC x y;;

let newaddNC = uncurry addC;;
newaddNC (2,3);;
let newaddC  = curry   addNC;;
newaddC 2 3;;
```

Observe the types themselves pretty much specify the behavior
```ocaml
curry : ('a * 'b -> 'c) -> 'a -> 'b -> 'c
uncurry : ('a -> 'b -> 'c) -> 'a * 'b -> 'c
```

```ocaml
let noop1 = curry (uncurry addC);; (* a no-op *)
let noop2 = uncurry (curry addNC);; (* another no-op; noop1 & noop2 together show isomorphism *)
```
### Misc OCaml

See [Pervasives](http://caml.inria.fr/pub/docs/manual-ocaml/libref/Pervasives.html) for various functions available in the OCaml top-level.

See [stdlib](http://caml.inria.fr/pub/docs/manual-ocaml/stdlib.html) for modules of extra functions for lists, strings, integers, as well as sets, trees, etc structures.

`print_x` for atomic types 'x', again no overloading in meaning here

```ocaml
print_string ("hi\n");;
```

Raise a failure exception (more on exceptions later)

```ocaml
(failwith "BOOM!") + 3 ;;
```

Invalid argument exception:
```ocaml
let f x = if x <= 0 then invalid_arg "Let's be positive, please!" else x + 1;;
f (-5);;
```

You CAN also declare types, anywhere in fact
 - Put parens around any such declaration or it won't parse

```ocaml
let add (x: float) (y: float) = x +. y;;
let add (x: int) (y: int) = (((x:int) + y) : int);;
```

Type abbreviations are also possible via `type `
```ocaml
type intpair = int * int;;
let f (p : intpair) = match p with
                      (l, r) -> l + r
;;
(2,3);; (* ocaml doesn't call this an intpair by default *)
f (2, 3);; (* still, can pass it to the function expecting an intpair *)
((2,3):intpair);; (* can also explicitly tag data with its type *)
```

### Time-out to solve some simple problems
Lets work through some simple programming problems to get experience with writing simple functional OCaml programs

1. Write a function 'compose_funs' which takes a list of functions `[f1; ...; fn]` and returns a function representing the composition `fn o .. o f1 of all of these.`

**Answer:**
```ocaml
let rec compose_funs lf =
  match lf with
    [] -> (function x -> x)
  | f :: fs -> (function x -> (compose_funs fs) (f x))
;;
```

Equivalent alternate version - refactor to hoist out the "function x"

```ocaml
let rec compose_funs lf =
  function x ->
    (match lf with
      [] -> x
    | f :: fs -> (compose_funs fs) (f x)
    )
;;
```

Yet another equivalent alternative - hoist x up one more level
```ocaml
let rec compose_funs lf x =
    match lf with
      [] -> x
    | f :: fs -> (compose_funs fs) (f x)
;;
```

Tests

```ocaml
let composeexample = compose_funs [(function x -> x+1); (function x -> x-1);
                 (function x -> x*3); (function x -> x-1)];;
assert(composeexample 5 = 14);;
```

2. Write a function 'toUpperCase' which takes a list (l) of characters and returns a list which has the same characters as l, but capitalized (if not already).

Notes: 
a. Assume that the capital of characters other than alphabets
            (A - Z or a - z), are the characters themselves e.g.

```
                character               corresponding capital character
                    a                             A
                    z                             Z
                    A                             A
                    1                             1
                    %                             %
```

b. You can only use `Char.code` and `Char.chr` library functions. You **cannot** use `Char.uppercase`.

**Answer:**
```ocaml
let toUpperChar c =
  let c_code = Char.code c in
  if c_code >= 97 && c_code <= 122 then
    Char.chr (c_code - 32)
  else c;;


let rec toUpperCase l =
  match l with
    [] -> []
  | c :: cs -> toUpperChar c :: toUpperCase cs
;;
```

Test
```ocaml
assert(toUpperCase ['a'; 'q'; 'B'; 'Z'; ';'; '!'] = ['A'; 'Q'; 'B'; 'Z'; ';'; '!']);;
```

Could have used map instead (note map is built in as `List.map`):

```ocaml
let toUpperCase l = List.map toUpperChar l ;;
```

Could have also defined it even more simply - partly apply the Curried map:

```ocaml
let toUpperCase = List.map toUpperChar ;;
```

3. Write a function 'nth' which takes a list (l) and index (n) and returns the nth element of the list. If n is an invalid index i.e. n is negative or l has less then (n + 1) elements then fail.

Note: indices start with 0 for the head of the list, 1 for the next element and so on (similar to arrays).

**Answer:**
```ocaml
let rec nth l n =
  match l with
  |  [] -> failwith "list too short"
  | x :: xs ->
      if n = 0 then
        x
      else
        nth xs (n - 1) (* eureka *)
;;
```

Tests
```ocaml
assert(nth [1;2;3] 0 = 1);;
nth [1;2;3] 1;; (* should return 2 *)
nth [1;2;3] (-1);; (* should raise exception *)
nth [1;2;3] 3;; (* should raise exception *)
```

4. Write a function 'partition' which takes a predicate (p) and a list (l) as arguments  and returns a tuple (l1, l2) such that l1 is the list of all the elements of l that satisfy the predicate p and l2 is the list of all the elements of l that do NOT satisfy p. The order of the elements in the input list (l) should be preserved.

Note: A predicate is any function which returns a boolean. e.g. let isPositive n = (n > 0);;

**Answer:**
```ocaml
let rec partition p l =
  match l with
  |[] -> ([],[])
  | hd :: tl ->
    let (posl,negl) = partition p tl in
    if (p hd)
    then
      (hd :: posl,negl)
    else
      (posl,hd::negl);;
```
Test

```ocaml
let isPositive n = n > 0 in
assert(partition isPositive [1; -1; 2; -2; 3; -3] = ([1; 2; 3], [-1; -2; -3]))
```

5. Write a function `diff` which takes in two lists l1 and l2 and returns a list containing all elements in l1 not in l2.

Note: You will need to write another function `contains x l` which checks  whether an element `x` is contained in a list `l` or not.

**Answer:**
```ocaml
let rec contains x l =
  match l with
    [] -> false
  | y :: ys -> x = y || contains x ys
;;

let rec diff l1 l2 =
  match l1 with
    [] -> []
  | x :: xs ->
      if contains x l2 then
    diff xs l2
      else
    x :: diff xs l2
;;
```

Tests
```ocaml
assert(contains 1 [1; 2; 3])
assert(not(contains 5 [1; 2; 3]))
assert(diff [1;2;3] [3;4;5] = [1; 2])
assert(diff [1;2] [1;2;3] = [])
```

### OCaml Lecture IV: Variants & records

We saw some simple examples of variants above, now we go into the full possibilities
  - related to union types in C or enums in Java: "this OR that OR theother"
  - like OCamls lists/tuples they are IMMMUTABLE data structures
  - each case of the union is identified by a name called 'Constructor' which serves for both
      - Constructing values of the variant type
      - inspecting them by pattern matching
      - Constructors must start with Capital Letter to distinguish from variables
      - type declarations needed but once they are in place type inference on them works


Example variant type for doing mixed arithmetic (integers and floats)

```ocaml
type mynumber = Fixed of int | Floating of float;;  (* read "|" as "or" *)

Fixed(5);; (* tag 5 as a Fixed *)
Floating 4.0;; (* tag 4.0 as a Floating *)
```

Note constructors look like functions but they are **not** -- you always need to give argument

```ocaml
let pullout_int x =
    match x with
    | Fixed n -> n    (* variants fit well into pattern matching syntax *)
    | Floating z -> int_of_float z;;

pullout_int (Fixed 5);;
```

A non-trivial function using the above variant type

```ocaml
let add_num n1 n2 =
   match (n1, n2) with    (* note use of pair here to parallel-match on two variables  *)
     | (Fixed i1, Fixed i2) ->       Fixed   (i1       +  i2)
     | (Fixed i1,   Floating f2) ->  Floating(float i1 +. f2)       (* need to coerce *)
     | (Floating f1, Fixed i2)   ->  Floating(f1       +. float i2) (* ditto *)
     | (Floating f1, Floating f2) -> Floating(f1       +. f2)
;;

add_num (Fixed 123) (Floating 3.14159);;
```

Multiple data items in a single clause?  Use the pre-existing tuple types

```ocaml
type complex = CZero | Nonzero of float * float;;

let com = Nonzero(3.2,11.2);;
let zer = CZero;;
```

#### Recursive data structures 
  - A key use of variant types
  - Functional programming is fantastic for computing over tree-structured data
  - recursive types can refer to themselves in their own definition
  - similar in spirit to how C structs can be recursive (but, no pointer needed here)

Warm-up: homebrew lists - built-in list type not needed
First just int lists

```ocaml
type myintlist = Mt | Cons of int * myintlist;; (* Observe: self-referential type *)
let mylisteg = Cons(3,Cons(5,Cons(7,Mt)));; (* equivalent to [3;5;7] *)
```
Let us extend the above to be just like built-in polymorphic lists

```ocaml
type 'a mylist = Mt | Cons of 'a * ('a mylist);;
```
Observe how above type takes a (prefix) argument, 'a -- "mylist" is a type function

```ocaml
let mylisteg = Cons(3.,Cons(5.,Cons(7.,Mt)));;
```

```ocaml
let rec double_list_elts ml =
  match ml with
    | Mt -> Mt (* vs [] -> [] *)
    | Cons(hd,tl) -> Cons(hd *. 2.,double_list_elts tl);; (* vs hd :: tl -> .. *)

double_list_elts mylisteg;;
```

Binary trees, like lists but two self-referential sub-structures not one

```ocaml
type 'a btree = Leaf | Node of 'a * 'a btree * 'a btree;;
```

Example trees

```ocaml
let whack = Node("whack!",Leaf, Leaf);;
let bt = Node("fiddly ",
            Node("backer ",
               Leaf,
               Node("crack ",
                  Leaf,
                  Leaf)),
            whack);;

let bt2 = Node("fiddly ",
            Node("backer ",
               Leaf,
               Node("crack ",
                  Leaf,
                  Leaf)),
            whack);;
(* Type error, like list, must have uniform type: *)
Node("fiddly",Node(0,Leaf,Leaf),Leaf);;
```

Functions on binary trees are similar to functions on lists: use recursion

```ocaml
let rec add_gobble binstringtree =
   match binstringtree with
     Leaf -> Leaf
   | Node(y, left, right) ->
       Node(y^"gobble",add_gobble left,add_gobble right)
;;
```
(Remember, this is not mutating the tree, its building a new one)

```ocaml
let rec lookup x bintree =
   match bintree with
     | Leaf -> false
     | Node(y, left, right) ->
       if x = y then
          true
       else if x < y then
          lookup x left
       else
          lookup x right
;;

lookup "whack!" bt;;
lookup "flack" bt;;
```

```ocaml
let rec insert x bintree =
   match bintree with
     Leaf -> Node(x, Leaf, Leaf)
   | Node(y, left, right) ->
       if x <= y then
         Node(y, insert x left, right)
       else
         Node(y, left, insert x right)
;;
```

This is also NOT MUTATING -- returns a whole new tree instead.

```ocaml
let goobt = insert "goober " bt;;
bt;; (* observe bt did not change after the insert *)
let gooobt = insert "slacker " goobt;; (* thread in the most recent tree *)
```

### Records
  - like tuples but with labels on fields.
  - similar to the structs of C/C++.
  - the types must be declared just like OCaml variants.
  - can be used in pattern matches as well.
  - again the fields are immutable by default
  - not used as often as structs of C, most data is a variant with tupled multiple arguments

Record type to represent rational numbers

```ocaml
type ratio = {num: int; denom: int};;
let q = {num = 53; denom = 6};;
q.num;;
q.denom;;
```

Pattern matching works of course
```ocaml
let rattoint r =
 match r with
   {num = n; denom = d} -> n / d;;
```

Only one pattern matched so can again inline pattern in functions and lets
```ocaml
let rattoint {num = n; denom = d}  =
   n / d;;
```

Equivalently can use dot projections, but happy path is usually patterns
```ocaml
let rattoint r  =
   r.num / r.denom;;
rattoint q;;
```

```ocaml
let add_ratio r1 r2 = {num = r1.num * r2.denom + r2.num * r1.denom; 
                      denom = r1.denom * r2.denom};;
add_ratio {num = 1; denom = 3} {num = 2; denom = 5};;
```

Annoying shadowing issue: there is one global namespace of record labels
```ocaml
type newratio = {num: int; coeff: float};; (* shadows ratio's label num *)

fun x -> x.num;; (* x is a newratio, the most recent num field defined *)
```
Solution in event of shadowing: pattern match on full record

```ocaml
fun {num = n; denom = _} -> n;;
```
OCaml programmers often use tuples instead of records for conciseness

* End of pure functional programming in OCaml, on to side effects
* But before heading there, remember to stay OUT of side effects unless *really* needed - that is the happy path in OCaml coding
* For interpreters and typecheckers side effects are not helpful at all

### State
 *   Variables in OCaml are NEVER directly mutable themselves; only (indirectly) mutable if they hold a
      - reference
      - mutable record
      - array

Indirect mutability - variable itself can't change, but what it points to can.
 - items are immutable unless their mutability is explicitly declared

### Mutable References

```ocaml
let x = ref 4;;    (* always have to declare initial value when creating a reference *)
```

Meaning of the above: x forevermore (i.e. forever unless shadowed) refers to a fixed cell.  The **contents** of that fixed call can change, but not x.

```ocaml
x + 1;; (* a type error ! *)
!x + 1;; (* need !x to get out the value; parallels *x in C *)
x := 6;; (* assignment - x must be a ref cell.  Returns () - goal is side effect *)
!x + 1;; (* Mutation happened to contents of cell x *)
```

* `'a ref` is really implemented by a mutable record with one field, contents:
* `'a ref` abbreviates the type `{ mutable contents: 'a }`
* The keyword mutable on a record field means it can mutate

```ocaml
let x = { contents = 4};; (* identical to x's definition above *)
x := 6;;
x.contents <- 7;;  (* same effect as previous line: backarrow updates a field *)

!x + 1;;
x.contents + 1;; (* same effect as previous line *)
```

Declaring your own mutable record: put `mutable` qualifier on field

```ocaml
type mutable_point = { mutable x: float; mutable y: float };;
let translate p dx dy =
                p.x <- (p.x +. dx); (* observe use of ";" here to sequence effects *)
                p.y <- (p.y +. dy)  (* ";" is useless without side effects (think about it) *)
                                ;;
let mypoint = { x = 0.0; y = 0.0 };;
translate mypoint 1.0 2.0;;
mypoint;;
```

Observe: mypoint is immutable at the top level but it has two spots in it where we can mutate

Tree with mutable nodes

```ocaml
type mtree = MLeaf | MNode of int * mtree ref * mtree ref;;
```

- ONLY ref typed variables or mutable records may be assigned to
- The notion of immutable variables is one of the great strengths of OCaml.
- Note: `let` doesn't turn into a mutation operator with `ref`:

```ocaml
let x = ref 4;;
let f () = !x;; (* This is syntax for a 0-argument function in OCaml - it only takes () as argument *)

x := 234;;
f();;

let x = ref 6;; (* shadowing previous x definition, NOT an assignment to x !! *)
f ();;
```

Yes, we can even use ";" and with it write a while loop !
```ocaml
let x = ref 1 in
    while !x < 10 do
      print_int !x;
      print_string "\n";
      x := !x + 1;
    done;;
```

Fact: while loops are useless without mutation: either never loop or infinitely loop

Why is immutability good?
 - programmer can depend on the fact that something will never be mutated when writing code: permanent like mathematical definitions
 - ML still lets you express mutation, but its only use it when its really needed
 - Haskell has an even stronger separation of mutation, its all strictly "on top".

### Arrays
 - fairly self-explanatory
 - have to be initialized before using
 - in general there is no such thing as "uninitialized" in OCaml.


```ocaml
let arrhi = Array.make 100 "";; (* size and initial value are the params here *)
let arr = [| 4; 3; 2 |];; (* another way to make an array *)
arr.(0);; (* access (unfortunately already used [] for lists in the syntax) *)
arr.(0) <- 55;; (* update *)
arr;;
```

### Exceptions
* Pretty standard and mostly Java-like
* Unfortunately types do not include what exceptions a function will raise - outdated aspect of ML.

```ocaml
exception Foo;;  (* This is a new form of top-level declaration, along with let, type *)

let f () = raise Foo;; (* note no need to "raises Foo" in the type as in Java *)
f ();;

exception Bar;;

let g _ = 
  (try
    f ()
  with
    Foo ->  5 | Bar -> 3) + 4;; (* Use power of pattern matching in handlers *)
g ();;
```

Exceptions with a parameter - syntax is like a variant
```ocaml
exception Goo of string;;

let f _ = raise (Goo "keyboard on fire");;
f ();;

let g () =
  try
    f ()
  with
      Foo -> ()
        | Goo s ->
      (print_string("exception raised: ");
       print_string(s);print_string("\n"))
;;
g ();;
```

There are a few built-in exceptions we already saw

```ocaml
failwith "Oops";; (* Generic code failure - exception is named Failure *)
invalid_arg "This function works on non-empty lists only";; (* Invalid_argument exception *)
```
###  OCaml Lecture V

### Modules - structures and functors

Modules in programming languages
   - a module is a larger level of program abstraction: functional units or library.
   - e.g. Java package, Python module, C directory, etc
   - needed for all but very small programs: imagine a file system without directories/folders as analogy to a PL without modules - YUCK!

Some principles of modules:
  -  Modules have names they can be referenced by.
  -  A module contains code declarations: functions, classes,  types, etc.
  - They often are file-based: one module per file, module name is file name
  -  The module has a way to
      * import things (e.g. other modules) from the outside and
      * export some (or all) things it has declared for outsiders to use;
      * it may **hide** some things for internal use only
         -- hiding is a key feature, don't overwhelm users
      * Separate name spaces, so e.g. the Window's reset() won't clash
        with a File's reset(): use `Window.reset()` and `File.reset()`
      * Nested name spaces for ever larger software: `Window.Init.reset()`
      * Often modules can be compiled separately (for compiled languages)

Most modern languages have a module system solving most of these problems.

For example the Java module system: **packages**
  - File system directory is explicitly a package; supports nested packages
  - Implicit export via public classes/methods
  - private/protected for hiding internals from outside users
  - Separate namespace for each package avoids name clashes

 The C "module" system is a historical garbage pit
   - Informal use of files and filesystem directories as modules
   - .h file declaring what is externally visible for a module
   - There is a global space of function names, so there can be name clashes
   - There is no strict relation enforced between the `.c` and `.h`  files
       * bad programmers can write really ugly code
   - C++ fixed this (eventually) with namespaces


### Modules in OCaml

We already saw OCaml modules in action earlier, e.g. with `List.map`.  This is an invocation of the map function in the system `List module`.

```ocaml
List.map (fun x -> x ^"gobble")["Have";"a";"good";"day"];;
```
See the [standard library documentation](http://caml.inria.fr/pub/docs/manual-ocaml/stdlib.html) to see all the operations possible with List, and for all the other built-in modules

Now, lets look into how we can build our own OCaml modules

OCaml module definitions are called **structures**
    - collections of related definitions (functions, types, other structures, exceptions, values, ...) given a name

Lets make a simple functional set module in OCaml

```ocaml
module FSet = (* Module names must start with a Capital Letter *)
struct (* keyword stands for "structure" *)
  exception NotFound (* any top-level definable can be included in a module *)

  type 'a set = 'a list (* sets are just lists but make a new type to keep them distinct *)

  let emptyset : 'a set = []

  let rec add x (s: 'a set) = ((x :: s) : ('a set)) (* observe this is a FUNCTIONAL set - RETURN new *)

  let rec remove x (s: 'a set) =
   match s with
    | [] -> raise NotFound
    | hd :: tl ->
     if hd = x then (tl: 'a set)
     else hd :: remove x tl

  let rec contains x (s: 'a set) =
   match s with
   | [] -> false
   | hd :: tl ->
     if x = hd then true else contains x tl
end
;;
```

Observe what is printed in the top loop when the above is entered: a module *signature* is inferred

- The types of structs are called signatures
  - they are the interfaces for structures, something like Java interfaces
  - signatures can be used to hide some things from outside users


Use modules via dot notation, like `List.map` above

```ocaml
let mySet = FSet.add 5 [];;
let myNextSet = FSet.add 22 mySet;;
FSet.contains 22 mySet;;
FSet.remove 5 myNextSet;;

open FSet;; (* puts an implicit "FSet." in front of all things in FSet; may shadow existing names *)

add "a" ["b"];;
contains "a" ["a"; "b"];;
```

OCaml's module signatures and using them for information hiding

```ocaml
module type GROWINGSET = (* define a module type (signature) with no remove; not very useful *)
  sig
    exception NotFound
    type 'a set = 'a list
    val emptyset : 'a set
    val add : 'a -> 'a set -> 'a set
    val contains : 'a -> 'a set -> bool
  end
;;

module GrowingSet = (FSet: GROWINGSET);; (* constrain a structure to have that signature *)
GrowingSet.add "a" ["b"];;

(* GrowingSet.remove;; *) (* Error: remove in struct but not in signature! *)

FSet.remove;;  (* This is still fine, remember we are not mutating FSet when making GrowingSet *)
```

Now lets do some useful hiding.  Hiding types is possible and allows "black box" data structures
   - can be good software engineering practice to enforce hiding of internals

```ocaml
module type HIDDENSET =
  sig
    type 'a set (* hide the type 'a list here by not giving 'a set definition in signature *)
    val emptyset : 'a set
    val add: 'a -> 'a set -> 'a set
    val remove : 'a -> 'a set -> 'a set
    val contains: 'a -> 'a set -> bool
  end
;;

module HiddenSet = (FSet: HIDDENSET);;

HiddenSet.add 3 [];; (* Errors: [] not a set since we HID the fact that sets are really lists *)

let hs = HiddenSet.add 5 (HiddenSet.add 3 HiddenSet.emptyset);; (* now it works - <abstr> result means type is abstract *)
HiddenSet.contains 5 hs;;
```

Also can declare signature along with module

```ocaml
module HFSet :
  sig
    type 'a set
    val emptyset : 'a set
    val add: 'a -> 'a set -> 'a set
    val remove : 'a -> 'a set -> 'a set
    val contains: 'a -> 'a set -> bool
  end =
struct
exception NotFound (* any top-level definable can be included in a module *)

type 'a set = 'a list (* sets are just lists but make a new type to keep them distinct *)

let emptyset : 'a set = []

let rec add x (s: 'a set) = ((x :: s) : ('a set)) (* observe this is a FUNCTIONAL set - RETURN new *)

let rec remove x (s: 'a set) =
  match s with
  | [] -> raise NotFound
  | hd :: tl ->
    if hd = x then (tl: 'a set)
    else hd :: remove x tl

let rec contains x (s: 'a set) =
  match s with
  | [] -> false
  | hd :: tl ->
    if x = hd then true else contains x tl
end
;;

let hs = HFSet.add 5 (HFSet.add 3 HFSet.emptyset);; (* same use as before *)
```

### Separate Compilation with OCaml

- We can program OCaml in a cc / javac like way - use ocamlc instead of ocaml.
- Key invariant: each OCaml module is a separate .ml file
- Syntax of module **body** is identical
- No header "module XX = struct .. end" is included in .ml module file
- Name of module is capped name of file: fSet.ml defines module FSet
- File fSet.mli holds the signature of module FSet if there is no file set.mli thats OK; you have nothing hidden
- Use ocamlc to compile and link to an executable: similar to C/C++
- main program that starts running is any non-values defined in the module(s)
- Also need to compile the .mli files! (unlike .h files)

Here is how the ocamlc compiler makes object files

      .ml -- ocamlc -c --> .cmo
      .mli -- ocamlc -c --> .cmi

Then to make the binary

      .cmo's -- ocamlc -o mybinary --> mybinary

You need any dependent .cmi's for modules you refer to before you can ocamlc -c them.


Example of how file method of definition relates to top-loop: 

```ocaml
module FSet: sig (* contents of file fSet.mli *) end
          = struct (* contents of file fSet.ml *) end;;

module Main: sig (* contents of main.mli *) end
           = struct (* contents of main.ml *) end;;
```

* See [sep.zip](http://pl.cs.jhu.edu/pl/ocaml/code/sep.zip) for the example we cover in lecture.
* We will follow [readme.txt](http://pl.cs.jhu.edu/pl/ocaml/code/sep_compile/readme.txt) in particular.
* See the ocaml manual Chapter 8 for the full documentation


#### Loading object file modules into the top loop

It is possible to mix ocamlc and ocaml for debugging: load .cmo files into top loop.

For the following to work need to first `#cd` to `sep_compile/`.  My computer's version: 
```
#cd "/Users/scott/pl/ocaml/code/sep_compile";;
```
Note you can use `#pwd` to see what directory you are in now in OCaml.


```ocaml
#load "fSet.cmo";;
FSet.emptyset;;
```
### Functors
 * A "function" from structures to structures
 * Allows a module to be parameterized and so instantiated in multiple ways
    - think of it as the ability to "plug in" a code module
 * In object-oriented languages, object polymorphism gives you much of this ability
    - the "Animal" variable can have a Dog, Cat, Fish, etc plugged in to it
    - But, OCaml has no object polymorphism and something is needed to support this
    - General functors are found only in a few languages

Recall this type above: `type comparison = LessThan | EqualTo | GreaterThan`

Here is a kind of struct that we can take as a parameter; in Java we would just use an interface Comparable

```ocaml
module type ORDERED_TYPE =
  sig
    type t
    val compare: t -> t -> comparison
  end;;
```
Here is a functor version of a set, you feed in a struct with the set element ordering defined on it

```ocaml
module FSetFunctor =
  functor (Elt: ORDERED_TYPE) ->
  struct
    type element = Elt.t (* import the type of elements from the structure *)
    type set = element list

    let empty = []

    let rec add x s =
      match s with
        [] -> [x]
      | hd::tl ->
          match Elt.compare x hd with
            EqualTo   -> s
          | LessThan    -> x :: s
          | GreaterThan -> hd :: add x tl

    let rec contains x s =
      match s with
        [] -> false
      | hd::tl ->
          match Elt.compare x hd with
            EqualTo   -> true
          | LessThan    -> false
          | GreaterThan -> contains x tl
  end;;
```

Here is a concrete ordering we can feed in, one over ints

```ocaml
module OrderedInt =
  struct
    type t = int
    let compare x y =
      if x = y then
    EqualTo
      else
    if x < y then
      LessThan
    else
      GreaterThan
  end;;
```

Here is how we feed it in, instantiating the functor to give a structure

```ocaml
module OrderedIntSet = FSetFunctor(OrderedInt);; (* note how this looks like a function application *)

let myOrderedIntSet = OrderedIntSet.add 5 OrderedIntSet.empty;;
OrderedIntSet.contains 3 myOrderedIntSet;;
```

We can do the same thing for a string comparison

```ocaml
module OrderedString =
struct
  type t = string
  let compare x y =
    if x = y then EqualTo
    else if x < y then LessThan
    else GreaterThan
end;;

module OrderedStringSet = FSetFunctor(OrderedString);; (* a DIFFERENT instantiation of same *)

let myOrderedStringSet = OrderedStringSet.add "abc" OrderedStringSet.empty;;
```

Functors also have signatures; there can also be type abstraction in a functor signature

```ocaml
module type SETFUNCTOR = (* below is the syntax for a signature of a functor *)
    functor (Elt: ORDERED_TYPE) ->
  sig
    type element = Elt.t      (* concrete *)
    type set                  (* abstract *)
    val empty : set
    val add : element -> set -> set
    val contains : element -> set -> bool
  end;;

module AbstractSet = (FSetFunctor : SETFUNCTOR);; (* slap that sig on a functor *)
module AbstractIntSet = AbstractSet(OrderedInt);;

AbstractIntSet.add 5 AbstractIntSet.empty;;
```