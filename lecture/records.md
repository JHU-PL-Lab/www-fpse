
## Records
- Records make **and** data: they have this-and-this-and-this
- Tuples also make **and** data, but records have labels for each component
  - Labels help with type checking and readability
- Record fields are immutable by default
  - (We'll see a way to make them mutable in a future lecture on side effects)


Note that a record type must be declared before you make any values with that type
 - similar to variants, but not like inferred variants or tuples

```ocaml
let rat = { num = 5; denom = 7 } (* doesn't work! Its type isn't defined yet *)
```

So let's define the type:
```ocaml
type ratio = { num : int ; denom : int }
```

This defined the `ratio` type, a record type with two labels:
- `num` is label with an `int` value.
- `denom` is a label with an `int` value, too.

To make a value of a type simply replace the `:` with `=`:
```ocaml
let q = { num = 53 ; denom = 6 }
```

### Taking apart records

There are many ways to take apart record values.

1. Follow C/C++/Java/JS/Python etc: dot notation.

```ocaml
let rat_to_int r =
  r.num / d.denom (* project the labels out from r *)
```

2. Pattern matching

```ocaml
let rat_to_int r =
  match r with
  | { num = n ; denom = d } -> n / d (* variable n contains numerator, d contains denominator *)
```
- Note that `num =` and `denom =` are the **labels**, and `n` and `d` are **variables**. This is just like an object or struct field name vs a variable name in Java/C/C++/etc.

3. Punning by reusing the field name as a variable

The following pun binds the *fields* `num` and `denom` from `r` straight into those same names as *variables*:

```ocaml
let rat_to_int r =
  match r with
  | { num ; denom } -> num / denom (* sugar for { num = num ; denom = denom } -> .. *)
```

4. Inlining pattern matchings with `let` 

Pattern `match`ing on only one pattern is too verbose, don't do it.  Like with pairs, we can put the (sole) pattern as a function parameter or in a `let` definition.

```ocaml
let rat_to_int { num = n ; denom = d } = (* pattern as a function parameter *)
  n / d

let rat_to_int { num ; denom } = (* pattern parameter plus punning on labels/variables *)
  num / denom

let rat_to_int r =
  let { num ; denom } = r in (* pattern in a value let definition *)
  num / denom
```

5. Yet another shortcut, `; _` can be used for dont-care fields:

```ocaml
let numerator { num ; _ } = (* the _ catches all the other labels, no matter how many there are *)
   num 
```

### Shadowing, shared labels, and namespaces

If there are record types that share some labels, and we use dot notation, the type inferencer will infer the most recent type defined with that label.

```ocaml
type newratio = { num : int ; coeff : float } (* shadows above ratio type's label num *)

(* Inferred type for x is newratio because its num field is more recent *)
let get_num x = 
  x.num

(* Resolve the ambiguity by explicitly declaring x's type *)
let get_new_num (x : newratio) = 
  x.num
```

### Puns for record creation

```ocaml
let make_ratio (num : int) (denom : int) =
  { num ; denom } (* sugar for { num = num ; denom = denom } *)

make_ratio 1 2
```

When there are many labels and you are making a new record with only a few fields changed, use `with`:

```ocaml
type abc = { a : int ; b : int ; c : int }

let r1 = { a = 0 ; b = 1 ; c = 2 }

let r2 = { r1 with a = 4 } (* same as writing { a = 4; b = r1.b; c = r1.c } - implicitly copy over others *)
(* Note this is a COPY, NOT a mutate - ! *)

let r2 = { r1 with b = 2 ; c = 3 } (* use semicolons for multiple overrides *)

let c = 4
let r3 = { r1 with b = 2 ; c } (* combining puns, `c = c` can again shorten to `c` *)
```

### Records as variant payloads

When a variant constructor has many components to its payload, name them with records.

```ocaml
type gbu =
  | Good of { sugar : string ; units : int }
  | Bad of { spice : string ; units : int }
  | Ugly
```

The inner records (`{ sugar : string ; units : int }` and `{ spice : string ; units : int }`) don't need to be defined on their own. The downside is they cannot be returned or typed on their own. They are only internal to the variant constructor.

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

For a binary tree type the record labels are handy so you don't get the order mixed up

```ocaml
type 'a bin_tree = 
  | Leaf 
  | Node of { data : 'a ; left : 'a bin_tree ; right : 'a bin_tree }
```

If you write `{left = Leaf; node = 5; right = Leaf}` you are still fine
 - like with named function arguments the order doesn't matter if there is a name that disambiguates