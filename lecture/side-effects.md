## Side effects

* Side effects are operations which do more than return a result: mutate, I/O, exceptions, threads, etc.
* So far we have not seen many side effects but a few have snuck in: printing, file input, exceptions
* Principle of idiomatic OCaml (and style for this class): **avoid effects**, unless they are a real improvement, or a necessity (e.g. I/O).
* Reminder: don't use mutation on your homeworks, and limit use of other effects as well.

Side effects of OCaml include
* Mutatable state - *changing* the contents of a memory location intead of making a new one
  - Three built-in sorts in OCaml: references, mutable record fields, and arrays.
  - Plus many libraries: `Stack`, `Queue`, `Hashtbl`, etc
  - Faster because rebuilding avoided, but slower due to impossibility of sharing sub-components
* Exceptions (we saw a bit of this already, `failwith "ill-formed"` etc)
* Input/output (in basic modules lecture we looked at file input and results printing for example)
* Concurrency and parallelism (will cover later)

### State
* Variables in OCaml are *never* directly mutable
* But, they can hold a *reference* to memory that can be mutated
* i.e. it is only indirect mutability - variable itself can't change, but what it points to can.

### Mutable References

* References, mutable references, refs, reference cells, and cells are all more or less synomyms
* `'a ref` is a type, and `val ref : 'a -> 'a ref` is a function that makes a ref cell.

```ocaml
# let x = ref 4;; (* have to declare initial value when creating *)
val x : int ref = {contents = 4}
```

Meaning of the above: `x` forevermore (i.e. forever unless shadowed) refers to a fixed cell.  The **contents** of that fixed cell, currently `4`, can change, but not `x`.

```ocaml
# let x = ref 4;;
val x : int ref = {contents = 4}

# x + 1;;
Line 1, characters 0-1:
Error: This expression has type int ref but an expression was expected of type
         int
```

* Addition with `(+)` works on integers, but `x` is of type `int ref`.
* Get the value from a ref cell with the `!` prefix operator.
  * It simply gets the (immutable) value that the ref cell points to.
  * It does *not* get the memory location that it points to.

```ocaml
# !x + 1;; (* use !x to get out the value; similar to *x in C *)
- : int = 5

# x := 6;; (* assignment with (:=). x must be a ref cell.  Returns () - only performs side effect *)
- : unit = ()

# !x + 1;; (* Mutation happened to contents of cell x *)
- : int = 7
```

And `!` does **not** return the memory location to which a ref cell points, so this is a syntax error:

```ocaml
let x = ref 4
let !x = 5 (* syntax error. !x is a value, not a valid assignee *)
```

In this way, `!x` in OCaml is not like `*x` in C.

### Tangent on unit

* `unit` is a terminal type. Only one value called `()` has type `unit`, and it is totally useless.
* All you can do is pass it around.
* So what is it good for?

Since `()` is useless, any function that returns it is either useless **or** performs a side effect. It is almost certainly the latter.

```ocaml
# print_endline;; (* returns unit; has the side effect of printing *)
- : string -> unit = <fun>

# (:=);; (* returns unit; has the side effect of assignment to LHS *)
- : 'a ref -> 'a -> unit = <fun>

# Hashtbl.add;; (* returns unit, so it has the side effect of assignment *)
: ('a, 'b) Hashtbl.t -> 'a -> 'b -> unit = <fun>
```

* `Hashtbl.add` returns `unit`, so it must be a mutable data structure.
* On the flip side, functions taking `unit` as argument are often also only performing side effects.

```ocaml
# Stack.create;; (* takes unit, so it is making a new mutable data structure *)
- : unit -> 'a Stack.t = <fun>

# Stack.create ();; (* Note the convention of putting a space here *)
- : '_weak1 Stack.t = <abstr> (* It is abstract, we can't see internals.. more on weak types soon *)
```

### Variables are still themselves immutable

* To be clear, `let` doesn't turn into a mutation operator with `ref`:

```ocaml
let x = ref 4;;
let f () = !x;;

x := 234;;
f ();;

let x = ref 6;; (* shadows previous x definition, NOT an assignment to x !! *)
f ();; (* 234 still, not 6 *)
```

### Null or Nil initial cell contents in OCaml, and Weakly Polymorphic types

* If you don't yet have a well-formed initial value, use an `option`:

```ocaml
# let x = ref None;;
val x : '_weak1 option ref = {contents = None}
```

* Note the type here, `'_weak1 option ref`, this is a *weakly polymorphic type*
* Which really is not polymorphic at all - what it means is the type can be only a single type
  - which is not known yet
* To the first order, a weakly polymorphic type is like a "Schrodinger's type".
  - It is ready to be any (single) type until it is observed (i.e. used), after which it is fixed.
* If you think about it, there is no other possibility: you can't put int and string in same cell.
  - In that case, you would not know the type when taking out of cell.

```ocaml
# x := Some 3;;
- : unit = ()

# !x;;
- : int option = Some 3 (* now we see '_weak1 was touched and its now forevermore an int *)
```

* At various points, OCaml will infer only weak types on certain things.
* Most of the time it is because it would be incorrect not to.
* But occasionally OCaml is too dumb to realize things are not weak.
  - there are advanced workarounds for this case which we will not cover

The weak types are here so that we cannot do this:

```ocaml
let x = ref None (* Puts Schrodinger's cat in the box. It is weakly typed, not polymorphic. *)

let _ = x := Some 5 (* Observes Schrodinger's cat: fixes the weak type to be int *)

let _ = x := Some "hello" (* type error! x is not a string ref *)
```

### Mutable Records

* Along with refs, we can declare some record fields `mutable`
* `'a ref` is really implemented by a mutable record with one field, contents:
* `'a ref` in fact is the type `{ mutable contents: 'a }`
  * And `ref` is a just a function to make creation convenient.
  * And `(:=)` is just a function to make assignment convenient.
  * And `(!)` is just a function to make reading convenient and explicit.
* The keyword `mutable` on a record field means it can mutate.

```ocaml
let x = { contents = 4 };; (* 100.0% identical to `let x = ref 4` *)

x.contents <- 7;;  (* identical to `x := 6` *)

x.contents + 1;; (* identical to `!x + 1` *)
```

### Declaring Mutable Record Types

* The default on each field is that the value is *immutable*.
* Put `mutable` qualifier on each field that you want to mutate>
* Principle of least mutability: you should only put `mutable` on fields you **have** to mutate.

```ocaml
type mutable_point = { mutable x : float ; mutable y : float };;

let translate p dx dy =
  p.x <- (p.x +. dx); (* observe use of ";" here to sequence effects *)
  p.y <- (p.y +. dy)
;;

let mypoint = { x = 0.0; y = 0.0 };; (* new mutable record *)

translate mypoint 1.0 2.0;; (* changes fields inside mypoint *)

mypoint;;
```

* Here, the `x` and `y` fields of the point are mutable, but the point as a whole you cannot swap in a different point for.

* Note that `;` is the standard sequencing operator.
  * But in OCaml everything is an expression so it's a bit non-standard.
  * `e ; e'` is roughly the same as `let () = e in e'`: evaluate `e`, ignore result, then evaluate `e'`.
  * `(5 + 2); true` will give you a warning since `5` is not of type `unit`
  * The reasoning here is if you are using `;` the left-hand side should have a side effect because you are throwing away the result,
    - and, as we covered above, side-effecting functions will nearly always return `unit`.

### Tree with mutable subtrees

```ocaml
(* version using ref: *)
type 'a mtree_ref =
  | MLeaf
  | MNode of 'a * 'a mtree ref * 'a mtree ref
;;

(* But, use this type with mutable records - no `!` needed: *)
type 'a mtree =
  | MLeaf
  | MNode of { data : 'a ; mutable left : 'a mtree ; mutable right : 'a mtree }
;;
```

- Note that in this `mtree`, we can only mutate the subtrees, *not* the data.
- Also, we cannot replace a leaf at top of tree with a non-leaf.
- The idea is to put mutablility only where you are doing mutation, no more no less.
- So if the tree structure never changes but the node values can, you would only make the `data` mutable.

Example use: mutate left subtree

```ocaml
# let mt = MNode { data = 3 ; left = MLeaf ; right = MLeaf };;
val mt : int mtree = MNode {data = 3; left = MLeaf; right = MLeaf}

# match mt with
| MLeaf -> ()
| MNode ({ data ; left ; right } as r) -> (* "as" captures it all under one name *)
  r.left <- MNode { data = 5 ; left = MLeaf ; right = MLeaf };;
- : unit = ()

(* Verify that mt mutated *)
# mt;;
- : int mtree =
MNode
 { data = 3
 ; left = MNode { data = 5 ; left = MLeaf ; right = MLeaf }
 ; right = MLeaf }
```

### Physical equality

* Occasionally in imperative programs you need to check for "same pointer".
* It's also useful in functional programming for fast comparison when data is shared.
* There's no need to compare entire structures if their memory addresses are identical.

```ocaml
# 2 == 2;; (* memory layout of 2 is always the same *)
- : bool = true

# let x = ref 4;;
val x : int ref = {contents = 4}

# let y = x;; (* make y an alias for x *)
val y : int ref = {contents = 4}

# x == y;;
- : bool = true (* same pointer *)

# let z = ref 4;; (* new cell. totally different from x and y *)
val z : int ref = {contents = 4}

# x == z;;
- : bool = false (* different pointers *)
```

We can use `==` to see that data is shared in functional data structures.

```ocaml
# let big_list = List.init 10000 Fun.id ;;

# let x = 10 :: big_list ;;

# let y = 11 :: big_list ;;

# x == y ;;
- : bool = false

# List.tl x == List.tl y ;;
- : bool = true (* the tails are physically identical, they are big_list *)
```

### Control structures to help with mutution

* As mentioned above, side effecting operations usually return `unit`
* But occasionally they don't, and you might want to use `;` with them, which OCaml will complain about:

```ocaml
# let next =
  let count = ref 0 in
  fun () ->
    count := !count + 1;
    !count
;;
- : unit -> int = <fun>

# next () ; next ();; (* Increment twice *)
Line 1, characters 0-7:
Warning 10 [non-unit-statement]: this expression should have type unit.
- : int = 2
```

* Gives a warning since the first `next ()` does not return `unit`, but it is sequenced with `;`.
* To silence the warning (once you are clear you are doing the right thing):

```ocaml
# ignore (next ()); next () (* or, better, let _ = next () in next () *)
```

* `for` and `while` loops are useful with mutable state.
* But they are often a code smell in OCaml. Usually a data structure iterator like map, fold, etc. is better.
* Here is a `while .. do .. done` loop; `for` syntax also standard

```ocaml
let x = ref 1 in
while !x < 10 do
  Printf.printf "count is %i ...\n" !x;
  x := !x + 1
done;;
```

* Fact: `while` loops are useless without mutation: would either never loop or infinitely loop
* Same for `e1 ; e2` --  if `e1` has no side effects, you may as well delete it. It is dead code!
* Remember that `e1; e2` is exactly the same as writing `let () = e1 in e2`

### Arrays

- They are mutable, and they are also constant time to access nth element, unlike lists
- But, extending an array is inefficient: cannot share sub-array due to mutation
- And, sub-components of different arrays cannot be shared since they may change
- They have syntax `[| 1; 2; 3 |]` (added "`|`" inside the usual list brackets) to distinguish from lists.
- They have to be initialized an entry in every slot before using.
  - In general, there is no such thing as "uninitialized" in OCaml.
  - If you need "undefined"/"null" array, make it an `int option array` and init to `None`'s.

```ocaml
let arrhi = Array.init 10 (fun _ -> "hi");; (* length and initial value maker *)

let arr = [| 4; 3; 2 |];; (* make a literal array *)

arr.(0);; (* access *)

arr.(0) <- 55;; (* update cell, like with mutable record fields *)

arr;; (* see that arr has changed *)

Array.map (fun x -> x + 1) arr;; (* standard map - produces a new array *)

Array.map_inplace (fun x -> x + 1) arr;; (* This *changes* the array using the map function and returns unit *)

(* Here are some conversions *)
let a = Array.of_list [1;2;3];;
let l = Array.to_list a;;
```

### Exceptions

* As mentioned earlier, exceptions are powerful but dangerous
  - They are OK if they are always handled close to when they are raised
  - If the handler is far away it can lead to buggy code
  - We will aim for idiomatic use of OCaml exceptions in FPSE: local necessary ones only.

There are a few simple built-in exceptions which we used some already:

```ocaml
failwith "Oops";; (* Generic code failure - exception is named Failure *)
invalid_arg "This function works on non-empty lists only";; (* Invalid_argument exception *)
```

Also there are library functions we covered that raise exceptions

```ocaml
# List.combine [1;2] [2;3;4];;
Exception: Invalid_argument "List.combine".
```

### OCaml syntax for defining raising and handling exceptions

* New exception names need to be declared via `exception` like `type`s needs to be declared
* Unfortunately, OCaml types do not include what exceptions a function may raise
  - an outdated aspect of OCaml; even Java has this with `raises` on method declarations
* The value returned by an exception is very similar in looks to a variant.
  - (tangent: under the hood, the `exn` type is an extensible variant!)

Extend the `exn` type with your exception using the `exception` keyword.
- Everything following the `exception` keyword is just like a variant constructor declaration.
- There is no need for `of` if you don't want data in your exception, just like a variant with no payload (e.g. `None`).

```ocaml
exception Boom of string;;

let f _ = raise @@ Boom "keyboard on fire";; (* raise is ultimately how all exceptions are raised *)

f ();; (* this raises the exception *)

let g () =
  try f () with
  | Boom s -> printf "exception Boom raised with payload string \"%s\"\n" s
;;

g ();;
```

### Mutating data structures in the standard libraries

* The `Stack` and `Queue` modules are *mutable* data structures.
* (There are no immutable stack/queue libraries - but just use `list`s most of the time)
* (There is also `Hashtbl` which is a mutable hash table)
* Here is a simple example of playing around with a `Stack`.

```ocaml
# let s = Stack.create();;
val s : '_weak1 Stack.t = <abstr> (* Stack.t is the underlying implementation and is hidden *)

# Stack.push "hello" s;;
- : unit = () (* returns unit because s is mutated *)

# Stack.push "hello again" s;;
- : unit = ()

# Stack.push "hello one more time" s;;
- : unit = ()

# Stack.pop s;; (* exception Stack.Empty will be raised if empty here *)
- : string = "hello one more time"

# Stack.pop s;;
- : string = "hello again" (* s changed from the last pop, so this pop is different! *)

# Stack.pop s;;
- : string = "hello"

# Stack.pop s;;
Exception: Stdlib.Stack.Empty.

# Stack.pop_opt s;; (* altenative interface to return an option and avoid exceptions *)
- : string option = None
```

### Summing Up Effects With an Example: A Parentheses Matching Function

* To show how to use effects and some of the trade-offs, we look at a small example
* See file [match.ml](../examples/match/match.ml)/[match.zip](../examples/zips/match.zip) which has several versions of a simple parenthesis matching function
* It shows uses of `Stack`, and some trade-offs of using exceptions vs option type.
* Lastly there is a pure functional version which is arguably simpler
  - Yes, you **don't** need that mutation!
