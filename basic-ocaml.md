## Introduction to OCaml

### Installing

 * See [the Coding page](https://pl.cs.jhu.edu/fpse/coding.html) for install instructions and lots of other information.  
 * Make sure to use the required 4.10.0 version of OCaml, install the libraries listed via `opam`, and change your `.ocamlinit` file as mentioned on this page.
    - This will let us all "play in the same sandbox" and avoid confusions

### The Ecosystem via Hello World in OCaml

* Before getting into the details of the language we will cover the ecosystem at a high level

#### The top loop

* Let's type the following in a file `helloworld.ml`:

```ocaml
let hw = "hello"^" world"
```
* Now, run the shell command `ocaml`, copy/paste this code in, add a `;;` and hit return - it runs!
* Control-D to quit `ocaml`, let us switch to its improved version, `utop`, and do the same thing.

#### The compile/run system

* The above is the **top loop** aka **read-eval-print** view of OCaml.  You probably know this from Python/Javascript/shell/etc.
* Let us now do the compile/run view of C/C++/Java/etc.
* In OCaml we really want to live in **both worlds**

* From the shell type `ocamlc helloworld.ml` to compile and then `./a.out` to run
* Nothing happens?  Because executables only interact by I/O (think Java, C, etc)
* Re-write to add line
```ocaml
print_string hw
```
* recompile and run: we get some output!


#### Building and running with Dune

* `dune` is the modern `Makefile` equivalent for OCaml.
* In same directory, add a file `dune`:
```scheme
(executable
  (name helloworld)
  (modules helloworld)
)
```
* This is the **build file**, specifying how to compile/test/run the program.
* Now, type `dune build` to compile a standalone program like we did above but letting `dune` invoke the compiler.
* Then, run with `dune exec ./helloworld`

#### Adding a Library

* Let's make printing less primitive: use a `Core` library function, `printf`
* Replace printing with line `Core.printf "the string is %s\n" hw`
* Try building - gives an error
* Add line `(libraries core)` to dune file to fix -- all library dependencies must be listed in the dune file
* Compile and run

### Exploring Basic Data in the top loop

* We will be running many small incremental programs - best done in the top loop.
* We will always use the `utop` top loop
* All the following are typed as input into `utop` with `;;` ending input.

 
* Integers
```ocaml
3 + 4;;
let x = 3 + 4;; (* give the value a name via let keyword. *)
let y = x + 5;; (* can use x now *)
let z = x + 5 in z - 1;; (* let .. in defines a local variable z *)
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
4.5 +. 4.3;; (* operations are +. etc not just + which is for ints only *)
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

Let's write a well-known function with recursion and if-then-else syntax

```ocaml
let rec fib n =     (* the "rec" keyword needs to be added to allow recursion *)
  if n <= 0 then 0
  else if n = 1 then 1
  else fib (n - 1) + fib (n - 2);; (* notice again everything is an expression, no "return" *)

fib 10;; (* get the 10th Fibonacci number *)
```

#### Anonymous functions

* Key purpose of FP: functions are just expressions; put them in variables, pass and return from other functions, etc.
* Much of this course will be showing how this is useful, we are just getting started now

```ocaml
let add1 x = x + 1;; (* a normal add1 definition *)
let anon_add1 = (function x -> x + 1);; (* anonymous version; "x" is argument here *)
anon_add1 3;;
(anon_add1 4) + 7;; 
((function x -> x + 1) 4) + 7;; (* can inline any anonymous function as well *)
((fun x -> x + 1) 4) + 7;; (*  shorthand notation usually works -- cut off the "ction" *)
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

* Lists are pervasive in OCaml; easy to create and manipulate
* They are always immutable so while they look something like arrays or vectors they are different

```ocaml
let l1 = [1; 2; 3];;
let l2 = [1; 1+1; 1+1+1];;
let l3 = ["a"; "b"; "c"];;
let l4 = [1; "a"];; (* error - All elements must have same type - HOMOGENEOUS *)
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
* QED, the function is proved correct! (actually partially correct, this induction argument does not rule out infinite loops)

#### Immutable Data Structures in Functional Programming

* By default, data structures are immutable
* A change is instead implemented as rebuilding the whole list from scratch
* This style of programming: "Data structure corresponds to control flow"

Example: zero out all the negative elements in a list of numbers.

