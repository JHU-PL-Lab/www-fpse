## Introduction to OCaml

(see the file [basic-ocaml.ml](basic-ocaml.ml) if you want all of the ml examples in this file extracted out.  See [basic-ocaml.md](basic-ocaml.md) for the Markdown which you can Preview in VSCode like I am doing in lecture)
### Installing

 * See [the Coding page](https://pl.cs.jhu.edu/fpse/coding.html) for install instructions and lots of other information.  
 * Make sure to use the required version of OCaml, 5.3.0, install all the libraries listed via `opam`, and change your `.ocamlinit` file as mentioned on that page.
    - This will let us all "play in the same sandbox" and avoid confusion

### The Ecosystem via Hello World in OCaml

* Before getting into the details of the language we will cover the ecosystem at a high level

#### The top loop

* Top loops allow you to type in small snippets of code which will run and produce a result.
  - e.g. shells like `bash`, Python's `python3`, JavaScript `node`, etc.
* The OCaml top loop is started with the shell command `utop`.  
* We will run the OCaml top loop and show you you can enter expressions such as `3+4`, follow with `;;` to indicate end of input (`;;` is **required**), and hit return to get the result

```ocaml
utop # 3+4;;
- : int = 7
```

* Control-D will exit `utop`.


#### The Standalone Compiler

* The `ocamlc` compiler is the analogue of the  `cc`/`gcc`/`javac` compilers you have used
  - Compilers translate source code to a binary which you can then run from the shell.
* In OCaml it is useful to live in **both worlds**: both play with code in a top loop, *and* use a compiler to compile it to a binary.
* Let's cover how we will compile in OCaml.  Suppose the following is in a file `helloworld.ml`:
```ocaml
open Core;; (* Make the Core libraries directly available *)
let hw = "hello" ^ "world";;
printf "the string is %s\n" hw
```

* (The actual compiler is `ocamlc` or `ocamlopt`, but we will never be directly invoking it)
* Instead we will operate at a higher level and use build tool `dune` to invoke the compiler
* `dune` is a modern `make`/`Makefile` equivalent for OCaml which is very powerful.
* So, in same directory, there should be a `dune` file with the following contents:
```scheme
(executable             ; create an executable
  (name helloworld)     ; need to give it a name
  (modules helloworld)  ; it consists of just one module, helloworld.ml
  (libraries core)      ; indicates that the core libraries are used
)
```
* This is the **build file**, specifying how to compile/test/run the program.  The notation is S-expressions.
* Also a file `dune-project` is needed with only `(lang dune 3.19)` in it.
* Now, type `dune build` to compile this `helloworld.ml` code as an executable.
* All of the results are placed in a new `_build/` sub-directory
* Then, run with `dune exec ./helloworld.exe` - same as typing `_build/default/helloworld.exe`
* We will be using `dune` to build libraries and binaries, and `utop` to play with them.
* If you want to try these commands yourself the above `helloworld.ml` and dune files are in [this zip](helloworld.zip), just unzip and the `dune` commands above should work from within the `helloworld` directory.

### OCaml Language Basics in `utop`

* We will start with OCaml by running tiny examples in the top-loop, but for the first assignment you will be working in both worlds.
 
###  Integers

```ocaml
3 + 4;; (* outputs `- : int = 7` -- the value is 7, int is the type, "-" means no name given *)
let x = 3 + 4;; (* outputs `val x : int = 7` - give the result value a name, via let. *)
let y = x + 5;; (* the above defines `x` so can use it subsequently *)
let z = x + 5 in z - 1;; (* let .. in defines a local variable z *)
(* z is not defined after the `in` is over: z + 1 ;; will give an error. *)
```

#### Boolean operations

```ocaml
let b = true;;
b && false;;
true || false;;
1 = 2;; (* = not == for equality comparison; note = works on ints only in our OCaml setup *)
1 <> 2;;  (* <>, not !=, for not equal *)
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

Let's declare a function `squared` with `x` as its one parameter.  `return` is  implicit.
```ocaml
let squared x = x * x;; (* outputs `val squared : int -> int = <fun>` *)
squared 4;; (* to call a function -- separate arguments with S P A C E S - ! *)
```
 *  OCaml has no `return` statement; value of the whole body-expression is what gets returned
 *  Type is automatically **inferred** and printed as `domain -> range`; `int -> int` here.
 *  OCaml functions in fact always take only one argument - !  multiple arguments can be encoded (covered later)

#### Fibonacci series example - `0 1 1 2 3 5 8 13 ...` 

Let's write a well-known function with recursion and if-then-else syntax

```ocaml
let rec fib n = (* the "rec" keyword needs to be added to allow recursion *)
  if n <= 0 then 0
  else if n = 1 then 1
  else fib (n - 1) + fib (n - 2);; (* notice again everything is an expression, no "return" *)

fib 10;; (* get the 10th Fibonacci number; 2^10 steps so don't make input too big! *)
```

* Nested conditionals as above are generally avoided in OCaml since they are not very readable.  
* Here is an easier to read `fib` using pattern `match` notation similar to Java/C `switch` (we will cover `match` in detail later):

```ocaml
let rec fib x = match x with
  | 0 -> 0 
  | 1 -> 1 
  | n -> fib (n - 1) + fib (n - 2);;
```
#### Functions are just values like integers and booleans

* Key feature of FP: functions can be put in variables, passed and returned from other functions, etc.
* There is no need to give functions a name, they can be very short-lived and it can be cumbersome to name them all
* Much of this course will be showing how this is useful

```ocaml
let add1 x = x + 1;; (* the normal way to define an add1 function in OCaml *)
add1 3;;
let add1' = (function x -> x + 1);;  (* another way: define a `function` value and put in a regular variable *)
let add1'' = (fun x -> x + 1);;      (* equivalent shorthand -- cut off the "ction" *)
add1'' 3;;
(add1'' 4) + 7;; 
((fun x -> x + 1) 4) + 7;; (* can inline so function NEVER named; useful when passing one function to another *)
```

* Multiple argument functions - just leave s p a c e s between multiple arguments in both definitions and uses

```ocaml
let add x y = x + y;;
add 3 4;;
(add 3) 4;; (* same meaning as previous application -- two applications, " " associates LEFT *)
let add3 = add 3;; (* No need to give all arguments at once - !  
                      Type of add is int -> (int -> int) - "CURRIED" *)
add3 4;;
add3 20;;
(+) 3 4;; (* Putting () around any infix operator turns it into a 2-argument function *)
```

* Conclusion: `add` is a function taking an integer, and returning a **function** which takes ints to ints.
* So, add is a **higher-order function**: it returns a function as result.
* Other forms of higher-order function take functions as arguments (e.g. the math compose example `o`)

Observe `int -> int -> int` is parenthesized as `int -> (int -> int)` -- **right** associativity which is opposite of arithmetic operators

Be careful with operator precedence in the unusual way that function application doesn't need parens!
```ocaml
add3 (3 * 2);;
add3 3 * 2;; (* NOT the previous - this is the same as (add3 3) * 2 - application binds TIGHTER than `*` *)
add3 @@ 3 * 2;; (* LIKE the original - @@ is like " " for application BUT binds LOOSER than all other ops *)
```

* `=` is also a 2-argument function; it is somewhat strange in our `Core` OCaml on non-ints:
```ocaml
3.4 = 4.2;; (* errors, = only works on ints with the Core library in use *)
Float.(3.3 = 4.4);; (* Solution: use the Float module's = function for floats, "Float.(...)" opens it in the ... *)
```
* Why this apparent ugliness?  Pay a price here but reap rewards later of never having the wrong notion of `=`.

### Simple Structured Data Types: Option and Result

* Before getting into "bigger" data types like lists and trees, let's use one of the simplest structured data types, the `option` type.

```ocaml
Some 5;;
- : int option = Some 5
```

* All this does is "wrap" the 5 in the `Some` tag
* Observe the type is `int option`, it is "optionally an integer".

```ocaml
None;;
- : 'a option = None
```

 * Notice these are both in the `option` type .. either you have `Some` data or you have `None`.
 * `option` is similar to how you can have null or non-null objects in other languages, but it is more explicit.
 * These kinds of types with the capital-letter-named tags are called **variants** in OCaml; each tag wraps a different variant.
 * The `option` type is very useful; here is an oversimplified example.

 ```ocaml
# let nice_div m n = if n = 0 then None else Some (m / n);;
val nice_div : int -> int -> int option = <fun>
# nice_div 10 0;;
- : int option = None
# nice_div 10 2;;
- : int option = Some 5
```

* This allows an explicit failure value, `None`, to be propagated
* But, `None` is not like `NULL` -- you can't use `nice_div` directly in the place of `/`:

```ocaml
# (nice_div 5 2) + 7;;
Line 1, characters 0-14:
Error: This expression has type int option
       but an expression was expected of type int
```

* Notice the type of the return value of `nice_div`, it is `int option`, not `int`
* This type error is saying the `+` lhs needs to be type `int` but is a `Some` value which is not an `int`.

Here is a failed attempt at solving this problem:
 ```ocaml
# let not_nice_div m n = if n = 0 then None else m / n;;
Line 1, characters 47-52:
Error: This expression has type int but an expression was expected of type
         'a option
```
- The `then` and `else` branches must return the same type, here they do not: `int` and `int option` are disjoint types.

#### Using pattern matching to use `nice_div`

Here is how we can in fact use `nice_div`:
```ocaml
# match (nice_div 5 2) with 
   | Some i -> i + 7 (* the nice_div result is (Some 2) and i is bound to the 2 by this pattern *)
   | None -> failwith "This should never happen, we divided by 2";;
- : int = 9
```
* This shows how OCaml lets us *destruct* option values, via the `match` syntax.
* `match` is similar to `switch` in C/Java/.. but is much more flexible in OCaml
* The LHS in OCaml can be a general pattern which binds variables (the `i` here), etc

Moral from the above example
- Use of `option` can make a little more code but it is more exact/rigorous/debuggable than using a `NULL` value
- It also puts more information in the type itself -- a function returning `int option` tells the caller they need to case on it.

#### Result

A similar approach to the above is to use the `result` type, which like `option` but is specialized for error handling.

```ocaml
# let nicer_div m n = if n = 0 then Error "Divide by zero" else Ok (m / n);;
val nicer_div : int -> int -> (int, string) result = <fun>
```
* The `result` type is explicitly intended for this case of failure-result
    - `Ok` means the normal result
    - `Error` is the error case, which unlike `None` can include failure data, usually a string.

```ocaml
# match (nicer_div 5 2) with 
   | Ok i -> i + 7
   | Error s -> failwith s;;
- : int = 9
```

To complete the picture there is a third way to handle divide by zero, raise an exception:

```ocaml
let div_exn m n = if n = 0 then failwith "divide by zero is bad!" else m / n;;
div_exn 3 4;;
```

* This has the positive property of not needing a match on the result.  
* (Note that the built-in `/` also raises an exception.)
* But, exceptions are side effects though and we want to minimize their usage to avoid error-at-a-distance.
* The above examples show how exceptional conditions can either be handled via exceptions or in the return value; 
   - A key dimension of this course is this side effect vs direct passing trade-off
   - Many bugs, security leaks, etc are due to ignorance of side effects; the `Error/Ok` approach keeps them "in your face" by being in the return type
   - Also recall `Error/Ok` keeps us completely in math-land, the return result tells everything.  Exceptions are not math.

### Lists

* Finally we can use a real data structure to write some real programs
* Lists are the most common data structure in OCaml, similar to dictionaries/objects for Python/JavaScript.
* They are **immutable** so while they look something like arrays or vectors they most certainly are **not**

```ocaml
let l1 = [1; 2; 3];;
let l2 = ["a"; "b"; "c"];;
let l3 = [1; "a"];; (* error - All elements must have same type *)
let l5 = [];; (* the empty list *)
```

#### Building lists 

Lists are represented internally as **binary trees** with left child always a leaf.
```ocaml
let l0 = 0 :: l1;; (* "::" is 'consing' 0 to the top of the tree - fast *)
0 :: (1 :: (2 :: (3 :: [])));; (* equivalent to more concise [0;1;2;3] *)
[1; 2; 3] @ [4; 5];; (* appending lists - slower than `::`, needs to cons 3/2/1 on front of [4;5] *)
let z = [2; 4; 6];;
let y = 0 :: z;; (* in y, 0 is the *head* (first elt) of the list and z is the *tail* (rest of list) *)
z;; (* Observe z itself did not change -- recall lists are immutable in OCaml *)
```

Here is a picture of the trees used to internally represent `l1` and `l0` above:

<img src = "https://pl.cs.jhu.edu/pl/ocaml/List.png" width = 500>

#### Destructing Lists with pattern matching

* Here is a very simple example of how a list can be analyzed.
* This function gets the tail, the list without the first element.
* Key to analyzing lists is pattern matching via `match`, breaking list into head and tail portions

```ocaml
let tl_exn l =
  match l with
  |  [] -> invalid_arg "empty lists have no tail"
  |  hd :: tl -> tl  (* the pattern ht :: tl  binds hd to the first elt (left subtree), tl to ALL the others (right subtree) *)
;;
let l = [1;2;3];; 
let l' = tl_exn l;;
l;; (* Note: lists are immutable, so l didn't change *)
let l'' =  tl_exn l' (* To get tail of tail, take tail of l' ..  THREAD the state! *)
tl_exn [];; (* Raises an `invalid_arg` exception if the list had no tail *)
```

* Note that an alternative to avoid the exception effect is to return `Ok/Error`:

```ocaml
let tl l =
  match l with
  |  [] -> Error "empty list has no tail"
  |  hd :: tl -> Ok tl
;;
let l = [1;2;3];; 
let l' = tl l;;
tl [];;
let l'' = tl l' (* Oops this fails!  As in the div example above need to case on `Ok/Error` *)
```

### Recursive Functions on Lists

* For the first homework many of the programs you need to write work on list inputs.  
* Recursion is the key here.  
* Here is an example of how to get the nth element of a list, by walking along the list with recursion:

```ocaml
let rec nth_exn l n =
  match l with
  |  [] -> invalid_arg "there is no nth element in this list"
  |  hd :: tl -> if n = 0 then hd else nth_exn tl (n-1) (* "the nth element of l is the (n-1)-th element of tl" *)
;;
nth_exn [33;22;11] 1;;
nth_exn [33;22;11] 3;;
```

Key points

1. Pattern match on the list input: its either empty or is a head/tail pair
2. Recursively call the function on the tail of the list (plus other arguments): it **should work for shorter lists by induction**

Fortunately many common operations are already in the `List` module in the `Core` library:

```ocaml
# List.nth [1;2;3] 2;;
- : int option = Some 3
```
* This library uses the `option` type instead of raising an exception
* `List.nth_exn` raises an exception like ours does.  Both versions are useful.
   - (Note this function is also `Core.List.nth_exn` but we always `open Core;;` to make `Core` module functions implicitly available)
* On Assignment 1 you **cannot** use `List.` libraries, you first need to practice using `let rec`
   - On Assignment 2 you will start using the `List.` libraries.


### An Example of a function both taking and returning a list

* Goal: write a function to zero out all the negative elements in a list of integers
* C solution: `for`-loop over it and **mutate** all negatives to 0
* OCaml immutable list solution: recurse on list structure, construct a completely **new** list with the negative elements zeroed

```ocaml
let rec zero_negs l =
  match l with
  |  [] -> []
  |  hd :: tl -> (if hd < 0 then 0 else hd) :: zero_negs tl(* can assume by induction that zero_negs tl will properly zero tl *)
;;

zero_negs [1;-2;3];;
```

