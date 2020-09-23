### Variants

* Variants build or-data (this or this or this); records build and-data (this and this and this)
* They are the fundamental data constructors
* We start with variants

### Variants
* The `option` and `result` types we have been using are simple forms of *variant types*
* Variants let your data be one of several forms (either-or), with a label wrapping the data indicating the sort
* They are related to `union` types in C or `enums` in Java, but are more safe and more general
* Like OCaml lists and tuples they are by default immutable

Example variant type for doing mixed arithmetic (integers and floats)

```ocaml
type ff_num = Fixed of int | Floating of float;;  (* read "|" as "or" *)

Fixed(5);; (* tag 5 as a Fixed *)
Floating 4.0;; (* tag 4.0 as a Floating *)
```

 * Each case of the variant is wrapped with a 'Constructor' which serves for both
      - Constructing values of the variant type
      - inspecting them by pattern matching
 * Constructors must start with a Capital Letter to distinguish from variables
 * Variants must be declared but once declared type inference can infer them.
 * The `of` indicates what type is under the wrapper
 * Note constructors look like functions but they are **not** -- you always need to give the argument

```ocaml
let ff_as_int x =
    match x with
    | Fixed n -> n    (* variants fit well into pattern matching syntax *)
    | Floating z -> int_of_float z;;

ff_as_int (Fixed 5);;
```

A non-trivial function using the above variant type

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
* Multiple data items in a single variant clause?  Wrap with a tuple:

```ocaml
type complex = CZero | Nonzero of float * float;;

let com = Nonzero(3.2,11.2);;
let zer = CZero;;
let annoyance = Fn.id Nonzero(3.2,11.2);; (* common parsing error here; use @@ instead of " " *)
```

#### An Example of Variants plus List. libraries

* Here is a small Hamming distance calculator for DNA.
* Observe the `[@@deriving eq]`, this is a *macro* (called a "ppx extension" in OCaml) 
* It automatically generates a function `equal_nucleotide` (`equal_the-types-name-here` in general)
* You will need to use this with `Core` since `=` will not work on `nucleotide`s.

```ocaml
(* Example derived from 
   https://exercism.io/tracks/ocaml/exercises/hamming/solutions/afce117bfacb41cebe5c6ebb5e07e7ca
   This code needs a #require "ppx_deriving.eq";; in top loop to load ppx extension for @@deriving eq 
   Or, in a dune file it will need   (preprocess (pps ppx_deriving.eq)) added to the library decl *)

type nucleotide = A | C | G | T [@@deriving eq]

let hamming_distance left right =
  match List.length left, List.length right with
  | x, y when x <> y -> Error "left and right strands must be of equal length" (* "when" allows additional constraints *)
  | _ -> Ok (List.length (List.filter ~f:(fun (a,b) -> not (equal_nucleotide a b)) (* _ is wild card match *)
                                      (List.zip_exn left right))) (* We already know this never fails - OK to _exn *)

let hamm_example = hamming_distance [A;A;C;A;T;T] [A;A;G;A;C;T]
```

#### Parametric variant types

Here is the system's declaration of the `option` type -- the `#show_type` top loop directive will print it:
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
  - A common use of variant types: self-referential ones
  - Functional programming is fantastic for computing over tree-structured data
  - Recursive types can refer to themselves in their own definition
     - similar in spirit to how C structs can be recursive (but, no pointers needed here)
  - Unlike with functions, no need for `rec` (in fact can use `nonrec` to let OCaml know it is *not* recursive)

Homebrew lists as a warm-up - the built-in `list` type is in fact not needed

```ocaml
type 'a homebrew_list = Mt | Cons of 'a * 'a homebrew_list;;
let hb_eg = Cons(3,Cons(5,Cons(7,Mt)));; (* analogous to [3;5;7] *)
```
Coding over homebrew lists is basically identical to built-in lists.

```ocaml
let rec map ml ~f:f =
  match ml with
    | Mt -> Mt
    | Cons(hd,tl) -> Cons(f hd,map tl ~f)

let map_eg = map hb_eg ~f:(fun x -> x -1)
```

Lets look at the built-in `list` type:
```ocaml
# #show_type list;;
type 'a list = [] | (::) of 'a * 'a list
```
Looks very similar to our homebrew one, eh??

### Binary trees

* Binary trees are like lists but with two self-referential sub-structures instead of one
* Binary trees also show how arbitrary recursive variants work; same idea but more variants.
* Here is a tree with data in the *nodes* but not the leaves.

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

#### Operations on Binary Trees

* Since lists are built-in we get a massive library of functions on them.
* For these binary trees (and in general for whatever variants you roll up yourselves) there is no such luxury.
* **But**, that doesn't mean you should just code everything by recursing over the tree.  Instead
   1. Define the combinators you need (maps, folds, node counts, etc.) using `let rec`
   2. Use your combinators without needing `let rec`

* Here is a simple recursive function over binary trees for example:
```ocaml
let rec add_gobble binstringtree =
   match binstringtree with
   | Leaf -> Leaf
   | Node(y, left, right) ->
       Node(y^"gobble",add_gobble left,add_gobble right)
```

 * Remember, like with lists this is not mutating the tree, its building a new one
 * Observe: this is an instance of the general operation of building a tree with same structure but applying an operation on each node value
 * i.e. it is a **map** operation over a tree.  Let us code it.

```ocaml
let rec map tree ~f =
   match tree with
   | Leaf -> Leaf
   | Node(y, left, right) ->
       Node(f y,map ~f left,map ~f right)

(* using tree map to make a non-recursive add_gobble *)
let add_gobble tree = map ~f:(fun s -> s ^ "gobble") tree
```
* Fold is also natural on binary trees, apply operation f to node value and each subtree result.

```ocaml
let rec fold tree ~f ~leaf =
   match tree with
   | Leaf -> leaf
   | Node(y, left, right) ->
       f y (fold ~f ~leaf left) (fold ~f ~leaf right)

(* using tree fold *)
let int_summate tree = fold ~f:(fun y -> fun ls -> fun rs-> y + ls + rs) ~leaf:0 tree;;
let bt = Node(3,Node(1,Leaf,Node(2,Leaf,Leaf)),Leaf);;
int_summate bt;;
(* fold can also do map-like operations - the folder can return a tree *)
let bump_nodes tree = fold ~f:(fun y -> fun ls -> fun rs-> Node(y+1,ls,rs)) ~leaf:Leaf tree;;
```

* Many of the other `List` functions have analogues on binary trees and recursive variants in general
   - `length` (`size` for a tree), `forall`, `exists`, `filter` (filter out a subtree), etc etc.

* For some operations we need to know how to compare the tree elements, 
* e.g. if it is a binary (sorted) tree an insertion requires comparison
* For integers at least this is easy as we have `<=`:

```ocaml
let rec insert_int x bt =
   match bt with
   | Leaf -> Node(x, Leaf, Leaf)
   | Node(y, left, right) ->
       if x <= y then Node(y, insert_int x left, right)
       else Node(y, left, insert_int x right)
;;
```

* Like lists operations this is not mutating -- it returns a whole new tree.

```ocaml
let bt' = insert_int 4 bt;;
let bt'' = insert_int 0 bt';; (* thread in the most recent tree into subsequent insert *)
```

* For non-integers however, we need to explicitly supply any equal or comparison function.
   - recall `=` in `Core` works on integers only.
* Library functions needing to compare will in fact take a comparision operation as argument
* For example in the `List` library, the [`List.sort` function](https://ocaml.janestreet.com/ocaml-core/latest/doc/base/Base/List/index.html#val-sort)
* Here is an example of how to sort a string list with `List.sort`:

```ocaml
List.sort ["Zoo";"Hey";"Abba"] (String.compare);; (* pass string's comparison function as argument *)
(* insight into OCaml expected behavior for compare: *)
# String.compare "Ahh" "Ahh";; )(* =  returns 0*)
- : int = 0
# String.compare "Ahh" "Bee";; (* < returns -1 *)
- : int = -1
# String.compare "Ahh" "Ack";; (* > returns 1 *)
- : int = 1
```

So, a general tree insert would follow the lead of `List.sort`:

```ocaml
let rec insert x bt compare =
   match bt with
   | Leaf -> Node(x, Leaf, Leaf)
   | Node(y, left, right) ->
       if (compare x y) <= 0 then Node(y, insert x left compare, right)
       else Node(y, left, insert x right compare)
;;
let bt' = insert 4 bt (Int.compare);;
```

* In general all the built-in types have both `compare` and `equal` (which is same as `(=)`) defined
* Define your own compare/equal for your own types if you need it
 - Appending `[@@ppx_deriving eq]` to  type decl as we saw above in Hamming DNA example will automatically define function `equal_mytype` for your type `mytype`
 - Appending `[@@ppx_deriving ord]` (`ord` for ordering) is similar but will define function `compare_mytype`.

### Polymorphic Variants Briefly

* OCaml has an additional form of variant which has different syntax and is overlapping in uses: *polymorphic variants*
* A better term would be "inferred variants" - you don't need to declare them via `type`.

```ocaml
# `Zinger(3);;
- : [> `Zinger of int ] = `Zinger 3
```
* This looks a bit useless, it inferred a 1-ary variant type
* But the "`>`" in the type means *there could be other variants showing up in the future*.

```ocaml
# [`Zinger 3; `Zanger "hi"];;
- : [> `Zanger of string | `Zinger of int ] list = [`Zinger 3; `Zanger "hi"]
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
