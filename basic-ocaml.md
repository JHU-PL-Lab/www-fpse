## Introduction to OCaml

Installing: see [the Coding page](https://pl.cs.jhu.edu/fpse/coding.html) for install instructions and lots of other information

### The Ecosystem via Hello World in OCaml

In a file `helloworld.ml` type

```ocaml
let hw = "hello"^" world"
```
* Paste into `ocaml` then in `utop`
* Save file in new directory, `ocamlc helloworld.ml`
* `./a.out` to run
* Nothing happens?  Because executables only interact by I/O (think Java, C, etc)
* Re-write to add 
```ocaml
print_string hw
```
* recompile and run: we get some output!

#### Building and running with Dune

* In same directory, add a file `dune`:
```scheme
(executable
  (name helloworld)
  (modules helloworld)
)
```
* This is the build file, like a `Makefile`.
* Now, type `dune build` to compile a standalone program like we did above.
* Then, run with `dune exec ./helloworld`

#### Adding a Library

* Lets make printing less primitive: use a `Core` library function, `printf`
* Replace printing with line `Core.printf "the string is %s\n" hw`
* Try building - gives an error
* Add line `(libraries core)` to dune file to fix
* Compile and run

#### Exploring Basic Data in the top loop

* We will use the `utop` top loop; the classic version is `ocaml` which has fewer bells and whistles
* See [the Coding page](https://pl.cs.jhu.edu/fpse/coding.html) to install `utop`.  Note you need to also set up an `.ocamlinit` file as per that page
* All the following are typed as input into `utop` with `;;` ending input.

 
* Integers
```ocaml
3 + 4;;
let x = 3 + 4;; (* give the value a name via let keyword. *)
let y = x + 5;; (* can use x now *)
let z = x + 5 in z - 1;;
```

#### Boolean operations

```ocaml
let b = true;;
b && false;;
true || false;;
1 = 2;; (* = not == for equality comparison *)
1 <> 2;;  (* <> not != for not equal *)
```

#### Other basic data -- see documentation for details
```ocaml
4.5;; (* floats *)
4.5 +. 4.3 (* operations are +. etc not just + which is for ints only *)
30980314323422L;; (* 64-bit integers *)
'c';; (* characters *)
"and of course strings";;

```
#### Simple functions on integers

To declare a function `squared` with `x` its one parameter.  `return` is  implicit.
```ocaml
let squared x = x * x;; 
squared 4;; (* to call a function -- separate arguments with S P A C E S *)
```
 *  OCaml has no `return` statement; value of the whole body-expression is what gets returned
 *  Type is automatically **inferred** and printed as domain `->` range
 *  OCaml functions in fact take only one argument - !  multiple arguments can be encoded by a trick (later)

#### Fibonacci series example - `0 1 1 2 3 5 8 13 ...` 

Let's write a well-known function with recursion

```ocaml
let rec fib n =     (* the "rec" keyword needs to be added to allow recursion *)
  if n <= 0 then 0
  else if n = 1 then 1
  else fib (n - 1) + fib (n - 2);; (* notice again everything is an expression, no "return" *)

fib 10;; (* get the 10th Fibonacci number *)
```

#### Anonymous functions

* Key to FP: functions are just expressions; put them in variables, pass and return from other functions, etc.
* Similar to lambdas in Python, Java, C++, etc - all are based on the lambda calculus *)

```ocaml
let add1 x = x + 1;; (* normal add1 definition *)
let funny_add1 = (function x -> x + 1);; (* "x" is argument here *)
funny_add1 3;;
(funny_add1 4) + 7;; 
((function x -> x + 1) 4) + 7;; (*  a "->" function is an expression and can be used anywhere *)
((fun x -> x + 1) 4) + 7;; (*  shorthand notation -- cut off the "ction" *)
```

* Multiple arguments - just leave spaces between multiple arguments

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

### Simple Structured Data Types: Option and Result

* Before getting into "bigger" data types and how to declare our own, let's use one of the simplest structured data types, the built-in `option` type.

```ocaml
Some 5;;
- : int option = Some 5
```

* all this does is "wrap" the 5 in the `Some` tag

```ocaml
None;;
- : 'a option = None
```

 * Notice these are both in the `option` type .. either you have `Some` data or you have `None`.
 * This type is very useful; here is a simple example.

 ```ocaml
# let nice_div m n = if n = 0 then None else Some (m / n);;
val nice_div : int -> int -> int option = <fun>
# nice_div 10 0;;
- : int option = None
# nice_div 10 2;;
- : int option = Some 5
```

There is a downside with this though, you can't just use `nice_div` like `/`:

```ocaml
# (nice_div 5 2) + 7;;
Line 1, characters 0-14:
Error: This expression has type int option
       but an expression was expected of type int
```

This type error means the `+` lhs should be type `int` but is a `Some` value so is not an `int`.

Here is a non-solution to that:
 ```ocaml
# let not_nice_div m n = if n = 0 then None else m / n;;
Line 1, characters 47-52:
Error: This expression has type int but an expression was expected of type
         'a option
```
- The `then` and `else` branches must return the same type, here they do not.

#### Pattern matching first example

Here is a real solution to the above issue:
```ocaml
# match (nice_div 5 2) with 
   | Some i -> i + 7 (* i is bound to the result, 2 here *)
   | None -> failwith "This should never happen, we divided by 2";;
- : int = 9
```
* This shows how OCaml lets us *destruct* option types, via the `match` syntax.
* `match` is similar to `switch` in C/Java/.. but is much more flexible in OCaml
* LHS in OCaml can be a general pattern
* Note that we turned `None` into an exception via `failwith`.

#### Result

An "even nicer" version of the above would be to use the `result` type, which is very similar to option.
```ocaml
# let nicer_div m n = if n = 0 then Error "Divide by zero" else Ok (m / n);;
val nicer_div : int -> int -> (int, string) result = <fun>
```
* The `result` type is explicitly intended for this case of failure-result
    - `Ok` means the normal result
    - `Error` is the error case, which unlike none can include failure data.
* Again we can do the same kind of pattern match on `Ok/Error` as above.
* This is a "more well-typed" version of the C approach of returning `-1` or `NULL` to indicate failure.

```ocaml
# match (nicer_div 5 2) with 
   | Ok i -> i + 7
   | Error s -> failwith s;;
- : int = 9
```

Lastly, the function could itself raise an exception

```ocaml
let div_exn m n = if n = 0 then failwith "divide by zero is bad!" else m / n;;
div_exn 3 4;;
```

Which has the property of not needing a match on the result.

### Lists

Lists are pervasive in OCaml; easy to create and manipulate

```ocaml
let l1 = [1; 2; 3];;
let l2 = [1; 1+1; 1+1+1];;
let l3 = ["a"; "b"; "c"];;
let l4 = [1; "a"];; (* errors - All elements must have same type - HOMOGENEOUS *)
let l5 = [];; (* empty list *)
```

#### Building lists 

Lists are represented internally as BINARY TREES with left child a leaf.
```ocaml
0 :: l1;; (* "::" is 'consing' an element to the front - fast *)
0 :: (1 :: (2 :: (3 :: [])));; (* equivalent to the above *)
[1; 2; 3] @ [4; 5];; (* appending lists - slower *)
let z = [2; 4; 6];;
let y = 0 :: z;;
z;; (* Observe z itself did not change -- lists are immutable in OCaml *)
```

#### Destructing Lists with pattern matching

```ocaml
let rec rev l =
  match l with
  |  [] -> []
  |  x :: xs -> rev xs @ [x]
;;
rev [1;2;3];; (* = 1 :: ( 2 :: ( 3 :: [])) *)
```

* Correctness of a recursive function by induction: assume recursive call does what you expect in arguing it is overall correct.
* For this example, can assume `rev xs` always reverses the tail of the list.
* Given that fact, `rev xs @ [x]` should clearly reverse the whole list.
* QED, the function is proved correct! (actually partially correct, it could also loop forever)

#### Immutable Data Structures in Functional Programming

* By default, data structures are immutable
* A change is instead implemented as rebuilding the whole list from scratch
* This style of programming: "Data structure corresponds to control flow"

Example: zero out all the negative elements in a list of numbers.

