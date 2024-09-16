
### Records
  - Records are like tuples, an and-data combiner (this-and-this-and-this), but with label names added for readability
    - Yes it is mainly about readability but it can make a big difference in code quality
  - Record types must be declared with `type` just like OCaml variants
  - Record fields are immutable by default, **but** there is a way to make them mutable (below)

Example: a simple record type to represent rational numbers

```ocaml
type ratio = {num: int; denom: int};;
let q = {num = 53; denom = 6};;
```

Pattern matching
```ocaml
let rattoint r =
 match r with
   {num = n; denom = d} -> n / d;;
```

Only one pattern is matched so can inline the pattern in `fun`ctions and `let`s
```ocaml
let rattoint {num = n; denom = d}  =  n / d;;
```

Short-cut: pun between variable and field name (understand the above form before punning!!):

```ocaml
let rat_to_int {num; denom}  =  num / denom ;;
```

which is just sugar for 

```ocaml
let rat_to_int {num = num; denom = denom}  =  num / denom ;;
```
 - be clear that the first `num =`/`denom =` are *labels* and the others are *variables*; same as in many languages.


Another short-cut if you only care about a few fields (very useful for a big record):
```ocaml
let numerator {num; _}  =  num;; (* _ here means "plus any other fields" )
```
or even this:
```ocaml
let numerator {num}  = num;;
```

Can also use dot projections a la C etc, but happy path is usually patterns
```ocaml
let rattoint r  =  r.num / r.denom;;
```

* Dot notation to make an addition of ratios:

```ocaml
let add_ratio r1 r2 = {num = r1.num * r2.denom + r2.num * r1.denom; 
                      denom = r1.denom * r2.denom};;
add_ratio {num = 1; denom = 3} {num = 2; denom = 5};;
```
Preferred pattern equivalent (can't pun here because there are two records of same type):
```ocaml
let add_ratio {num = n1; denom = d1} {num = n2; denom = d2} = 
{num = n1 * d2 + n2 * d1; denom = d1 * d2};;
```

Annoying shadowing issue when using dot: there is one global namespace of record labels
```ocaml
type newratio = {num: int; coeff: float};; (* shadows ratio's label num *)

fun x -> x.num;; (* x is inferred a newratio, the most recent num field defined *)
```
Solution is to avoid dot

* Multiple punning.. pun both on parameters and in record creation

```ocaml
let make_ratio (num : int) (denom : int) = {num; denom};;
make_ratio 1 2;;
```

* Here is a shorthand for changing just some of the fields: `{r with ...}`
  - Very useful for records with many fields
  - Note "change" still is not mutation, it constructs a new record.

 ```ocaml
let clear_bad_denom r =
match r with
  | { denom = 0 } ->  { r with num = 0 } (* can leave off ignored fields in pattern *)
  | _ -> r;;
clear_bad_denom { num = 4; denom = 0 };;
``` 

* One more nice feature: labeling components of variants with records

```ocaml
type gbu = | Good of { sugar : string; units : int } | Bad of { spice: string; units : int } | Ugly
```
* Observe that these inner record types don't need to be separately declared
* Note that the "internal records" here are just that, internal -- you can only use a `{sugar;units}` records inside a `Good` variant.

Let's re-visit our binary tree type and use record notation instead.

```ocaml
type 'a bin_tree = Leaf | Node of {data :'a ; left : 'a bin_tree; right : 'a bin_tree}
```

* Using this version we don't have to remember the order of the triple
