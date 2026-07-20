## List programming

Let's warm up by writing a few more recursive functions on lists.

#### Reversing a list

* Since lists are immutable, reverse will create a completely new list.
* This style of programming is called "Data structure corresponds to control flow" - the program needs to touch and reconstruct the whole data structure as it runs.
* (If you have not heard of the term "control flow" its how the program counter is moving through memory -- the flow of the focus of execution)

```ocaml
let rec rev l =
  match l with
  |  [] -> []
  |  hd :: tl -> rev tl @ [hd]
;;
rev [1;2;3];; (* recall this list is 1 :: [2;3] which is the tree 1 :: ( 2 :: ( 3 :: [])) *)
```

* Correctness of a recursive function follows by induction: assume recursive call does what you expect in arguing it is overall correct.
* For this example, can assume `rev tl` always reverses the tail of the list,  
    - (e.g. in computing `rev [1;2;3]` we match `hd` = `1` and `tl` = `[2;3]` and can assume `rev [2;3]` = `[3;2]` )
* Given that fact, the code `rev tl @ [hd]` should clearly reverse the whole list 
    - (e.g. `rev [2;3] @ [1] = [3;2] @ [1]` = `[3;2;1]`)
* QED, the function is proved correct! (actually partially correct, this induction argument does not rule out infinite loops)

`rev` is also in `List` since it is a common operation:

```ocaml
# List.rev [1;2;3];;
- : int list = [3; 2; 1]
```

### List library functions

* We already saw a few of these previously, e.g. `List.rev` and `List.nth`.
* `List` is a **module**, think fancy package.  It contains functions *plus* values *plus* types *plus* even other modules
* (Note that `List.hd/List.tl` are also available, but you should nearly always be pattern matching to take apart lists; don't use `List.hd/List.tl` on the homework.)
* (Also, read the homeworks carefully, on A1 you *cannot* use `List...` functions and on some questions of A2 you *must* use the `List...` functions.)
* Let us peek at the documentation [`List`](https://ocaml.org/manual/5.5/api/List.html) to see what is available; we will cover a few of them now.

#### Some handy `List` library functions

```ocaml
List.length ["d";"ss";"qwqw"];;
List.is_empty [];;
List.concat [[1;2]; [1;2;3]];; (* joins all elements in a list of lists into one list *)
List.append [1;2] [3;4];; (* Note you should use the more convenient infix @ syntax for listappend *)
```
#### ... And their types

* Types of functions are additional hints to their purpose, get used to reading them
* Much of the time when you mis-use a function you will get a type error
* Recall that `'a list` etc is a polymorphic aka generic type, `'a` can be *any* type

  ```ocaml
  # List.length;;
  - : 'a list -> int = <fun> (* "for ANY type 'a, List.length will take a list of 'a and return an integer" *)
  # List.is_empty;;
  - : 'a list -> bool = <fun>
  # List.concat;;
- : 'a list list -> 'a list = <fun>
  # List.append;;
  - : 'a list -> 'a list -> 'a list = <fun>
  # List.map;;  (* Foreshadowing; we will review this function below *)
  - : ('a -> 'b) -> 'a list -> 'b list = <fun> (* takes in a function! *)
  ```

* We coded `nth` and `rev` previously; here is one more, `concat`:


  ```ocaml
  let rec concat (l: 'a list list) = match l with
    | [] -> [] (* "joining together a list of no-lists is an empty list" *)
    | l :: ls -> l @ concat ls (* by induction assume (concat ls) will turn a list-of-lists into a single list *)
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

* Here is a simple function to break a list in half, returning a pair of lists
  - uses `List.take` (take the front part of the list up to the nth position) and 
  - uses `List.drop` (list after nth position).

  ```ocaml
  let divide_in_half (l : 'a list) : 'a list * 'a list = 
    let half = List.length l / 2 in 
    (List.take half l, List.drop half l);;
  divide_in_half [2;3;4;5;99;6];;
  ```

* Fact: pairs-of-lists are isomorphic to lists-of-pairs (of the same length)
* combining and splitting library functions can convert between these two equivalent forms.

#### combine/split and Currying

The library function for combining two lists into a single list of pairs is `List.combine`:
```ocaml
# List.combine;;
- : 'a list -> 'b list -> ('a * 'b) list = <fun>
```

* Recall this function of two arguments is in Curried form so if we try the following it fails:

```ocaml
List.combine ([1;2;3],[4;5;6]);;
```

* What happened here?  It was wanting us to instead write `List.combine [1;2;3] [4;5;6]`
* `List.combine` takes two curried arguments, lists to combine (its type is `'a list -> 'b list -> ('a * 'b) list `).
* No worries, we can write a wrapper (an *adapter*) turning `List.combine` into a version taking a pair of lists:

```ocaml
let combine_pair (l1,l2) = List.combine l1 l2;;
```

Now we can use our function to combine two lists into a list of pairs:

  ```ocaml
  combine_pair @@ divide_in_half [1;2;3;4;5;6];; (* returns a list-of-pairs *)
  ```

* Note the use of `@@` here, recall it is function application but with "loosest binding", avoids need for parens
* Here is a cooler way to write the same thing, with pipe operation `|>` (based on shell pipe `|`)

  ```ocaml
  [1;2;3;4;5;6] |> divide_in_half |> combine_pair;;
  ```
* In a series of pipes, the leftmost argument is data, and all the others are functions
* The data is fed into first function, output of first function fed as input to second, etc
  - its like an *assembly line* for building the result
* This is exactly what the shell `|` does with standard input / standard output.
* Please use pipes *as much as possible* on Assignment 2 - it will make the code more readable

* `List.split` is the opposite of combine: take a list of pairs and make a pair of lists:

  ```ocaml
  List.split [(1, 4); (2, 5); (3, 6)];;
  - : int list * int list = ([1; 2; 3], [4; 5; 6])
  ```

We can now show how combining and splitting is a no-op:

```ocaml
[(1, 3); (2, 4)] |> List.split |> combine_pair ;;  (* no-op! *)
([1; 2; 3], [4; 5; 6]) |> combine_pair |> List.split;; (* another no-op! *)
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

Note that the built-in `Pair.fold` is the same as `uncurry` (there is oddly no `curry` in the library).

We can now use our uncurrying combinator to build `combine_pair` directly:

```ocaml
let combine_pair  = Pair.fold List.combine;; (* Pair.fold is uncurry *)
```

#### One last higher-order function: compose

Composition function g o f: take two functions, return their composition

```ocaml
let compose g f = (fun x -> g (f x));;
compose (fun x -> x + 3) (fun x -> x * 2) 10;;
```

* The type says it all again, `('a -> 'b) -> ('c -> 'a) -> 'c -> 'b`
* Equivalent ways to code `compose` in OCaml:


```ocaml
let compose g f x =  g (f x);;
let compose g f = (fun x -> g(f x));; (* this equivalent form reads more how you think of the "o" operation in math *)
let compose = (fun g -> (fun f -> (fun x -> g(f x))));;
let compose g f x =  x |> f |> g;; (* This is the readability winner: feed x into f and f's result into g *)
```

* We can express the no-op split/combine composition with `compose`:

```ocaml
# (compose combine_pair List.split) [(1, 3); (2, 4)];;
- : (int * int) list = [(1, 3); (2, 4)]
```


#### `List` functions which take function arguments

* So far we have done the "easier" functions in `List`; the real meat are the functions taking other functions
* Think of these as "recursion patterns", they will recurse over the list so you don't have to `let rec`
  - makes functional code a lot easier to read once you are familiar with these "recursion combinators"
* Lets warm up with `List.filter`: remove all list elements not meeting a condition which we supply a function to check

```ocaml
List.filter (fun x -> x >= 0) [1;-1;2;-2;0];;
```

* Cool, we can "glue in" any checking function (boolean-returning, i.e. a *predicate*) and `List.filter` will do the rest
* We can also just supply the function, this often makes us a desirable new function:

```ocaml
let remove_negatives = List.filter (fun x -> x >= 0);;
remove_negatives  [1;-1;2;-2;0];;
```

Note that you can either inline the function as an anonymous `fun` or can declare it in advance:
```ocaml
let gtz x = x >= 0;;
List.filter gtz [1;-1;2;-2;0];;
```
Usually for short functions it is better to inline them as it is more concise


Let us use `filter` to write a function determining if a list has any negative elements:

```ocaml
let has_negs l = l |> List.filter (fun x -> x < 0) |> List.is_empty |> not;;
```
 * The example shows the power of pipelining, it is easier to see the processing order with `|>`
 * This is a common operation so there is a library function for it as well: does there *exist* any element in the list where predicate holds?

```ocaml
let has_negs l = List.exists (fun x -> x < 0) l;;
```
Similarly, `List.for_all` checks if it holds for *all* elements.

#### List.map

* `List.map` is very powerful, apply some operation we supply to every element of a list making a new list:

```ocaml
# List.map (fun x -> x + 1) [1;-1;2;-2;0];;
- : int list = [2; 0; 3; -1; 1]
# List.map (fun x -> x >= 0) [1;-1;2;-2;0];;
- : bool list = [true; false; true; false; true]
List.map (fun (x,y) -> x + y) [(1,2);(3,4)];; (* turns list of number pairs into list of their sums *)
List.map (uncurry (+)) [(1,2);(3,4)];; (* equivalent: its an uncurried add function that is needed *)
```

### Folding

* OK, so far we have been cruising along on impulse power; its now time for warp speed!
* The most powerful list combinators are the folds: `fold_right`, and `fold_left`. 
* They "fold together" list data using an operator.
* Think of `fold` as something you feed a "base case" and "recursive case" code to, and it makes a recursive function for you.
  - this recursive function will make one recursive call on the tail of the list
* Here for example is how we can turn a list of characters into a string with `fold_right`

  ```ocaml
  List.fold_right (fun elt -> fun accum -> (Char.escaped elt)^accum) ['a';'b';'c'] "";; (* computes "a"^("b"^("c"^"")) *)
  ```

* The base case is argument `""`
* the function is how we plug in the code for the recursive call
  - `elt` is the current element of the list
  - `accum` is going to be the result of recursing on the tail of the list (a string here)

Before showing potential code for `List.fold_right` let's manually implement `char_list_to_string` with `let rec` to compare.

```ocaml
let rec char_list_to_string l =
  match l with 
  | [] -> "" (* initial value above is this "", plug it in as the base case *)
  | elt :: elts ->  (* as in the above we are calling the current list element `elt` *)
    let accum = char_list_to_string elts in (* this is also what `accum` is above, the result of recursing on the tail *)
    (Char.escaped elt)^accum (* same as the body of f above, the calculation done on accum and elt *)
```


* OK now lets code `fold_right` by taking the above code and making the `""` and `(Char.escaped elt)^accum`  explicit parameters `init` and `f` respectively.
* (since the code `(Char.escaped elt)^accum` refers to `elt` and `accum` we also need to make them parameters, `f` will be `fun elt accum -> (Char.escaped elt)^accum`)

```ocaml
let rec fold_right f l init =
  match l with
  | [] -> init
  | elt :: elts -> 
    let accum = fold_right f elts init in 
    f elt accum
```

 - If we now plug in `""` for `init` and `(fun elt accum -> (Char.escaped elt)^accum)` for `f` we get `char_list_to_string` above.

 ```ocaml
fold_right (fun elt -> fun accum -> (Char.escaped elt)^accum) ['a';'b';'c'] "" ;;
```

 - Aside: observe how we have to keep forwarding `f` and `init` down the recursion to keep them available; we could have instead made an aux function without those:

```ocaml
let fold_right l f init =
  let rec folder_aux l = 
    match l with
    | [] -> init
    | elt :: elts -> 
      let accum = folder_aux elts in 
        f elt accum in
  folder_aux l
```

Here is another simple right fold to summate an integer list
```ocaml
List.fold_right (fun elt accum -> elt + accum) [3; 5; 7] 0;;  (* this computes 3 + (5 + (7 + 0))  *)
```
which more concisely could be written as

```ocaml
List.fold_right (+) [3; 5; 7] 0;;
```

#### Left folding 

* There is another way to fold: left fold!
* Notice in the above summate example the zero is on the right; that is why that is a right fold
* We could have instead summated as `((0 + 3) + 5) + 7`, with the zero on the *left* which is a fold left.
* `List.fold_left` is the function, and it has synonym `List.fold` which is because by default you should fold left for efficiency.

```ocaml
List.fold_left (fun accum elt -> accum + elt) 0 [3; 5; 7];; (* this is ((0 + 3) + 5) + 7 *)
```

* Here since it is a fold left the accumulator is on the *left* (compare with folding right above)
  - the arguments to `f` are swapped to make that more clear
* Note that for `f` being addition, folding left or right gives the same answer; 
    - but, that is only because `+` happens to be *commutative and associative*.
* For example, `List.fold_left (-) 0 [1;2]` is `(0 - 1) - 2` is `-3` and `List.fold_right (-) [1;2] 0` is `1 - (2 - 0)` is `-1` 

Let us understand how left folding differs by again looking at an implementation for the char list to string function.

```ocaml
let rec char_list_to_string l accum = (* invariant: accum is the accumulated result thus far *)
  match l with 
  | [] -> accum (* we are totally done at this point, `accum`` is the final result and just pop pop pop *)
  | elt :: elts -> 
    char_list_to_string elts (accum^(Char.escaped elt));;  (* we are computing the `f` to accumulate result on the way *down* the recursion *)
char_list_to_string ['a';'d'] "";; (* we need to prime the accum pump with "" here *)
```

Here is the general `fold_left`, pulling out the `f` in the above as a parameter.  
Note that the `accum` we call `init` here since that is the exterior interface.

```ocaml 
let rec fold_left f init l =
  match l with
  | [] -> init
  | elt::elts -> fold_left f (f init elt) elts (*observe f is invoked **before** the call -- accumulating left-first *)
```
#### Summarize by looking at the types

* The type of `List.fold_left` is `('acc -> 'a -> 'acc) -> 'acc -> 'a list -> 'acc`
   - The `'a` here is the type of the list elements
   - The `'acc` is the type of the result being accumulated
* The type of `List.fold_right` is `('a -> 'acc -> 'acc) -> 'a list -> 'acc -> 'acc`
  - (Notice that the arguments to `f` are swapped here compared to the `fold` left version)

#### More fold examples

* Folding can encapsulate most simple recursions over lists, so it can implement many of the library functions.
* We can for example implement `List.exists` above with map and fold:

```ocaml
let exists f l =
  l
  |> List.map f
  |> List.fold_left (||) false;; (* the List.map output is a list of booleans, just fold them up here *)
# exists (fun x -> x >= 0) [-1;-2];;
- : bool = false
# exists (fun x -> x >= 0) [1;-2];;
- : bool = true
```

In fact we can do this in one pass with just a fold:
```ocaml
let exists f l = 
  List.fold_left (fun accum elt -> accum || f elt) false l;;
```

Which hints that `map` itself is definable with a `fold`; we accumulate a new *list* here:
```ocaml
let map f l = List.fold_left (fun accum elt -> accum @ [f elt]) [] l
```

If you wanted to use `fold_right` to build map it would be similar:
```ocaml
let map_right f l = List.fold_right (fun elt accum -> (f elt) :: accum) [] l;;
```
Note that `map_right` is much more efficient, `::` takes unit time and `@` is linear in size of left list.

#### Folding and efficiency

Let us review left vs right folding and reflect on efficiency.  Here are two implementations similar to the above ones:

```ocaml
let rec fold_right f l init =
  match l with
  | [] -> init
  | hd::tl -> f hd (fold_right f tl init) (* observe it is invoking f **after** the recursive call *)
```
vs

```ocaml 
let rec fold_left f init l =
  match l with
  | [] -> init
  | hd::tl -> fold_left f (f init hd) tl (*observe f is invoked **before** the call -- accumulating left-first *)
```

* Note that the first parameter to f in `fold_left` is the accumulated value passed *down* and the second parameter is the current list value
* In `fold_right` on the other hand the `f` computation happens *after* the recursive call is complete.
* Fold left/right are good example contrasts of how you can accumulate a value up (`fold_right`) vs down (`fold_left`) the recursion

`fold_left` is in fact more efficient than `fold_right` so it is preferred all things being equal:
 - Observe how the value of the `fold_left` function above is what is directly returned from the base case, it bubbles all the way out
 - Such a function is *tail recursive*: there is *no work to do* after the (sole) recursive call finishes
 - The compiler doesn't need to use a call stack for such functions since nothing happens upon return
   - there is nothing it needs to mark as a point to go back to
   - so, it replaces push/pop with jumps in and one jump out when done -- its just a loop.
 - Important when lists get really long that you don't use stack unless required.
 - Observe that `fold_right` is not tail recursive, so it needs the stack and will be slower

### Named arguments

* OCaml has been switching over to using *named arguments* in some libraries.
* Named arguments allow you to switch around the order of arguments
* They also make the code easier to follow when there are multiple args (e.g. folds)
* For lists there is a parallel library `ListLabels` which has the same functions but with named arguments.

```ocaml
ListLabels.map ~f:(fun x -> x * x) [1;5;3;45]
ListLabels.fold_left ~f:(fun accum _ -> accum + 1) ~init:0 [1;2;2345;43]
ListLabels.fold_left [1;2;2345;43] ~init:0 ~f:(fun accum _ -> accum + 1) (* can swap order *)
ListLabels.fold_left (fun accum _ -> accum + 1) 0 [1;2;2345;43] (* can leave off names *)
(* writing your own functions with named arguments: *)
let rec fold_left ~f ~init l =
  match l with
  | [] -> init
  | hd::tl -> fold_left ~f ~init:(f init hd) tl
let swap ~(x : int) ~(y : int) : int * int = (y,x) in swap ~x:5 ~y:4
```