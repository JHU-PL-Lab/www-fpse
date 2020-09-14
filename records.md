
### Records
  - like tuples but with label names on fields
  - the types must be declared just like OCaml variants.
  - can be used in pattern matches as well.
  - again the fields are immutable by default (but there is a way to make them mutable ..)

A record type to represent rational numbers

```ocaml
type ratio = {num: int; denom: int};;
let q = {num = 53; denom = 6};;
q.num;;
q.denom;;
```

Pattern matching
```ocaml
let rattoint r =
 match r with
   {num = n; denom = d} -> n / d;;
```

Only one pattern matched so can again inline pattern in functions and lets
```ocaml
let rattoint {num = n; denom = d}  =
   n / d;;
```

Short-cut: pun between variable and field name (understand the above form before punning!!):

```ocaml
let rattoint {num; denom}  =  num / denom ;;
```


Can also use dot projections a la C etc, but happy path is usually patterns
```ocaml
let rattoint r  =  r.num / r.denom;;
rattoint q;;
```

```ocaml
let add_ratio r1 r2 = {num = r1.num * r2.denom + r2.num * r1.denom; 
                      denom = r1.denom * r2.denom};;
add_ratio {num = 1; denom = 3} {num = 2; denom = 5};;
```

Annoying shadowing issue when using dot: there is one global namespace of record labels
```ocaml
type newratio = {num: int; coeff: float};; (* shadows ratio's label num *)

fun x -> x.num;; (* x is a newratio, the most recent num field defined *)
```
Solution is to avoid dot.  You can also leave out unused fields in a pattern:

```ocaml
let numerator {num}  = num;;
```


### Other stuff

* record field name punning also in values: `let r = {x;y}` abbreviation
* `let r' = { r with x = ..; y = }`  for changing just a few fields
* Embedding record declarations in variants - like named args on variant fields:
`type gbu = | Good of { sugar : string; } | Bad of { spice: string; } | Ugly`
 - no need to declare sugar/spice as records, they are in fact not external records.
