
# Pre-processor extensions

Pre-Processor eXtensions (PPXs) write code for us. They save us from writing boilerplate code, so our code is shorter and (probably) more correct.

Some examples of code we could get from pre-processor extensions are:
- Print functions (`show`)
- Serialization (`sexp`, `yojson`)
- Comparison (`compare`, `equal`)
- Rank functions on variants (`variants`)

## `ppx_jane` and `deriving`

* In the variants lecture, we wrote a `nucleotide` type and derived an equality function for it.
* We put `[@@deriving equal]` in the nucleotide example to get an `=` on that type "for free":
  * In the top loop, use `#require "ppx_jane"` to load the pre-processor extension.
  * In dune, put `(preprocess (pps (ppx_jane)))` as part of the library declaration.

```ocaml
# type nucleotide = A | C | G | T [@@deriving equal];;
type nucleotide = A | C | G | T
val equal_nucleotide : nucleotide -> nucleotide -> bool = <fun>
```

* We defined our type **and** got the `equal_nucleotide` function.
  * In `Core`, it is idiomatic to name types `t`. If we derive a function from a type named `t`, we wouldn't get `equal_t`, we would just get `equal`.
* `[@@zibbo...]` notation in code indicates the line is processed by the macro named `ppx_zibbo`
* The `equal` is a parameter to the macro, here it is which `deriving` extension is added
* The `[@@deriving equal]` in particular causes an `equal_nucleotide` function to be automatically generated
* Without this function we would have to use pattern matching to write our own equality.

### Composing `deriving equal`

* If we have an `xyy_equal` function on component types, `deriving` can derive `equal` for a type built from those components. For example equality on *lists* of nucleotides:

```ocaml
# type n_list = nucleotide list [@@deriving equal];;
type n_list = nucleotide list
val equal_n_list : n_list -> n_list -> bool = <fun>

# equal_n_list [A;A;A] [A;G;A];;
- : bool = false

# type n_queue = nucleotide Queue.t [@@deriving equal];;
type n_queue = nucleotide Core.Queue.t
val equal_n_queue : n_queue -> n_queue -> bool = <fun>
```
* Notice that the `Core` libraries are designed to play well as they have `List.equal`, `Queue.equal` built in
  - But, `List.equal : ('a -> 'a -> bool) -> 'a list -> 'a list -> bool` -- it needs `=` on the underlying list data.
  - This is a bit annoying as you keep having to pass `=` for members to check `'` for lists
  - .. we will eventually see an alternative to this when we learn about functors in the modules lecture.
* Note that in general for a component type that is the `t` of a module, the name looked for is `My_module.equal` instead of `equal_t`
  - This is standard for types named `t`, and we saw that above when deriving, too. 

### Some other useful `@@deriving` type accessor extensions in ppx_jane

* `sexp` generates S-expression printable representations of types which is handy for displaying data internals 
 - S-expressions are a general data format like JSON or XML, in fact they are the first such format

```ocaml
# type nucleotide = A | C | G | T [@@deriving equal, sexp];;
type nucleotide = A | C | G | T
val equal_nucleotide : nucleotide -> nucleotide -> bool = fun
val nucleotide_of_sexp : Sexp.t -> nucleotide = fun
val sexp_of_nucleotide : nucleotide -> Sexp.t = fun

# type n_list = nucleotide list [@@deriving equal, sexp];;
type n_list = nucleotide list
val equal_n_list : n_list -> n_list -> bool = fun
val n_list_of_sexp : Sexp.t -> n_list = fun
val sexp_of_n_list : n_list -> Sexp.t = fun

# sexp_of_n_list [A;G;G];;
- : Sexp.t = (A G G) (* this is the "S-Expression" version of a list.. parens and spaces *)

# n_list_of_sexp (Sexp.of_string "(A G G)");; (* how to convert in the other direction *)
- : n_list = [A; G; G]
```

* `[@@deriving compare]` is like `equal` except it makes a `compare` function instead of `equal`
* We covered this in the variants lecture

```ocaml
# type nucleotide = A | C | G | T [@@deriving compare];;
type nucleotide = A | C | G | T
val compare_nucleotide : nucleotide -> nucleotide -> int = fun

# compare_nucleotide A C;;
- : int = -1

# compare_nucleotide C A;;
- : int = 1
```


### JSON format

* JSON is a common standard for data-as-text and may be useful in your project
* `Core` does not have libraries for dealing with JSON unfortunately.
  - `sexp` is the "JSON for Core"
  - Anywhere you want to use JSON, just settle for S-expressions if you want to also use Core.
* If you need JSON conversion, use `ppx_deriving_yojson` which works with the `yojson` library to do something like what `deriving sexp` above did.
* **Aside**: `ppx_deriving_yojson` is not compatible with `ppx_jane` so if you want to derive equality and comparisons along with `yojson` you need to use `#require "ppx_deriving.eq";; / [@@deriving eq]` and `#require "ppx_deriving.ord";; / [@@deriving ord]` in place of the `equal/compare` deriving in `ppx_jane`. `ppx_deriving show`, which prints variant type data, is also not compatible with `ppx_jane`.
