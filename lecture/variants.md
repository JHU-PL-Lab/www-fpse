### Variants

* Variants build or-data (this-or-this-or-this); records build and-data (this-and-this-and-this)
* All data combination is fundamentally either *and* or *or*, similar to the fundamental operators of boolean logic.
* We start with variants (or), and then do records (and) next.

### Variants
* The `option` and `result` types we have been using are simple forms of *variant types*
* Variants let your data be one of several forms (either-or), with a label wrapping the data indicating the specific form
* They are related to `union` types in C or `enums` in Java, but are more safe than C and more general than Java
* Like lists and tuples they are by default immutable

Example variant type for doing mixed arithmetic (integers and floats)

```ocaml
type ff_num = Fixed of int | Floating of float;;  (* read "|" as "or" *)

Fixed 5;; (* tag 5 as a Fixed *)
Floating 4.0;; (* tag 4.0 as a Floating *)
```

 * Each case of the variant is wrapped with a *constructor* which serves for both
      - constructing values of the variant type
      - inspecting them by pattern matching
 * Constructors must start with a Capital Letter to distinguish from variables
 * Variants must be declared but once declared type inference can infer them.
 * The `of` indicates what type is under the wrapper
 * (Note constructors look like functions but they are **not** -- you always need to give the argument)

```ocaml
let ff_as_int x =
    match x with
    | Fixed n -> n    (* pattern match like with option/list/result - those types are also variants *)
    | Floating z -> int_of_float z;;

ff_as_int (Fixed 5);;
```

A function using the above variant type

```ocaml
let ff_add n1 n2 =
   match n1, n2 with    (* note use of pair here to parallel-match on two variables  *)
     | Fixed i1, Fixed i2 -> Fixed (i1 + i2)
     | Fixed i1, Floating f2 ->  Floating(float i1 +. f2) (* need to coerce *)
     | Floating f1, Fixed i2 -> Floating(f1 +. float i2)  (* ditto *)
     | Floating f1, Floating f2 -> Floating(f1 +. f2)
;;

ff_add (Fixed 123) (Floating 3.14159);;
```

* No data item?  leave off the `of`.
* Multiple data items in a single variant clause?  Wrap with a tuple (or record once we cover them):

```ocaml
type complex = CZero | Nonzero of float * float;;

let com = Nonzero(3.2,11.2);;
let zer = CZero;;
let ocaml_annoyance = Fn.id Nonzero(3.2,11.2);; (* this is a parsing error, it views as (Fn.id Nonzero)(3.2,11.2) *)
let ocaml_annoyance = Fn.id @@ Nonzero(3.2,11.2);; (* so use @@ instead of " " *)
```

#### An Example of Variants plus List. libraries

* Lets write Hamming distance calculator for DNA
* Goal beyond using variants is to cover some useful OCaml programming patterns.
* `[@@deriving equal]` in the below is a *macro* (called a "ppx extension" in OCaml) 
* It automatically generates a function `equal_nucleotide` (`equal_the-types-name-here` in general)
* You will need to use this with `Core` since regular `=` will not work on `nucleotide`s.

```ocaml
(* Example derived from 
   https://exercism.io/tracks/ocaml/exercises/hamming/solutions/afce117bfacb41cebe5c6ebb5e07e7ca
 *)

type nucleotide = A | C | G | T

let combine_opt l r = try Some(List.combine l r) with _ -> None

let hamming_distance (left : nucleotide list) (right : nucleotide list) : ((int, string) result)=
  match combine_opt left right with (* this returns Some list or None *)
  | None -> Error "left and right strands must be of equal length"
  | Some l ->
    l
    |> List.filter (fun (a,b) -> not (equal_nucleotide a b))
    |> List.length 
    |> fun x -> Ok(x) (* Unfortunately we can't just pipe to `Ok` since `Ok` is not a function in OCaml - make it one here *)

let hamm_example = hamming_distance [A;A;C;A;T;T] [A;A;G;A;C;T]
```
Now let's use `fold_left` instead of `filter`/`length`
```ocaml
let hamming_distance (left : nucleotide list) (right : nucleotide list) : ((int, string) result)=
  match combine_opt left right with
  | None -> Error "left and right strands must be of equal length"
  | Some l ->
    l
    |> List.fold_left (fun accum (a,b) -> accum + if (equal_nucleotide a b) then 0  else 1) 0 
    |> fun x -> Ok(x)
```
#### Parametric variant types
We have used several of these but have not looked at the type too carefully.

Here is the system's declaration of the `option` type -- the `#show_type` top loop directive (or just `#show`) will print it:
```ocaml
# #show_type option;;
type 'a option = None | Some of 'a
```
* The `'a` here is a *parameter*, which gets filled in by a concrete type to make an actual type.
* e.g. `Some("hello") : string option` -- the `string` fills in the parameter `'a`
* `None : 'a option` type means instantiate the `'a` parameter with polymorphic/generic `'a`
* This may have been more clear if OCaml used function notation for these types, e.g.
   `type option('a) = None | Some of 'a` and  `Some("hello") : option(string)`

And here is `result`:
```ocaml
# #show_type result;;
type ('a, 'b) result = ('a, 'b) result = Ok of 'a | Error of 'b
```

 * Same idea but *a pair* of type parameters; `'b` is the type of the `Error`.
 * Observe `Ok(4) : (int, 'a) result` and `Error("bad") : ('a, string) result`

#### Recursive data structures 
  - A common use of variant types is to build recursive data structures (trees)
  - Functional programming is fantastic for computing over tree-structured data
  - Recursive types can refer to themselves in their own definition
     - similar in spirit to how C structs can be recursive (but, no pointers needed here)
  - Unlike with functions, no need for `rec`

 - Homebrew lists `lizt` as a warm-up - the built-in `list` type is in fact not needed
   - Note this example is just for understanding, use the built-in lists if you just want lists.

```ocaml
type 'a lizt = Mt | Cons of 'a * 'a lizt;; (* the recursive "'a lizt" on the rhs is a lizt of 'a *)
let lizt_eg = Cons(3,Cons(5,Cons(7,Mt)));; (* analogous to 3 :: 5 :: 7 :: [] = [3;5;7] *)
```
Coding over lizts is nearly identical to built-in lists; here is mapping:

```ocaml
let rec lizt_map (f : 'a -> 'b) (ml : 'a lizt) : ('b lizt) =
  match ml with
    | Mt -> Mt
    | Cons(hd,tl) -> Cons(f hd,lizt_map f tl)

let map_eg = lizt_map (fun x -> x - 1) (Cons(3,Cons(5,Cons(7,Mt)))) 
```

Lets look at the built-in `list` type:
```ocaml
# #show_type list;;
type 'a list = [] | (::) of 'a * 'a list
```
This is the exact same structure as `lizt`

### Binary trees

* Binary trees are like lists but with two self-referential sub-structures instead of one
* Here is a tree with data in the intermediate *nodes* but not in the leaves.

```ocaml
type 'a bin_tree = Leaf | Node of 'a * 'a bin_tree * 'a bin_tree
```

Here are some simple example trees

```ocaml
let bt0 = Node("whack!",Leaf, Leaf);;
let bt1 = Node("fiddly ",
            Node("backer ",
               Leaf,
               Node("crack ",
                  Leaf,
                  Leaf)),
            bt0);;

let bt2 = Node("fiddly ",
            Node("backer ",
               Leaf,
               Node("crack ",
                  Leaf,
                  Leaf)),
            bt0);;
(* Type error, like list, must have uniform type: *)
Node("fiddly",Node(0,Leaf,Leaf),Leaf);;
```

#### Combinators for Binary Trees

* Since lists are built-in we get a massive library of functions on them.
* For these binary trees (and in general for whatever variant types you roll yourself) there is no such luxury.
  - This is because there is no single canonical form of tree, there are many different kinds of trees used
* **Still**, that doesn't mean you should just code everything by recursing over the tree.  Instead
   1. Define the combinators you need (maps, folds, node counts, etc.) using `let rec`
   2. Use your combinators without needing `let rec`

* Here is a simple recursive function over binary trees:
```ocaml
let rec add_gobble binstringtree =
   match binstringtree with
   | Leaf -> Leaf
   | Node(y, left, right) ->
       Node(y^"gobble",add_gobble left,add_gobble right)
```

 * (Remember, as with lists this is not mutating the tree, its building a new one)
 * Observe: this is an instance of the general operation of building a tree with same structure but applying an operation on each node value
 * i.e. it is a **map** operation over a tree.  Let us code `map` and use it to add gobbles.

```ocaml
let rec map (f : 'a -> 'b) (tree : 'a bin_tree) : ('b bin_tree) =
   match tree with
   | Leaf -> Leaf
   | Node(y, left, right) ->
       Node(f y,map f left,map f right)

(* using tree map to make a non-recursive add_gobble *)
let add_gobble tree = map (fun s -> s ^ "gobble") tree
```
* Fold is also natural on binary trees, apply operation f to node value and each subtree result.
  - This is a fold right (post-processed), folding left on a tree isn't sensible because there are two subtrees to go down in to.

```ocaml
let rec fold (f : 'a -> 'acc -> 'acc -> 'acc) (tree : 'a bin_tree)  (leaf : 'acc) : 'acc =
   match tree with
   | Leaf -> leaf
   | Node(y, left, right) ->
       f y (fold f left leaf) (fold f right leaf)

(* using tree fold *)
let int_summate tree = fold (fun elt laccum raccum -> elt + laccum + raccum) tree 0;;
int_summate @@ Node(3,Node(1,Leaf,Node(2,Leaf,Leaf)),Leaf);;
(* fold can also do map-like operations - the folder can return a tree *)
let inc_nodes tree = fold (fun elt la ra -> Node(elt+1,la,ra)) Leaf tree;;
```

* Many of the other `List` functions have analogues on binary trees and recursive variants in general
   - `length` (`size` or `depth` for a tree), `forall`, `exists`, `filter` (filter out a subtree), etc etc.

* For some operations we need to know how to compare the tree elements 
   - we will use the built-in `<=` which is fine on simple types but not on Maps etc.
   - Beware!

```ocaml
let rec insert (x : 'a) (bt : 'a bin_tree) : ('a bin_tree) =
   match bt with
   | Leaf -> Node(x, Leaf, Leaf)
   | Node(y, left, right) ->
       if x <= y then Node(y, insert x left, right)
       else Node(y, left, insert x right)
;;
```

* Like list operations this is not mutating -- it returns a whole new tree.
* **But**, recall for lists that if we have a list `l` then `0 :: l` can share the `l` due to immutability
* So, for here, only one path through tree is not shared: on average only log n new nodes need to be made.  [More later in lecture on efficiency](efficiency.html).

```ocaml
let bt' = insert 4 bt;;
let bt'' = insert 0 bt';; (* thread in the most recent tree into subsequent insert *)
```

#### Comparisons

* Always be careful about what the meaning of `=`, `<`, `<=` etc are
* For lists, variants, integers, strings, floats, chars the built-in meaning is fine
* But for types list `Map`s, hashtables, etc the default equality can be not what you mean
* So, library functions needing to compare reliably will in fact take a comparision operation as argument
* For example in the `List` library, the [`List.sort` function](https://ocaml.org/manual/5.5/api/List.html#VALsort)
* Here is an example of how to sort a string list with `List.sort`:

```ocaml
List.sort (String.compare) ["Zoo";"Hey";"Abba"];; (* pass string's comparison function as argument *)
(* insight into OCaml expected behavior for compare: *)
# String.compare "Ahh" "Ahh";; (* =  returns 0 : equal *)
- : int = 0
# String.compare "Ahh" "Bee";; (* < returns -1 : less *)
- : int = -1
# String.compare "Ahh" "Ack";; (* > returns 1 : greater *)
- : int = 1
```

So, our more general tree insert should follow the lead of `List.sort`:

```ocaml
let rec insert compare x bt  =
   match bt with
   | Leaf -> Node(x, Leaf, Leaf)
   | Node(y, left, right) ->
       if (compare x y) <= 0 then Node(y, insert compare x left, right)
       else Node(y, left, insert compare x right)
;;
let bt' = insert (Int.compare) 4 bt ;;
```

* The built-in equality `(=)` and built-in compare, `compare` in fact work fine on all standard types and their compositions. 
* All of the data types we have used thus far, e.g. our `bin_tree` they compare well on.
* But they don't accurately compare `Map`, `Set`, `Hashtbl`, `Queue`, `Stack` and others.  
* Its dangerous because they don't give an exception they give a perhaps incorrect answer.
* Also it raises an exception when trying to compare functions.

Here is an example of how `Set` comparison is not what you want:
```ocaml
module S = Set.Make(Int) (* This is how you set up an int set; covered later *)

let s1 =  S.empty |> S.add 1 |> S.add 2 (* the set {1, 2} *)
let s2 =  S.empty |> S.add 2 |> S.add 1 (* the set {1, 2} again *)
let _ = s1 = s2 (* returns false but they are the same set - ! *)
let _ = compare m1 m2;; (* the second one is considered "greater" due to internal rep'n *)
```
The reason is sets are implemented as binary search trees and the order of addition affects the tree structure which is what `=` compares.


#### Solution if you want to properly compare Set etc
* For sets in particular there is a better one built-in: `S.equal s1 s2` returns `true`.
  - (why doesn't `=` invoke that?  Good question, its an historical oddity)
* Making your own definition of compare/equal is also possible
* To define equality more easily you can also use a ppx extension, a form of macro for OCaml
 - Use library `ppx_deriving.eq` and append `[@@deriving eq]` to automatically define function `equal_mytype` for your type `mytype`
 - Use library `ppx_deriving.ord` and append `[@@deriving ord]` will define function `compare_mytype`.
 - Appending `[@@deriving eq, ord]` will get you both

Here is an example of using these in the top loop to define equality on trees:
```ocaml
#require "ppx_deriving.eq";; (* loads the extension into utop *)
#require "ppx_deriving.ord";; (* ditto *)
type 'a tree = Leaf | Node of 'a * 'a tree * 'a tree [@@deriving ord, eq];;
```
produces output
```ocaml
type 'a tree = Leaf | Node of 'a * 'a tree * 'a tree
val compare_tree : ('a -> 'a -> int) -> 'a tree -> 'a tree -> int = <fun>
val equal_tree : ('a -> 'a -> bool) -> 'a tree -> 'a tree -> bool = <fun>
```
* This defines these functions for you that will compare trees.  
* For example, `compare_tree compare (Node (4,Leaf,Leaf)) (Leaf)` returns 1, it considers the left tree smaller since `Leaf` was listed first in the variant.
* Notice that we need to pass in a comparison function for the underlying data in the tree (integers); here we just pass in the default comparison.
* Note that `compare (Node (4,Leaf,Leaf)) (Leaf)` also returns 1 since this is a simple type.
* To use these macros in a dune project add `(preprocess (pps ppx_deriving.eq))` or `(preprocess (pps ppx_deriving.ord))` to your dune file.

### Polymorphic Variants Very Briefly

* OCaml has an additional form of variant which has different syntax and is overlapping in uses: *polymorphic variants*
* A better term would be "inferred variants" - you don't need to declare them via `type`.

```ocaml
# `Zinger(3);; (* prefix constructors with a backtick for the inferred variants *)
- : [> `Zinger of int ] = `Zinger 3
```
* This looks a bit useless, it inferred a 1-ary variant type
* But the "`>`" in the type means *there could be other variants showing up in the future*.

```ocaml
# let f b = if b then [`Zinger 3] else [`Zanger "hi"];;
val f : bool -> [> `Zanger of string | `Zinger of int ] list = <fun>
```

* We can of course pattern match as well:

```ocaml
# let zing_zang z = 
match z with
| `Zinger n -> "zing! "^(Int.to_string n)
| `Zanger s -> "zang! "^s
val zing_zang : [< `Zanger of string | `Zinger of int ] -> string = <fun>
```
Observe how the type now has a `<` instead of a `>`; the meaning is it is those fields or *fewer*.

```ocaml
# zing_zang @@ `Zanger "wow";;
- : string = "zang! wow"
# zing_zang @@ `Zuber 1.2;;
Line 1, characters 13-23:
Error: This expression has type [> `Zuber of float ]
       but an expression was expected of type
         [< `Zanger of string | `Zinger of int ]
       The second variant type does not allow tag(s) `Zuber
```

* Generally you should use the non-polymorphic form by default
* The main advantage of the polymorphic form is sharing tags amongst different types
   - regular variants like `Ok(4)` *must* be in only one type, `result` for `Ok` in `Core`
   - variants like `` `Zanger "f"`` can be in ``[> `Zanger of string ]``, ``[> `Zanger of string | `Zinger of int ]``, etc
   - really OCaml should just have one form; the two forms are historical baggage.
