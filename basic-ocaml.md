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

* We will be running many small incremental programs in lecture - best done in the top loop.
* We will always use the `utop` top loop, not the older `ocaml`
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
let squared x = x * x;; 
squared 4;; (* to call a function -- separate arguments with S P A C E S *)
```
 *  OCaml has no `return` statement; value of the whole body-expression is what gets returned
 *  Type is automatically **inferred** and printed as domain `->` range
 *  OCaml functions in fact always take only one argument - !  multiple arguments can be encoded by a trick (later)

#### Fibonacci series example - `0 1 1 2 3 5 8 13 ...` 

Let's write a well-known function with recursion and if-then-else syntax

```ocaml
let rec fib n =     (* the "rec" keyword needs to be added to allow recursion *)
  if n <= 0 then 0
  else if n = 1 then 1
  else fib (n - 1) + fib (n - 2);; (* notice again everything is an expression, no "return" *)

fib 10;; (* get the 10th Fibonacci number *)
```

#### Anonymous functions basics

* Key advantage of FP: functions are just expressions; put them in variables, pass and return from other functions, etc.
* Much of this course will be showing how this is useful, we are just getting started now

```ocaml
let add1 x = x + 1;; (* a normal add1 definition *)
let anon_add1 = (function x -> x + 1);; (* equivalent anonymous version; "x" is argument here *)
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

#### Pattern matching first example

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
   - the latter is the C approach but also the monadic approach as we will learn
   - a key dimension of this course is the side effect vs direct trade-off

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
* This function gets the head, the first element.

```ocaml
let hd l =
  match l with
  |  [] -> Error "empty list has no head"
  |  x :: xs -> Ok x (* the pattern x :: xs  binds x to the first elt, xs to ALL the others *)
;;
hd [1;2;3];;
hd [];;
```

* Lists are not random access like arrays; if you want to get the nth element, you need to work for it.

```ocaml
let rec nth l n =
  match l with
  |  [] -> failwith "no nth element in this list"
  |  x :: xs -> if n = 0 then x else nth xs (n-1)
;;
nth [33;22;11] 1;;
nth [33;22;11] 3;;
```

Fortunately many common operations are in the `List` module in the `Core` library:

```ocaml
# List.nth [1;2;3] 2;;
- : int option = Some 3
```
(This library uses the `option` type instead of raising an exception like we did)

#### Reversing a list

* Let us now write a somewhat more interesting function, reversing a list.
* Lists are immutable so it is going to create a completely new list, not change the original.
* This style of programming is called "Data structure corresponds to control flow" - the program needs to touch the whole data structure as it runs.

```ocaml
let rec rev l =
  match l with
  |  [] -> []
  |  x :: xs -> rev xs @ [x]
;;
rev [1;2;3];; (* recall input list is the tree 1 :: ( 2 :: ( 3 :: [])) *)
```

* Correctness of a recursive function by induction: assume recursive call does what you expect in arguing it is overall correct.
* For this example, can assume `rev xs` always reverses the tail of the list.
* Given that fact, `rev xs @ [x]` should clearly reverse the whole list.
* QED, the function is proved correct! (actually partially correct, this induction argument does not rule out infinite loops)

Of course this is also in `List` since it is a common operation:

```ocaml
# List.rev [1;2;3];;
- : int list = [3; 2; 1]
```

**Another Example: zero out all the negative elements in a list of numbers**

* Non-solution: `for`-loop over it and mutate all negatives to 0
* Immutable list solution: recurse on list structure, building the new list as we go

```ocaml
let rec zero_negs l =
  match l with
  |  [] -> []
  |  x :: xs -> (if x < 0 then 0 else x) :: zero_negs xs
in
zero_negs [1;-2;3];;
```

### Base/Core List library functions

* We already saw a few of these above, `List.rev` and `List.nth`.
* `List` is a module, which is the package-equivalent in OCaml.  It contains functions *plus* values *plus* types
* These functions we have available because they are actually `Base.List.rev` etc -- this denotes module `List` inside of module `Base`
* We have `Base` implicitly open because we opened `Core` and `Core` is a superset of `Base`
* Note that `List.hd` is also available, but you should nearly always be pattern matching to take apart lists; don't use `List.hd` on the homework.
* Let us [peek at the documentation for `List`](https://ocaml.janestreet.com/ocaml-core/latest/doc/base/Base/List/index.html) to see what is available; we will covrer a few of them now.

#### Some simple but very handy `List` library functions
```ocaml
List.length ["d";"ss";"qwqw"];;
List.is_empty [];;
List.last_exn [1;2;3];; (* get last element; raises an exception if list is empty *)
List.join [[1;2];[22;33];[444;5555]];;
List.append [1;2] [3;4];; (* Usually the infix @ syntax is used for append *)
```

* Let us code a few of these as exercises.

```ocaml
let rec join l = match l with
  | [] -> []
  | l :: ls -> l @ join ls (* " by induction assume join will turn list-of-lists to single list" *)
```

#### OCaml tuples and some `List` library functions using tuples

* Along with lists `[1;2;3]` OCaml has tuples, `(1,2.,"3")`
* It is like a fixed-length list, but elements can have different types
* You can also pattern match on them

```ocaml
# (1,2.,"3");;
- : int * float * string = (1, 2., "3")
```

* Here is a simple function to break a list in half using the `List.split_n` function

```ocaml
let split_in_half l = List.split_n l (List.length l / 2);;
split_in_half [2;3;4;5;99];;
```

* Now, using the `List.cartesian_product` function we can make all possible pairs of (front,back) elements

```ocaml
let all_front_back_pairs l = 
  let front, back = split_in_half l in List.cartesian_product front back;;
val all_front_back_pairs : 'a list -> ('a * 'a) list = <fun>
# all_front_back_pairs [1;2;3;4;5;6];;
- : (int * int) list =
[(1, 4); (1, 5); (1, 6); (2, 4); (2, 5); (2, 6); (3, 4); (3, 5); (3, 6)]
```

* Observe: lists of pairs are the same as pairs of lists (of the same length)
* zipping and unzipping library functions can convert between these two equivalent forms.

```ocaml
List.unzip @@ all_front_back_pairs [1;2;3;4;5;6];;
```

* Note the use of `@@` here, recall it is function application but with "loose binding", avoids parens
* Here is an even cooler way to write the same thing, with pipe operation `|>` (based on shell pipe `|`)

```ocaml
[1;2;3;4;5;6] |> all_front_back_pairs |> List.unzip;;
```
* In a series of pipes, the leftmost argument is data, and all the others are functions
* The data is fed into first function, output of first function fed as input to second, etc
* This is exactly what the shell `|` does with standard input / standard output.

* `List.zip` is the opposite of unzip:

```ocaml
List.zip [1;2;3] [4;5;6];;
- : (int * int) list List.Or_unequal_lengths.t =
Core.List.Or_unequal_lengths.Ok [(1, 4); (2, 5); (3, 6)]
```
* The strange result is dealing with the case where the lists supplied may not be same length
* This type and value are hard to read, let us take a crack at it.
* `((int * int) list) List.Or_unequal_lengths.t` is the proper parentheses.
* `List.Or_unequal_lengths.t` is referring to the type `t` found in the `List.Or_unequal_lengths` module (a small module within the `List` module)
* We can use the `#show_type` directive in the top loop to see what `t` actually is:
```ocaml
# #show_type List.Or_unequal_lengths.t;;
type nonrec 'a t = 'a List.Or_unequal_lengths.t = Ok of 'a | Unequal_lengths
```
The latter case is for zipping lists of different lengths:

```ocaml
List.zip [1;2;3] [4;5];;
- : (int * int) list List.Or_unequal_lengths.t =
Core.List.Or_unequal_lengths.Unequal_lengths
```

* In the original same-length case we got the result from the first clause in this type, `Core.List.Or_unequal_lengths.Ok [(1, 4); (2, 5); (3, 6)]`.
* They should have just used the `result` type here, these values and types are really ugly!!
* Note `List.zip_exn` will just raise an exception for unequal-length lists, avoiding all of this wrapper ugliness

#### zip/unzip and Currying

We should be able to zip and then unzip as a no-op, one should undo the other (we will use the `_exn` version to avoid the above error wrapper).

```ocaml
List.unzip @@ List.zip_exn [1;2] [3;4];;
```
And the reverse should also work as it is an isomorphism:

```ocaml
List.zip_exn @@ List.unzip [(1, 3); (2, 4)];;
Line 1, characters 16-43:
Error: This expression has type int list * int list
       but an expression was expected of type 'a list
```

* Oops! It fails.  What happened here?
* `List.zip_exn` takes two arguments, lists to zip, whereas `List.unzip` returns a *pair of lists*.
* No worries, we can write a wrapper turning `List.zip_exn` into a version taking a pair of lists:

```ocaml
let zip_pair (l,r) = List.zip_exn l r in 
zip_pair @@ List.unzip [(1, 3); (2, 4)];;
[(1, 3); (2, 4)] |> zip_pair |> List.unzip;; (* Pipe equivalent form *)
```
* Congratulations, we just wrote a fancy no-op function.
* The general principle here is a Curried 2-argument function like `int -> int -> int` is isomorphic to `int * int -> int`
* The latter form looks more like a standard function taking multiple arguments and is the **uncurried** form.
* And we sometimes need to interconvert between the two representations

#### `List` functions which take function arguments

* So far we have done the "easier" functions in `List`; the real meat are the functions taking other functions
* Lets warm up with `List.filter`: remove all elements not meeting a condition which we supply a function to check

```ocaml
List.filter [1;-1;2;-2;0] (fun x -> x >= 0);;
```

* Cool, we can "glue in" any checking function (boolean-returning, i.e. a *predicate*) and `List.filter` will do the rest
* Observe this function has type `'a list -> f:('a -> bool) -> 'a list` -- the `f` is a *named argument*, we can put args out of order if we give name via `~f:` syntax:
```ocaml
List.filter ~f:(fun x -> x >= 0) [1;-1;2;-2;0];;
```
* And, since OCaml functions are Curried we can leave off the list argument to make a generic remove-negatives function.
```ocaml
let remove_negatives = List.filter ~f:(fun x -> x >= 0);;
remove_negatives  [1;-1;2;-2;0];;
```

Let us use `filter` to write a function determining if a list has any negative elements:

```ocaml
let has_negs l = not (l |> List.filter ~f:(fun x -> x < 0) |> List.is_empty);;
```
This is a common operation so there is a library function for it as well: does there *exist* any element in the list where predicate holds?

```ocaml
let has_negs l = List.exists ~f:(fun x -> x < 0) l;;
```
Similarly, `List.for_all` checks if it holds for *all* elements.

#### List.map

* `List.map` is  super cool, apply some operation we supply to every element of a list:

```ocaml
# List.map ~f:(fun x -> x + 1) [1;-1;2;-2;0];;
- : int list = [2; 0; 3; -1; 1]
# List.map ~f:(fun x -> x >= 0) [1;-1;2;-2;0];;
- : bool list = [true; false; true; false; true]
```

#### Folding

* Observe the `for_all` and `exists` functions are just mapping over the predicate like in the previous, and inserting an "and" (for all) or an "or" (exists) between each list element.
* The `fold` library functions do that.  Here for example is `List.fold_right` at work 

```ocaml
let exists ~f l =  (* Note the ~f is declaring a named argument f, we were only using pre-declared ones above *)
  let bool_result_list = List.map ~f:f l in
  List.fold_right bool_result_list ~f:(||) ~init:false;;
# exists ~f:(fun x -> x >= 0) [-1;-2];;
- : bool = false
# exists ~f:(fun x -> x >= 0) [1;-2];;
- : bool = true
```

* The `~f`  parameter is the operation to put beetween list elements;
* The `~init` is needed because it is a binary operator
* For `fold_right` the `~init` is on the right:

```ocaml
# List.fold_right ~f:(||) ~init:false [true; false];; (* this is true || (false || (false)), the final false the ~init *)
- : bool = true
```

* `List.fold_left` aka `List.fold` puts the `~init` on the left:
```ocaml
# List.fold_left ~f:(||) ~init:false [true; false];; (* this is false || (true || false), the FIRST false the ~init *)
- : bool = true
```

* Note that in this case folding left or right gives the same answer; that is because `||` is *commutative and associative*, so e.g. `true || (false || (false) = false || (true || false)`.


