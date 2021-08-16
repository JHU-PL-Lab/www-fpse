
### Records
  - Records are like tuples, a data combiner, but with label names added for readability
  - Record types must be declared just like OCaml variants.
  - Again the fields are immutable by default (but there is a way to make them mutable ..)

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

Only one pattern matched so can again inline pattern in functions and lets
```ocaml
let rattoint {num = n; denom = d}  =  n / d;;
```

Short-cut: pun between variable and field name (understand the above form before punning!!):

```ocaml
let rat_to_int {num; denom}  =  num / denom ;;
```

Another short-cut if you only care about a few fields (very useful for a big record):
```ocaml
let get_num {num; _}  =  num;;
```
 - This is a special form of pattern, "`; _`" at the *end* of a record means don't-care on all the missing fields.

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
Pattern equivalent (can't pun here because there are two records of same type):
```ocaml
let add_ratio {num = n1; denom = d1} {num = n2; denom = d2} = 
{num = n1 * d2 + n2 * d1; denom = d1 * d2};;
add_ratio {num = 1; denom = 3} {num = 2; denom = 5};;
```

Annoying shadowing issue when using dot: there is one global namespace of record labels
```ocaml
type newratio = {num: int; coeff: float};; (* shadows ratio's label num *)

fun x -> x.num;; (* x is inferred a newratio, the most recent num field defined *)
```
Solution is to generally avoid dot; or declare `x`'s type if needed.  

```ocaml
fun (x : ratio) -> x.num;; (* x is declared a ratio, avoiding previous shadowing *)
```
* You can often leave out unused fields in a pattern:

```ocaml
let numerator {num}  = num;;
```
* More punning.. if you can also *use* variables with the right names as a pun

```ocaml
let make_ratio num denom = {num;denom};;
make_ratio 1 2;;
```

* Here is another shorthand for changing just some of the fields: `{r with ...}`
  - Very useful for records with many fields, not so much here though
  - Note "change" is not mutation again, it constructs a new record.

 ```ocaml
let clear_bad r =
match r with
  | {denom = 0 } ->  {r with num = 0}
  | _ -> r;;
clear_bad {num = 4; denom = 0};;
``` 

* One more nice feature: labeling components of variants with records

```ocaml
type gbu = | Good of { sugar : string; units : int} | Bad of { spice: string; units : int} | Ugly
```
* Observe that these inner record types don't need to be separately declared
* Note that the "internal records" here are just that, internal -- you can only use a `{sugar;units}` records inside a `Good` variant.

Let's re-visit our binary tree type and use record notation instead.

```ocaml
type 'a binnier_tree = Leaf | Node of {data :'a ; left : 'a binnier_tree; right : 'a binnier_tree}
```

* Using this version we don't have to remember the order of the triple
