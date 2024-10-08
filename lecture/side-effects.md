## Side effects

* Side effects are operations which do more than return a result: mutate, I/O, exceptions, threads, etc.
* So far we have not seen many side effects but a few have snuck in: printing, file input, exceptions
* Principle of idiomatic OCaml (and style for this class): **avoid effects**, unless they are a real improvement, or a necessity (e.g. I/O).
* Reminder: don't use mutation on your homeworks, and limit use of other effects as well.

Side effects of OCaml include
* Mutatable state - *changing* the contents of a memory location intead of making a new one
    - Three built-in sorts in OCaml: references, mutable record fields, and arrays.
    - Plus many libraries: `Stack`, `Queue`, `Hashtbl`, `Hash_set`, etc
* Exceptions (we saw a bit of this already, `failwith "ill-formed"` etc)
* Input/output (in basic modules lecture we looked at file input and results printing for example)
* Concurrency and parallelism (will cover later)

### State
 * Variables in OCaml are *never* directly mutable
 * But, they can hold a *reference* to memory that can be mutated
 * i.e. it is only indirect mutability - variable itself can't change, but what it points to can.

### Mutable References

* References, mutable references, refs, reference cells, and cells are all more or less synomyms

```ocaml
let x = ref 4;; (* have to declare initial value when creating *)
val x : int ref = {contents = 4}
```

Meaning of the above: x forevermore (i.e. forever unless shadowed) refers to a fixed cell.  The **contents** of that fixed cell, currently `4`, can change, but not x.

```ocaml
# let x = ref 4;;
val x : int ref = {contents = 4}
# x + 1;;
Line 1, characters 0-1:
Error: This expression has type int ref but an expression was expected of type
         int
# !x + 1;; (* need !x to get out the value; parallels *x in C *)
- : int = 5
# x := 6;; (* assignment - x must be a ref cell.  Returns () - only performs side effect *)
- : unit = ()
# !x + 1;; (* Mutation happened to contents of cell x *)
- : int = 7
# 
```


#### Variables are still themselves immutable

* To be clear, `let` doesn't turn into a mutation operator with `ref`:

```ocaml
let x = ref 4;;
let f () = !x;;

x := 234;;
f();;

let x = ref 6;; (* shadows previous x definition, NOT an assignment to x !! *)
f ();; (* 234, not 6 *)
```


#### Null or Nil initial cell contents in OCaml, and Weakly Polymorphic types

* If you don't yet have a well-formed initial value, use an `option`:
```ocaml
let x = ref None;;
val x : '_weak1 option ref = {contents = None}
```
* Note the type here, `'_weak1 option ref`, this is a *weakly polymorphic type*
* Which really is not polymorphic at all - what it means is the type can be only a single type
    - which is not known yet
* If you think about it, there is no other possibility, can't put int and string in same cell
    - would not know the type when taking out of cell.

```ocaml
# x := Some 3;;
- : unit = ()
# !x;;
- : int option = Some 3 (* `'_weak1` = `int` now, permanently *)
```

* At various points OCaml will infer only weak types on certain things
* Most of the time it is because it would be incorrect not to
* But occasionally OCaml is too dumb to realize things are not weak
    - there are advanced workarounds for this case which we will not cover

### Mutable Records

* Along with refs we can declare some record fields `mutable`
* `'a ref` is really implemented by a mutable record with one field, contents:
* `'a ref` in fact abbreviates the type `{ mutable contents: 'a }`
* The keyword mutable on a record field means it can mutate

```ocaml
let x = { contents = 4};; (* identical to x's definition above *)
x := 6;;
x.contents <- 7;;  (* same effect as previous line: backarrow updates a field *)

!x + 1;;
x.contents + 1;; (* same effect as previous line *)
```
#### Declaring Mutable Record Types

 * Default on each field is the value will be *immutable*
 * Put `mutable` qualifier on each field that you want to mutate
 * Principle of least mutability: only put `mutable` on fields you **have** to mutate

```ocaml
type mutable_point = { mutable x: float; mutable y: float };;
let translate p dx dy =
  p.x <- (p.x +. dx); (* observe use of ";" here to sequence effects *)
  p.y <- (p.y +. dy);;
let mypoint = { x = 0.0; y = 0.0 };;
translate mypoint 1.0 2.0;;
mypoint;;
```
* Note here that the `x` and `y` fields of the point are mutable, but the point as a whole you cannot swap in a different point for.


#### Tree with mutable subtrees

```ocaml
(* version using ref: *)
type 'a mtree = MLeaf | MNode of 'a * 'a mtree ref * 'a mtree ref;;
(* But, use this type with mutable records - no `!` needed: *)
type 'a mtree = MLeaf | MNode of { data : 'a; mutable left : 'a mtree; mutable right : 'a mtree};;
```

- Note that in this `mtree` we can only mutate the subtrees, *not* the data
- Also, cannot replace a leaf at top of tree with a non-leaf.
- The idea is to put mutablility only where you are doing mutation, no more no less.
- So if the tree structure never changes but the node values can, only make the `data` mutable.

Example use: mutate right tree

```ocaml
# let mt = MNode {data = 3; left = MLeaf; right = MLeaf};;
val mt : int mtree = MNode {data = 3; left = MLeaf; right = MLeaf}
# match mt with 
| MLeaf -> ()
| MNode ({data;left;right} as r) -> r.left <- MNode {data = 5; left = MLeaf; right = MLeaf};;
- : unit = ()
# mt;;
- : int mtree =
MNode
 {data = 3; left = MNode {data = 5; left = MLeaf; right = MLeaf};
  right = MLeaf}
```
- Note the use of the `... as r` in the pattern, sometimes something needs a name that didn't have one
- And of course notice that `mt` actually *changed* here unlike with immutables

### Physical equality

* Occasionally in imperative programs you need to check for "same pointer"
* `phys_equal` is `Core` notion for for "same pointer" (use `==` in non-Core)

```ocaml
# phys_equal 2 2;;
- : bool = true
# let x = ref 4;;
val x : int ref = {contents = 4}
# let y = x;;
val y : int ref = {contents = 4}
# phys_equal x y;;
- : bool = true (* same pointer *)
# let z = ref 4;;
val z : int ref = {contents = 4}
# phys_equal x z;;
- : bool = false (* different pointers *)
```

#### Control structures to help with mutution

*  Sequencing via "`;`" becomes useful with side effects

```ocaml
print_string "hi"; print_string "\n";;
```

* Observe that operations that only have a side effect return `() : unit`
    - `:=`, `<-`, `print`ing, etc
    - But sometimes operators will both have effects and return something
    - Sometimes need to sequence that and you may get an annoying warning if so:

```ocaml
# let incr = 
let count = ref 0 in 
let incr () = count := !count + 1; !count in incr;;
- : unit -> int = <fun>
# incr() ; incr();;
Line 1, characters 0-6:
Warning 10: this expression should have type unit.
...
```

* Gives a warning since it is concerned that the first incr does not return unit.
* This warning is actually good most of the time in fact, it means `;` was used incorrectly
* To silence warning (once you are clear you are doing the right thing):

```ocaml
# ignore(incr()) ; incr() (* or, can use let _ = incr() in incr() *)
```

* `for` and `while` loops are useful with mutable state
* But they are almost always a code smell in OCaml, usually a data structure iterator like map fold etc is better.
* Here is a `while .. do .. done` loop; `for` syntax also standard

```ocaml
let x = ref 1 in
while !x < 10 do
  printf "count is %i ...\n" !x;
  x := !x + 1;
done;;
```

* Fact: while loops are useless without mutation: would either never loop or infinitely loop
* Same for `e1 ; e2` --  if `e1` has no side effects may as well delete it, it is dead code!
* Note that `e1; e2` is exactly the same as writing `let () = e1 in e2`

### Arrays
 - They are mutable, and they are also constant time to access nth element unlike lists
 - But, extending an array is inefficient: cannot share sub-array due to mutation
 - Entered and shown as `[| 1; 2; 3 |]` (added "`|`") in top-loop to distinguish from lists.
 - Have to be initialized before using
     - In general, there is no such thing as "uninitialized" in OCaml.
     - If you need "undefined"/"null" array, make it an `int option array` and init to `None`'s.


```ocaml
let arrhi = Array.create ~len:10 "hi";; (* length and initial value *)
let arr = [| 4; 3; 2 |];; (* make a literal array *)
arr.(0);; (* access (unfortunately already used [] for lists so a bit ugly) *)
arr.(0) <- 55;; (* update *)
arr;;
(* Don't use for loops for arrays, use your favorite iterators: *)
Array.map ~f:(fun x -> x + 1) arr;; (* standard map - produces a new array *)
Array.map_inplace ~f:(fun x -> x + 1) arr;; (* This *changes* the array based on map-function *)
(* Here are some conversions *)
let a = Array.of_list [1;2;3];;
let l = Array.to_list a;;
```

### Exceptions

* As mentioned earlier, exceptions are powerful but dangerous
  - They are OK if they are always handled close to when they are raised
  - If the handler is far away it can lead to buggy code
  - We will aim for idiomatic use of OCaml exceptions in FPSE: local necessary ones only.
* `Core` discourages over-use of exceptions in its library function signatures
  - Avoid the `blah_exn` library functions unless the handler is close by

There are a few simple built-in exceptions which we used some already:

```ocaml
failwith "Oops";; (* Generic code failure - exception is named Failure *)
invalid_arg "This function works on non-empty lists only";; (* Invalid_argument exception *)
```

Also there are library functions we covered that raise exceptions

```ocaml
# List.zip_exn [1;2] [2;3;4];;
Exception: (Invalid_argument "length mismatch in zip_exn: 2 <> 3")
```

### OCaml syntax for defining raising and handling exceptions
* New exception names need to be declared via `exception` like `type`s needs to be declared
* Unfortunately types do not include what exceptions a function may raise 
  - an outdated aspect of OCaml; even Java has this
* The value returned by an exception is very similar in looks to a variant.

```ocaml
exception Boom of string;; (* Note like with variants the `of` is optional, no payload required *)

let f _ = raise @@ Boom "keyboard on fire";; (* raise is ultimately how all exceptions are raised *)
f ();;

let g () =
  try f ()
  with
  | Boom s -> printf "exception Boom raised with payload string \"%s\"\n" s
;;
g ();;
```

### Mutating data structures in `Core`

* The `Stack` and `Queue` modules in `Core` are *mutable* data structures.
* (There are no immutable libraries for stack/queue - just use `list`s)
* (There is also `Hash_set` which is a (hashed) mutable set and `Hashtbl` which is a mutable hashtable; more on those later)
* Here is a simple example of playing around with a `Stack` for example.

```ocaml
# let s = Stack.create();;
val s : '_weak3 t = <abstr> (* Stack.t is the underlying implementation and is hidden *)
# Stack.push s "hello";;
- : unit = ()
# Stack.push s "hello again";;
- : unit = ()
# Stack.push s "hello one more time";;
- : unit = ()
# Stack.to_list s;; (* a handy function to see what is there; top on left *)
- : string list = ["hello one more time"; "hello again"; "hello"]
# Stack.pop s;;
- : string option = Some "hello one more time"
# Stack.pop_exn s;; (* exception raised if empty here *)
- : string = "hello again"
# Stack.pop_exn s;;
- : string = "hello"
# Stack.pop s;;
- : string option = None
# Stack.exists s ~f:(fun s -> String.is_substring s "time");; (* Stack has folds, maps, etc too *)
- : bool = true
```

### Summing Up Effects: A Parentheses Matching Function

* To show how to use effects and some of the trade-offs, we look at a small example
* See file [matching.ml](../examples/matching.ml) which has several versions of a simple parenthesis matching function
* It shows uses of `Stack`, and some trade-offs of using exceptions vs option type.
* Lastly there is a pure functional version which is arguably simpler
 - Yes you **don't** need that mutation!
