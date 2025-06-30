
## Records
- Records make **and** data: they have this-and-this-and-this.
- Tuples also make **and** data, but records have labels for each component.
  - Labels help with type checking and readability.
- Record fields are immutable by default.
  - We'll see a way to make them mutable in a future lecture on side effects.

### Example: a simple record type to represent rational numbers

```ocaml
type ratio = { num : int ; denom : int }
```

This defined the `ratio` type, a record type with two labels:
- `num` is label with an `int` value.
- `denom` is a label with an `int` value, too.

Record types are written `label : type`. This should be familiar because we are used to using colons for types.

Record _values_ of that type are written `label = value`, like so:

```ocaml
let q = { num = 53 ; denom = 6 }
```

Note that a record type **must** be declared before you make any values with that type. For example, the following will **not** work because there is no type defined for it yet.

```ocaml
let p = { x = 42.0 ; y = 50.1 } (* doesn't work! It's type isn't defined yet *)
```

There are many ways to use record values. We will compare functions that do **the exact same thing** and are just different ways of writing it.

First, you may "project" the field from a record using dot notation: "record dot label". This is just like a struct or object in C/C++/Java etc.

```ocaml
let rat_to_int r =
  r.num / d.denom (* project the labels out from r *)
```

### Pattern matching

You may also match on the fields in records:

```ocaml
let rat_to_int r =
  match r with
  | { num = n ; denom = d } -> n / d
```

Here, the `num` field in `r` gets bound to the variable name `n`, and `denom` gets bound to the name `d`. We are matching on the record and binding its fields into variable names so that we don't need to do dot projections.
- Important! `num =` and `denom =` are the **labels**, and `n` and `d` are **variables**. There is a distinction because labels are not first class.

We can shortcut this and not rename them at all, but instead bind the fields `num` and `denom` from `r` straight into those names: `num` and `denom`. We call this "punning".

```ocaml
let rat_to_int r =
  match r with
  | { num ; denom } -> num / denom (* no `=` sign when not renaming *)
```

The above is simply sugar for this:

```ocaml
let rat_to_int r =
  match r with
  | { num = num ; denom = denom } -> num / denom
```

We can do this to any subset of the fields, e.g. the match case and body is allowed to be `| { num ; denom = d } -> num / d`. 

Because we have written **one pattern that captures all values with the type** `ratio`, we can inline it at the function parameter or with a `let` expression:

```ocaml
let rat_to_int { num = n ; denom = d } =
  n / d

let rat_to_int { num ; denom } =
  num / denom

let rat_to_int r =
  let { num ; denom } = r in
  num / denom
```

Notice in the first two that `r` is not bound anymore. We have no name for the whole record; we only have names for its fields.

Note that this inlining will not work when one pattern does not capture all values with that type. The compiler will warn that there are missing match cases. For example with options:

```ocaml
let value_exn (Some x : 'a option) : 'a = (* bad! There is a missing match case on None *)
  x
```

Okay, back to records now.

What about pattern matching when there are fields we don't need? Just capture them with an underscore! Like the above examples, both of the following will do the same thing.

```ocaml
let numerator r = 
  match r with
  | { num ; _ } -> num (* the _ catches all the other labels, no matter how many there are *)

let numerator r = 
  match r with
  | { num ; denom = _ } -> num (* binding denom into the unusable variable name _ *)
```

Like before, these patterns can be inlined.

Note that in the top loop, where some warnings are disabled, you can completely omit labels. Typically, though, the compiler will issue a warning, and you should not write patterns like this.

```ocaml
let numerator r =
  match r with
  | { num } -> num (* okay, but there is a warning, so you shouldn't do this *)
```

### Back to dot notation

Here is dot notation to make an addition of ratios:

```ocaml
let add_ratio r1 r2 =
  { num = r1.num * r2.denom + r2.num * r1.denom
  ; denom = r1.denom * r2.denom }

add_ratio {num = 1; denom = 3} {num = 2; denom = 5}
```

And here is a preferred pattern equivalent, where we cannot "pun" the labels because there are two records of the same type.

```ocaml
let add_ratio { num = n1 ; denom = d1 } { num = n2 ; denom = d2 } = 
  { num = n1 * d2 + n2 * d1
  ; denom = d1 * d2 }
```

### Shadowing, shared labels, and namespaces

If there are record types that share some labels, and we use dot notation, the type checker will infer the most recent type defined with that label.

```ocaml
type newratio = { num : int ; coeff : float } (* shadows ratio's label num *)

(* inferred type for x is newratio because its num field is more recent *)
let get_num x = 
  x.num
```

The solution is to avoid dot, or to use modules to avoid a global namespace of record labels.

Here are a few ways to make it clear which type is being used.

```ocaml
module A = struct
  type t = { x : int ; y : bool }
end

module B = struct
  type t = { x : int ; z : float }
end

let r = { x = 0 ; y = true } (* uh oh! It doesn't know label x because the types are inside modules *)

let r = { A.x = 0 ; y = true } (* this clears it up *)

let r = A.{ x = 0 ; y = true } (* so does this, and the difference rarely matters *)
```

Now if these modules are both opened, so that their `t` is put in scope, the most recent will win again.

```ocaml
open A
open B

let f r = r.x (* type inferred for r is B.t, just like with newratio *)

(* clarify with type annotation (prefered) *)
let f (r : A.t) : int = r.x

(* or with pattern matching *)
let f { x ; y = _ } = r.x

(* or namespace annotation (not so prefered here) *)
let f A.{ x ; _ } = r.x
let f { A.x ; _ } = r.x
```

### Record creation

Records can be **made** with punning, too. We previously only _extracted_ the label with punning. We can also _create_ with punning.

```ocaml
let make_ratio (num : int) (denom : int) =
  { num ; denom } (* sugar for { num = num ; denom = denom } *)

make_ratio 1 2
```

When there are many labels, and we want to copy a record and only change a few, we use the `with` keyword.
- Very useful for records with many fields
- Note that by "change" we do **not** mean a mutation. A new record is constructed.

```ocaml
let clear_bad_denom r =
  match r with
  | { denom = 0 ; _ } -> { r with num = 0 } (* same as { denom = r.denom ; num = 0 } *)
  | _ -> r

clear_bad_denom { num = 4; denom = 0 }
``` 

We can do this with more than one label, too.

```ocaml
type t = { a : int ; b : int ; c : int }

let r1 = { a = 0 ; b = 1 ; c = 2 }

let r2 = { r1 with b = 2 ; c = 3 } (* use semicolons to separate fields after "with" *)

let c = 4
let r3 = { r1 with b = 2 ; c } (* we can pun here, too! *)
```

### Records as variant payloads

When a variant constructor has many components to its payload, we may like to name them with records.

```ocaml
type gbu =
  | Good of { sugar : string ; units : int }
  | Bad of { spice : string ; units : int }
  | Ugly
```

The inner records (`{ sugar : string ; units : int }` and `{ spice : string ; units : int }`) don't need to be separately declared. The downside is they cannot be returned or typed on their own. They are only internal to the variant constructor.

```ocaml
let good_units_exn v =
  match v with
  | Good { units ; _ } -> units (* this works! *)
  | Bad _ | Ugly -> failwith "unhandled"

let good_units_exn v =
  match v with
  | Good r -> r.units (* so does this! *)
  | Bad _ | Ugly -> failwith "unhandled"

let return_good_record v =
  match v with
  | Good r -> r (* This is not allowed! Type error! We cannot let r escape. *)
  | Bad _ | Ugly -> failwith "unhandled"
```

We'll do this with our binary tree type to get nice naming with record notation:

```ocaml
type 'a bin_tree = 
  | Leaf 
  | Node of { data : 'a ; left : 'a bin_tree ; right : 'a bin_tree }
```

With this version, we don't have to remember the order of the triple. It's named for us, so we can't forget!
