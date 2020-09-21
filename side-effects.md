## Side effects

* Side effects are operations which do more than return a result
* So far we have not seen many side effects but a few have snuck in

Side effects of OCaml include
* Mutatable state - *changing* the contents of a memory location intead of making a new one
    - three main basic sorts in OCaml: references, mutable record fields, and arrays.
* Exceptions (we saw a bit of this already, `failwith "ill-formed"`)
* Input/output (we just looked at file input for example) 

### State
 * Variables in OCaml are still not directly mutable
 * They can hold a *reference* to mutable memory (and a way to mutate said reference)
 * i.e. it is only indirect mutability - variable itself can't change, but what it points to can.
 * OCaml invariant: items are immutable unless their mutability is explicitly declared

### Mutable References

```ocaml
let x = ref 4;;    (* always have to declare initial value when creating a reference *)
```

Meaning of the above: x forevermore (i.e. forever unless shadowed) refers to a fixed cell.  The **contents** of that fixed call can change, but not x.

```ocaml
x + 1;; (* a type error ! *)
!x + 1;; (* need !x to get out the value; parallels *x in C *)
x := 6;; (* assignment - x must be a ref cell.  Returns () - goal is side effect *)
!x + 1;; (* Mutation happened to contents of cell x *)
```

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
#### Mutable record declarations

Declaring your own mutable record:
 * Default on each field is that value will be immutable
 * Put `mutable` qualifier on each mutable field that you want to mutate
 * Principle of least mutability: only put `mutable` on fields you **have** to mutate

```ocaml
type mutable_point = { mutable x: float; mutable y: float };;
let translate p dx dy =
                p.x <- (p.x +. dx); (* observe use of ";" here to sequence effects *)
                p.y <- (p.y +. dy)  (* ";" is useless without side effects (think about it) *)
                                ;;
let mypoint = { x = 0.0; y = 0.0 };;
translate mypoint 1.0 2.0;;
mypoint;;
```

Observe: mypoint is immutable at the top level but it has two spots in it where we can mutate

Tree with mutable nodes

```ocaml
type mtree = MLeaf | MNode of int * mtree ref * mtree ref;;
```

- ONLY ref typed variables or mutable records may be assigned to
- The notion of immutable variables is one of the great strengths of OCaml.
- Note: `let` doesn't turn into a mutation operator with `ref`:

```ocaml
let x = ref 4;;
let f () = !x;;

x := 234;;
f();;

let x = ref 6;; (* shadowing previous x definition, NOT an assignment to x !! *)
f ();;
```

#### Control structures to help with mutution

* For and while-loops also exist and are useful with mutable state
* Also sequencing via "`;`" becomes useful with side effects

```ocaml
let x = ref 1 in
    while !x < 10 do
      Out_channel.print_string (Int.to_string !x);
      Out_channel.print_string "\n";
      x := !x + 1;
    done;;
```

* Observe that operations that only have a side effect return `() : unit`
* Fact: while loops are useless without mutation: would either never loop or infinitely loop
* Same for `e1 ; e2` --  if `e1` has no side effects may as well delete it, it is dead code!
* May help to know `e1; e2` is basically the same as `let () = e1 in e2`

Why is immutability good?
 - programmer can depend on the fact that something will never be mutated when writing code: permanent like mathematical definitions
 - ML still lets you express mutation, but its only use it when its really needed
 - Haskell has an even stronger separation of mutation, its all strictly "on top".

### Arrays
 - Fairly self-explanatory; 
 - Entered and shown as `[| 1; 2; 3 |]` (added "`|`") in top-loop to distinguish from lists.
 - Have to be initialized before using
     - In general, there is no such thing as "uninitialized" in OCaml.
     - If you really need it, make it an `int option array` and init to `None`'s.


```ocaml
let arrhi = Array.make 100 "";; (* size and initial value are the params here *)
let arr = [| 4; 3; 2 |];; (* another way to make an array *)
arr.(0);; (* access (unfortunately already used [] for lists in the syntax) *)
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

### Contrasting exceptions with bubbling up errors



