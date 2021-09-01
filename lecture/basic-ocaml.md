## Introduction to OCaml

(see the file [basic-ocaml.ml](basic-ocaml.ml) if you want all of the ml examples in this file extracted out)
### Installing

 * See [the Coding page](https://pl.cs.jhu.edu/fpse/coding.html) for install instructions and lots of other information.  
 * Make sure to use the required 4.12.0 version of OCaml, install the libraries listed via `opam`, and change your `.ocamlinit` file as mentioned on this page.
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

* The above is the **top loop** aka **read-eval-print** view of OCaml.  You should know this from Python/Javascript/shell/etc.
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

* `dune` is the modern `make`/`Makefile` equivalent for OCaml.
* In same directory, add a file `dune`:
```scheme
(executable
  (name helloworld)
  (modules helloworld)
)
```
* This is the **build file**, specifying how to compile/test/run the program.
* Now, type `dune build` to compile a standalone program like we did above but letting `dune` invoke the compiler.
* Then, run with `dune exec ./helloworld.exe`

#### Adding a Library

* Let's make printing less primitive: use a `Core` library function, `printf`
* Replace printing with line `Core.printf "the string is %s\n" hw`
* Try building - gives an error
* Add line `(libraries core)` to dune file to fix -- all library dependencies must be listed in the dune file
* Compile and run

### Exploring Basic Data in utop

* We will be running many small incremental programs in lecture - best done in the top loop.
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
1 = 2;; (* = not == for equality comparison; note = works on ints only in our OCaml setup *)
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
let squared x = x * x;; (* returns     val squared : int -> int = <fun>     *)
squared 4;; (* to call a function -- separate arguments with S P A C E S *)
```
 *  OCaml has no `return` statement; value of the whole body-expression is what gets returned
 *  Type is automatically **inferred** and printed as domain `->` range; `int -> int` here.
 *  OCaml functions in fact always take only one argument - !  multiple arguments can be encoded (covered later)

#### Fibonacci series example - `0 1 1 2 3 5 8 13 ...` 

Let's write a well-known function with recursion and if-then-else syntax

```ocaml
let rec fib n =     (* the "rec" keyword needs to be added to allow recursion *)
  if n <= 0 then 0
  else if n = 1 then 1
  else fib (n - 1) + fib (n - 2);; (* notice again everything is an expression, no "return" *)

fib 10;; (* get the 10th Fibonacci number; 2^10 steps so don't make input too big! *)
```

Nested conditionals as above are generally avoided in OCaml since they are not so readable.  For example here is an easier to read `fib` using pattern match notation similar to Java/C `switch` which we will cover in detail later:

```ocaml
let rec fib = function 
  | 0 -> 0 
  | 1 -> 1 
  | n -> fib (n - 1) + fib (n - 2);;
```
#### Anonymous (aka un-named) functions

* Key feature of FP: functions are just expressions; put them in variables, pass and return from other functions, etc.
* Much of this course will be showing how this is useful

```ocaml
let add1 x = x + 1;; (* a normal add1 definition *)
add1 3;;
let anon_add1 = (function x -> x + 1);; (* equivalent to above; "x" is argument here *)
anon_add1 3;;
(anon_add1 4) + 7;; 
((function x -> x + 1) 4) + 7;; (* can inline anonymous function definition *)
((fun x -> x + 1) 4) + 7;; (*  shorthand notation -- cut off the "ction" *)
```

* Multiple arguments - just leave s p a c e s between multiple arguments in both definitions and uses

```ocaml
let add x y = x + y;;
add 3 4;;
(add 3) 4;; (* same meaning as previous application -- two applications, " " associates LEFT *)
let add3 = add 3;; (* No need to give all arguments at once!  Type of add is int -> (int -> int) - "CURRIED" *)
add3 4;;
add3 20;;
(+) 3 4;; (* Putting () around any infix operator turns it into a 2-argument function *)
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

* `=` is also a 2-argument function; it is somewhat strange in our `Core` OCaml on non-ints:
```ocaml
3.4 = 4.2;; (* errors, = only works on ints with the Core library in use *)
Float.(=) 3.3 4.4;; (* Solution: use the Float module's = function for floats *)
```
* Why this apparent ugliness?  Pay a price here but reap rewards later of having the right notion of `=`.
### Simple Structured Data Types: Option and Result

* Before getting into "bigger" data types and how to declare our own, let's use one of the simplest structured data types, the built-in `option` type.

```ocaml
Some 5;;
- : int option = Some 5
```

* All this does is "wrap" the 5 in the `Some` tag

```ocaml
None;;
- : 'a option = None
```

 * Notice these are both in the `option` type .. either you have `Some` data or you have `None`.
 * `option` is similar to how you can have null or non-null objects in other languages, but it is explicit here.
 * These kinds of types with the capital-letter-named tags are called **variants** in OCaml; each tag wraps a different variant.
 * The `option` type is very useful; here is a super simple example.

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

This type error means the `+` lhs should be type `int` but is a `Some` value which is not an `int`.

Here is a non-solution to that:
 ```ocaml
# let not_nice_div m n = if n = 0 then None else m / n;;
Line 1, characters 47-52:
Error: This expression has type int but an expression was expected of type
         'a option
```
- The `then` and `else` branches must return the same type, here they do not.
- The `int` and `int option` types have no overlap of members!  Generally true across OCaml.
- `null` or similar value can sneak in to a type in other languages, but no such sneaking in OCaml.

#### Using pattern matching to use `nice_div`

Here is a real solution to the above issue:
```ocaml
# match (nice_div 5 2) with 
   | Some i -> i + 7 (* i is bound to the result, 2 here *)
   | None -> failwith "This should never happen, we divided by 2";;
- : int = 9
```
* This shows how OCaml lets us *destruct* option values, via the `match` syntax.
* `match` is similar to `switch` in C/Java/.. but is much more flexible in OCaml
* The LHS in OCaml can be a general pattern which binds variables (the `i` here), etc
* Note that we turned `None` into a runtime exception via `failwith`.

#### Result

An "even nicer" version of the above would be to use the `result` type, which is very similar to `option` but is specialized just for error handling.

```ocaml
# let nicer_div m n = if n = 0 then Error "Divide by zero" else Ok (m / n);;
val nicer_div : int -> int -> (int, string) result = <fun>
```
* The `result` type is explicitly intended for this case of failure-result
    - `Ok` means the normal result
    - `Error` is the error case, which unlike none can include failure data, usually a string.
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

* This has the property of not needing a match on the result.  
* Note that the built-in `/` also raises an exception.
* Exceptions are side effects though, we want to minimize their usage to avoid error-at-a-distance.
* The above examples show how exceptional conditions can either be handled via exceptions or in the return value; 
   - A key dimension of this course is this side effect vs direct trade-off
   - Many bugs, security leaks, etc are due to ignorance of side effects; the `Error/Ok` approach keeps them "in your face" as a programmer

### Lists

* Lists are pervasive in OCaml
* They are **immutable** so while they look something like arrays or vectors they are not

```ocaml
let l1 = [1; 2; 3];;
let l2 = [1; 1+1; 1+1+1];;
let l3 = ["a"; "b"; "c"];;
let l4 = [1; "a"];; (* error - All elements must have same type *)
let l5 = [];; (* empty list *)
```

#### Building lists 

Lists are represented internally as **binary trees** with left child a leaf.
```ocaml
0 :: l1;; (* "::" is 'consing' 0 to the top of the tree - fast *)
0 :: (1 :: (2 :: (3 :: [])));; (* equivalent to [0;1;2;3] *)
[1; 2; 3] @ [4; 5];; (* appending lists - slower, needs to cons 3/2/1 on front of [4;5] *)
let z = [2; 4; 6];;
let y = 0 :: z;;
z;; (* Observe z itself did not change -- recall lists are immutable in OCaml *)
```

#### Destructing Lists with pattern matching

* Before writing real programs here is a simple example of pattern matching on a list.
* This function gets the tail, the list without the first element.

```ocaml
let tl_exn l =
  match l with
  |  [] -> invalid_arg "empty lists have no tail"
  |  x :: xs -> Ok xs  (* the pattern x :: xs  binds x to the first elt, xs to ALL the others *)
;;
let l = [1;2;3];; 
let l' = tl_exn l;;
l;; (* IMPORTANT: lists are immutable, l didn't change!! *)
let l'' =  tl_exn l' (* So to get tail of tail, take tail of l' not 2 x tail of l!  THREAD the state! *)
tl_exn [];; (* Raise an exception if the list had no tail *)
```

* An alternative to avoid the exception effect is to return `Ok/Error`:

```ocaml
let tl l =
  match l with
  |  [] -> Error "empty list has no tail"
  |  x :: xs -> Ok xs
;;
let l = [1;2;3];; 
let l' = tl l;;
tl [];;
let l'' = tl l' (* Oops this fails!  As in the div example above need to case on `Ok/Error` *)
```

* Lists are not random access like arrays; if you want to get the nth element, you need to work for it.

```ocaml
let rec nth_exn l n =
  match l with
  |  [] -> invalid_arg "there is no nth element in this list"
  |  x :: xs -> if n = 0 then x else nth_exn xs (n-1)
;;
nth_exn [33;22;11] 1;;
nth_exn [33;22;11] 3;;
```

Fortunately many common operations are already in the `List` module in the `Core` library:

```ocaml
# List.nth [1;2;3] 2;;
- : int option = Some 3
```
* This library uses the `option` type instead of raising an exception like we did
* `List.nth_exn` raises an exception like ours does.  Both versions are useful.
* Note on the HW you can use libraries on some questions but not others, read instructions.


