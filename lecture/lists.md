## List programming
* First we will do a few more recursive functions over lists
* Then we will show how the `Core.List` library functions allow a great many (most?) operations to be written without recursion
* This is *combinator programming*, solve a task by composing operations on a few standard combinators ("combiners")
* (Note for Assignment 1 Part I you will not be able to use the library combinators, they are for Part II)

#### Reversing a list

* Let us write a somewhat more interesting function, reversing a list.
* Lists are immutable so it is going to create a completely new list, not change the original.
* This style of programming is called "Data structure corresponds to control flow" - the program needs to touch and reconstruct the whole data structure as it runs.

```ocaml
let rec rev l =
  match l with
  |  [] -> []
  |  hd :: tl -> rev tl @ [hd]
;;
rev [1;2;3];; (* recall input list is the tree 1 :: ( 2 :: ( 3 :: [])) *)
```

* Correctness of a recursive function by induction: assume recursive call does what you expect in arguing it is overall correct.
* For this example, can assume `rev tl` always reverses the tail of the list,  
    - (e.g. in computing `rev [1;2;3]` we match `hd` = `1` and `tl` = `[2;3]` and can assume `rev [2;3]` = `[3;2]` )
* Given that fact, `rev tl @ [hd]` should clearly reverse the whole list 
    - (e.g. `[3;2] @ [1]` = `[3;2;1]` for the example)
* QED, the function is proved correct! (actually partially correct, this induction argument does not rule out infinite loops)

Of course `rev` is also in `Core.List` since it is a common operation:

```ocaml
# List.rev [1;2;3];;
- : int list = [3; 2; 1]
```

**Another Example: zero out all the negative elements in a list of numbers**

* C solution: `for`-loop over it and mutate all negatives to 0
* OCaml immutable list solution: recurse on list structure, building the new list as we go

```ocaml
let rec zero_negs l =
  match l with
  |  [] -> []
  |  hd :: tl -> (if hd < 0 then 0 else hd) :: zero_negs tl
in
zero_negs [1;-2;3];;
```

### Core.List library functions

* We already saw a few of these previously, e.g. `List.rev` and `List.nth`.
* `List` is a **module**, think fancy package.  It contains functions *plus* values *plus* types *plus* even other modules
* `List` is itself in the module `Core` so the full name for `rev` is `Core.List.rev`
    * but we put an `open Core` in our `.ocamlinit` (and in the template for A1) so you can just write e.g. `List.rev`
* (Note that `List.hd` is also available, but you should nearly always be pattern matching to take apart lists; don't use `List.hd` on the homework.)
* Let us peek at the documentation [`Core.List`](https://ocaml.org/p/core/v0.15.0/doc/Core/List/index.html) to see what is available; we will cover a few of them now.

#### Some simple but very handy `List` library functions

```ocaml
List.length ["d";"ss";"qwqw"];;
List.is_empty [];;
List.last_exn [1;2;3];; (* get last element; raises an exception if list is empty *)
List.join [[1;2];[22;33];[444;5555]];;
List.append [1;2] [3;4];; (* Usually the infix @ syntax is used for append *)
```
#### ... And their types

* The types of the functions are additional hints to their purpose, get used to reading them
* Much of the time when you mis-use a function you will get a type error
* Recall that `'a list` etc is a polymorphic aka generic type, `'a` can be *any* type

```ocaml
# List.length;;
- : 'a list -> int = <fun>
# List.is_empty;;
- : 'a list -> bool = <fun>
# List.last_exn;;
- : 'a list -> 'a = <fun>
# List.join;;
- : 'a list list -> 'a list = <fun>
# List.append;;
- : 'a list -> 'a list -> 'a list = <fun>
# List.map;;  (* We will do this one below *)
- : 'a list -> f:('a -> 'b) -> 'b list = <fun>
```

* We coded `nth` and `rev` before, here is one more, `join`:

```ocaml
let rec join (l: 'a list list) = match l with
  | [] -> [] (* "joining together a list of no-lists is an empty list" *)
  | l :: ls -> l @ join ls (* "by induction assume (join ls) will turn list-of-lists to single list" *)
```

#### OCaml tuples and some `List` library functions using tuples

* Along with lists `[1;2;3]` OCaml has tuples, `(1,2.,"3")`
* It is like a fixed-length list, but tuple elements **can have different types**
* You can also pattern match on tuples

```ocaml
# (1,2.,"3");;
- : int * float * string = (1, 2., "3")
# [1,2,3];; (* a common error, parens not always needed so this is a singleton list of a 3-tuple, not a list of ints *)
- : (int * int * int) list = [(1, 2, 3)]
```

* Here is a simple function to break a list in half using the `List.split_n` function
    - a pair of lists is returned by `split_n`, dividing it at the nth position

```ocaml
let split_in_half l = List.split_n l (List.length l / 2);;
split_in_half [2;3;4;5;99];;
```

* Now, using the `List.cartesian_product` function we can make all possible pairs of (front,back) elements
  - (Also observe how these OCaml combinators have overlap with math combinators we already knew)

```ocaml
let all_front_back_pairs l = 
  let front, back = split_in_half l in 
    List.cartesian_product front back;; (* observe how let can itself pattern match pairs *)
val all_front_back_pairs : 'a list -> ('a * 'a) list = <fun>
# all_front_back_pairs [1;2;3;4;5;6];;
- : (int * int) list =
[(1, 4); (1, 5); (1, 6); (2, 4); (2, 5); (2, 6); (3, 4); (3, 5); (3, 6)]
```

* Fact: lists of pairs are isomorphic to pairs of lists (of the same length)
* zipping and unzipping library functions can convert between these two equivalent forms.

```ocaml
List.unzip @@ all_front_back_pairs [1;2;3;4;5;6];;
```

* Note the use of `@@` here, recall it is function application but with "loosest binding", avoids need for parens
* Here is an even cooler way to write the same thing, with pipe operation `|>` (based on shell pipe `|`)

```ocaml
[1;2;3;4;5;6] |> all_front_back_pairs |> List.unzip;;
```
* In a series of pipes, the leftmost argument is data, and all the others are functions
* The data is fed into first function, output of first function fed as input to second, etc
* This is exactly what the shell `|` does with standard input / standard output.
* Please use pipes as much as possible on Part II of Assignment 1 - will make the code more readable

* `List.zip` is the opposite of unzip: take two lists and make a single list pairing elements

```ocaml
List.zip [1;2;3] [4;5;6];;
- : (int * int) list List.Or_unequal_lengths.t =
Core.List.Or_unequal_lengths.Ok [(1, 4); (2, 5); (3, 6)]
```
* The strange result is dealing with the case where the lists supplied may not be same length
* This type and value are hard to read, let us take a crack at it.
* `((int * int) list) List.Or_unequal_lengths.t` is the proper parentheses.
* `List.Or_unequal_lengths.t` is referring to the type `t` found in the `List.Or_unequal_lengths` module (a small module within the `List` module)
  - one of the great things about modules is they can also contain types (like C .h files but more principled)
* We can use the `#show_type` directive in the top loop to see what `t` actually is:

```ocaml
# #show_type List.Or_unequal_lengths.t;;
type nonrec 'a t = 'a List.Or_unequal_lengths.t = Ok of 'a | Unequal_lengths
```
* This means the value is either `Ok(..)` or `Unequal_lenghts`, very similar to `result`
* The `'a` here is the type parameter, more on those later so don't sweat it now
* The latter case is for zipping lists of different lengths:

```ocaml
List.zip [1;2;3] [4;5];;
- : (int * int) list List.Or_unequal_lengths.t =
Core.List.Or_unequal_lengths.Unequal_lengths
```

* In the original same-length case we got the result from the first clause in this type, `Core.List.Or_unequal_lengths.Ok [(1, 4); (2, 5); (3, 6)]`.
* Note `List.zip_exn` will just raise an exception for unequal-length lists, avoiding all of this wrapper ugliness
    - but in larger programs we want to avoid exceptions at a distance so it is often worth the suffering

#### zip/unzip and Currying

We should be able to zip and then unzip as a no-op, one should undo the other (we will use the `_exn` version to avoid the above error wrapper issue).

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
* `List.zip_exn` takes two curried arguments, lists to zip (its type is `'a list -> 'b list -> ('a * 'b) list `), whereas `List.unzip` returns a *pair of lists*.
* No worries, we can write a wrapper (an *adapter*) turning `List.zip_exn` into a version taking a pair of lists:

```ocaml
let zip_pair (l,r) = List.zip_exn l r in 
zip_pair @@ List.unzip [(1, 3); (2, 4)];;
[(1, 3); (2, 4)] |> List.unzip|> zip_pair ;; (* Pipe equivalent form *)
```
* Congratulations, we just wrote a fancy no-op function 😁
* The general principle here is a *curried* 2-argument function like `int -> int -> int` is **isomorphic** to `int * int -> int`
* The latter form looks more like a standard function taking multiple arguments and is the **uncurried** form.
* And we sometimes need to interconvert between the two representations
* This conversion is called *uncurrying* (curried to pair/triple/etc form) or *currying* (putting it into curried form)

#### Curry/Uncurry are themselves functions
* We can even write combinators which generically convert between these two forms - !
* `curry`   - takes in uncurried 2-arg function and returns a curried version
* `uncurry` - takes in curried 2-arg function and returns an non-curried version

```ocaml
let curry f = fun x -> fun y -> f (x, y);;
let uncurry f = fun (x, y) -> f x y;;
```
Observe the types themselves in fact fully define their behavior:

```ocaml
curry : ('a * 'b -> 'c) -> 'a -> 'b -> 'c
uncurry : ('a -> 'b -> 'c) -> 'a * 'b -> 'c
```

We can now use our new combinator to build `zip_pair` directly:

```ocaml
let zip_pair  = uncurry @@ List.zip_exn;;
```

#### One last higher-order function: compose

Composition function g o f: take two functions, return their composition

```ocaml
let compose g f = (fun x -> g (f x));;
compose (fun x -> x+3) (fun x -> x*2) 10;;
```

* The type says it all again, `('a -> 'b) -> ('c -> 'a) -> 'c -> 'b`
* Equivalent ways to code `compose` in OCaml:


```ocaml
let compose g f x =  g (f x);;
let compose g f x =  x |> f |> g;; (* This is the readability winner: feed x into f and f's result into g *)
let compose = (fun g -> (fun f -> (fun x -> g(f x))));;
```

* We can express the Zip/unzip composition explicitly with `compose`:

```ocaml
# (compose zip_pair List.unzip) [(1, 3); (2, 4)];;
- : (int * int) list = [(1, 3); (2, 4)]
```


#### `List` module functions which take function arguments

* So far we have done the "easier" functions in `List`; the real meat are the functions taking other functions
* Lets warm up with `List.filter`: remove all elements not meeting a condition which we supply a function to check

```ocaml
List.filter [1;-1;2;-2;0] (fun x -> x >= 0);;
```

* Cool, we can "glue in" any checking function (boolean-returning, i.e. a *predicate*) and `List.filter` will do the rest
* Observe `List.filter` has type `'a list -> f:('a -> bool) -> 'a list` -- the `f:` is declaring a *named argument*, we can put args out of order if we give name via `~f:` syntax:

```ocaml
List.filter ~f:(fun x -> x >= 0) [1;-1;2;-2;0];;
```
* And, since OCaml functions are Curried we can leave off the list argument to make a generic remove-negatives function.

```ocaml
let remove_negatives = List.filter ~f:(fun x -> x >= 0);;
remove_negatives  [1;-1;2;-2;0];;
```

Note that you can either inline the function as a `fun` or can declare it in advance:
```ocaml
let gtz x = x >= 0;;
List.filter ~f:gtz [1;-1;2;-2;0];;
```
Usually for short functions it is better to inline them, it makes the code more readable.


Let us use `filter` to write a function determining if a list has any negative elements:

```ocaml
let has_negs l = l |> List.filter ~f:(fun x -> x < 0) |> List.is_empty |> not;;
```
 * The example shows the power of pipelining, it is easier to see the processing order with `|>`
 * This is a common operation so there is a library function for it as well: does there *exist* any element in the list where predicate holds?

```ocaml
let has_negs l = List.exists ~f:(fun x -> x < 0) l;;
```
Similarly, `List.for_all` checks if it holds for *all* elements.

#### List.map

* `List.map` is  super powerful, apply some operation we supply to every element of a list:

```ocaml
# List.map ~f:(fun x -> x + 1) [1;-1;2;-2;0];;
- : int list = [2; 0; 3; -1; 1]
# List.map ~f:(fun x -> x >= 0) [1;-1;2;-2;0];;
- : bool list = [true; false; true; false; true]
List.map ~f:(fun (x,y) -> x + y) [(1,2);(3,4)];; (* turns list of number pairs into list of their sums *)
```

### Folding
* Some of the most powerful combinators are the folds: `fold_right`, and `fold_left` aka simply `fold`. 
* They "fold together" list data using an operator.
* Here for example is how we can summate all elements in a list using `fold_right`

```ocaml
# List.fold_right ~f:(+) ~init:0 [3; 5; 7];; (* this computes 3 + (5 + (7 + 0))  *)
- : int = 15
```

* The `~f`  parameter is the binary operation to put between list elements, `+` in this example;
* The `~init` is needed because `+` is a binary operator so an initial value is needed to fold for 0/1 length lists
* For `fold_right` the `~init` is on the **right**, that is why it is called a "fold **right**"
* For the list `[1;2;3]`, `fold_right [1;2;3] ~f ~init` generally computes `f 1 (f 2 (f 3 init))`
* In general, `fold_right [a1; ...; an] ~f ~init` computes `f a1 (f a2 (... (f an init) ...))`.

#### Left folding 
* `List.fold_left` aka `List.fold` (use the latter syntax) puts the `~init` on the left:

```ocaml
# List.fold ~f:(+) ~init:0 [3; 5; 7];; (* this is ((0 + 3) + 5) + 7 *)
- : int = 15
```

* For list `[1;2;3]`, `fold [1;2;3] ~init ~f` generally computes `f (f (f init 1) 2) 3`
* In general, `fold [e1;...;en] ~init ~f` computes `f (... f (f (f init e1) e2) e3 ...) en`

* Note that in the case above folding left or right gives the same answer; 
    - that is because `+` is *commutative and associative*.
* But e.g. `List.fold ~f:(-) ~init:0 [1;2]` is `(0 - 1) - 2` is `-3` and `List.fold_right ~f:(-) ~init:0 [1;2]` is `1 - (2 - 0)` is `-1` 

#### Folds over more general functions, not just operators

* The type of `List.fold` is `'a list -> init:'accum -> f:('accum -> 'a -> 'accum) -> 'accum`
* Note how the two parameters of `f` need not be the same type
* The `'a` here is the type of the list elements
* The `'accum` is the type of the result being accumulated, which *could be different* than the type of list elements

Here is a simple fold example where these types are different (here `'a` is `string` and `'accum` is `int`):

```ocaml
List.fold ["a";"b";"c"] ~init:0 ~f:(fun accum -> fun elt -> accum + 1);;`
```

* Recall using the above expansion that this `fold` computes `f (f (f 0 "a") "b") "c"` 
where `f` is `(fun accum -> fun elt -> accum + 1)`
* Parameter `elt` is the list *element* and `accum` is the *accumulator*, the result thus far.
* Let us incrementally compute the above: `f 0 "a"` is going to throw away the `"a"` and return `0+1` so it is `1`.
* this result `1` is then the first parameter to `f` in the next call, `f (1) "b"` - it is the `accum`-ulated value.
* each call to `f` returns accum incremented by one and in the end we have computed the length of the initial list.

We can also compute length with `fold_right`:
```ocaml
List.fold_right ["a";"b";"c"] ~init:0 ~f:(fun elt -> fun accum -> accum + 1);;`
```

* Notice that the arguments to `f` are swapped here compared to the `fold` left version
   * in `fold` `f` should be a `fun accum elt -> ...` of type `('accum -> 'a -> 'accum)` and 
   * in `fold_right` it should be `fun elt accum -> ...` of type `('a -> 'accum -> 'accum)`

#### A few more fold examples

Here is more general use of `fold` where the accumulator is a different type than the list elements:

```ocaml
let map l ~f = List.fold ~f:(fun accum elt -> accum @ [f elt]) ~init:[] l
```

This function is identical to `List.map` described above.  We can also implement `List.exists` above with fold:

```ocaml
let exists l ~f =  (* Note: ~f is **declaring** a named argument f *)
  List.map ~f l    (* ~f as an argument is shorthand for ~f:f *)
  |> List.fold ~f:(||) ~init:false;;
# exists ~f:(fun x -> x >= 0) [-1;-2];;
- : bool = false
# exists ~f:(fun x -> x >= 0) [1;-2];;
- : bool = true
```

#### Folding and efficiency

Here is possible code for `fold_right` to help understand it:

```ocaml
let rec fold_right ~f l ~init =
  match l with
  | [] -> init
  | hd::tl -> f hd (fold_right ~f tl ~init)
```

Code for `fold` aka `fold_left`:

```ocaml 
let rec fold l ~init ~f =
  match l with
  | [] -> init
  | hd::tl -> fold tl ~init:(f init hd) ~f
```

* Note that the first parameter to f in `fold` is the accumulated value passed *down* and the second parameter is the current list value
* In `fold_right` on the other hand the `f` computation happens *after* the recursive call is complete.
* Fold left/right are good example contrasts of how you can accumulate a value up (`fold_right`) vs down (`fold`) the recursion

`fold` is in fact more efficient than `fold_right` so it is preferred all things being equal:
 - Observe how the value of the `fold` function above is what is directly returned from the recursion
 - Such a function is *tail recursive*
 - The compiler doesn't need to use a call stack for such functions since nothing happens upon return
 - Important when lists get really long that you don't use stack unless required.
 - Observe that `fold_right` is not tail recursive, so it needs the stack and will be slower

#### `fold_until`

* Let us end on perhaps the most powerful `List` combinator of all, `fold_until`.
* This is an extention to `fold` adding the functionality of `break` of C etc looping but in a functional style.

```ocaml
let summate_til_zero l =
  List.fold_until l ~init:0
    ~f:(fun acc i -> match i, acc with
        | 0, sum -> Stop sum
        | _, sum -> Continue (i + sum))
    ~finish:Fn.id
let stz_example = summate_til_zero [1;2;3;4;0;5;6;7;8;9;10]
```

* The `Stop` variant is like break, here take `sum` as the final value
* `Continue` wraps the continue-folding case, which adds `i` to running `sum` here.
* `~finish` can post-process the result if the `Stop` case was not hit; `Fn.id` is `fun x -> x`, no additional processing here.