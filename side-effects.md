## Side effects

* Side effects are operations which do more than return a result
* So far we have not seen many side effects but a few have snuck in
* Principle of idiomatic OCaml (and style for this class): **avoid effects**, unless it is critically needed.

Side effects of OCaml include
* Mutatable state - *changing* the contents of a memory location intead of making a new one
    - Three built-in sorts in OCaml: references, mutable record fields, and arrays.
    - Plus many libraries: `Stack` etc
* Exceptions (we saw a bit of this already, `failwith "ill-formed"`)
* Input/output (in basic modules lecture we looked at file input and results printing for example) 

### State
 * Variables in OCaml are *still* not directly mutable
 * They can hold a *reference* to mutable memory (and a way to mutate said reference)
 * i.e. it is only indirect mutability - variable itself can't change, but what it points to can.
 * OCaml invariant: items are immutable unless their mutability is explicitly declared

### Mutable References

* References, mutable references, refs, reference cells, and cells are all more or less synomyms

```ocaml
let x = ref 4;; (* have to declare initial value when creating *)
val x : int ref = {contents = 4}
```

Meaning of the above: x forevermore (i.e. forever unless shadowed) refers to a fixed cell.  The **contents** of that fixed call can change, but not x.

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

#### Null or Nil initial cell contents in OCaml, and Weakly Polymorphic types

* If you don't yet have a well-formed initial value, use an `option`:
```ocaml
let x = ref None;; (* Use an option type if initial value not known yet *)
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
# let y = ref None;;
val y : '_weak2 option ref = {contents = None} (* next one is `'_weak2` etc *)
```

* At various points OCaml will infer only weak types on certain things
* Most of the time it is because it would be incorrect not to
* But occasionally OCaml is too dumb to realize things are not weak
    - there are some workarounds for this case

### Mutable Records

* Along with refs we can make some record fields mutable
* `'a ref` is really implemented by a mutable record with one field, contents:
* `'a ref` abbreviates the type `{ mutable contents: 'a }`
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

#### Tree with mutable subtrees

```ocaml
(* version using ref: *)
type 'a mtree = MLeaf | MNode of 'a * 'a mtree ref * 'a mtree ref;;
(* But, this type would be more readable with mutable record - no `!` needed: *)
type 'a mtree = MLeaf | MNode of { data : 'a; mutable left : 'a mtree; mutable right : 'a mtree};;
```

- Note that in this `mtree` we can only mutate the subtrees, not the data
- Also, cannot replace a leaf at top of tree with a non-leaf.
- The idea is to put mutablility only where you are doing mutation, no more no less.

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
# let count = ref 0 in 
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
# ignore(incr()) ; incr()
```

* `for` and `while` loops are useful with mutable state
* But, don't fall back into old state habits; good OCaml style is functional by default
* Here is a `while .. do .. done` loop; `for` syntax also standard

```ocaml
let x = ref 1 in
while !x < 10 do
  Out_channel.print_string (Int.to_string !x);
  Out_channel.print_string "\n";
  x := !x + 1;
done;;
```

* Fact: while loops are useless without mutation: would either never loop or infinitely loop
* Same for `e1 ; e2` --  if `e1` has no side effects may as well delete it, it is dead code!
* May help to know `e1; e2` is basically the same as `let () = e1 in e2`

### Arrays
 - Fairly self-explanatory; 
 - Entered and shown as `[| 1; 2; 3 |]` (added "`|`") in top-loop to distinguish from lists.
 - Have to be initialized before using
     - In general, there is no such thing as "uninitialized" in OCaml.
     - If you really need it, make it an `int option array` and init to `None`'s.


```ocaml
let arrhi = Array.make 100 "";; (* size and initial value are the params here *)
let arr = [| 4; 3; 2 |];; (* make a literal array *)
arr.(0);; (* access (unfortunately already used [] for lists so a bit ugly) *)
arr.(0) <- 55;; (* update *)
arr;;
let a = Array.of_list [1;2;3];;
let l = Array.to_list a;;
```

### Exceptions

* As mentioned earlier, exceptions are powerful but dangerous
  - They are OK if they are always handled very close to when they are raised
  - If the handler is far away it can lead to buggy code
  - We will aim for idiomatic use of OCaml exceptions here: local necessary ones only.
* `Core` discourages over-use of exceptions in its library function signatures

The OCaml syntax for exceptions
* New exception names need to be declared via `exception` like `type`s needs to be declared
* Unfortunately types do not include what exceptions a function will raise - outdated aspect of ML.
* The value returned by an exception is very similar in looks to a variant.


```ocaml
exception Goo of string;; (* Note like with variants the `of` is optional, no payload required *)

let f _ = raise (Goo "keyboard on fire");;
f ();;

let g () =
  try
    f ()
  with
      Foo -> ()
        | Goo s ->
      (Out_channel.(print_string("exception raised: ");
       print_string(s);print_string("\n")))
;;
g ();;
```

There are a few simple built-in exceptions which may be familiar:

```ocaml
failwith "Oops";; (* Generic code failure - exception is named Failure *)
invalid_arg "This function works on non-empty lists only";; (* Invalid_argument exception *)
```

### Mutating data structures in `Base`

* The `Stack` and `Queue` modules in `Base` (and `Core`) are mutable data structures.
* Here is a simple example of playing around with a stack for example.

```ocaml
# let s = Stack.create();;
val s : '_weak3 t = <abstr> (* Stack.t is the underlying implementation and is hidden *)
# Stack.push s "hello";;
- : unit = ()
# Stack.push s "hello again";;
- : unit = ()
# Stack.push s "hello one more time";;
- : unit = ()
# Stack.to_list s;; (* very handy function to see what is there *)
- : string list = ["hello one more time"; "hello again"; "hello"]
# Stack.pop s;;
- : string option = Some "hello one more time"
# Stack.pop_exn s;;
- : string = "hello again"
# Stack.pop_exn s;;
- : string = "hello"
# Stack.pop s;;
- : string option = None
# Stack.exists s ~f:(fun s -> String.contains s 't');; (* Stack has folds, maps, etc too *)
- : bool = true
```




