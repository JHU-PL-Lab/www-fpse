
# Pre-processor extensions

* Pre-Processor eXtensions (PPXs) are macros, they write code for us. 
* They save us from writing boilerplate code, so our code is shorter and (probably) more correct.
* We got a peek at some `ppx` extensions when looking at how to properly define equality in the variants lecture.

Some examples of boilerplate code ppx extensions can produce include
- Print functions (`show`)
- Serialization (`yojson`) (turning arbitrary OCaml data into strings)
- Comparison (`compare`, `eq`)

## `ppx_deriving`

* In the variants lecture, we showed how `[@@deriving eq]` added to a tree type would automatically write the code for an equality on elements of that type. 
  * In the top loop, type `#require "ppx_deriving.eq"` to load it
  * In dune, put `(preprocess (pps (ppx_deriving.eq))` as part of the library declaration
* For the nucleotide example we could just use the built-in `=` but we could have also used a `ppx` to make it:

```ocaml
# type nucleotide = A | C | G | T [@@deriving eq];;
type nucleotide = A | C | G | T
val equal_nucleotide : nucleotide -> nucleotide -> bool = <fun>
```

* We defined our type **and** got the `equal_nucleotide` function for free.

### Composing `deriving equal`

* If we have an `xyy_equal` function on component types, `deriving` can derive `equal` for a type built from those components. For example equality on *lists* of nucleotides:

```ocaml
# type n_list = nucleotide list [@@deriving eq];;
type n_list = nucleotide list
val equal_n_list : n_list -> n_list -> bool = <fun>

# equal_n_list [A;A;A] [A;G;A];;
- : bool = false

# type n_queue = nucleotide Queue.t [@@deriving equal];;
type n_queue = nucleotide Core.Queue.t
val equal_n_queue : n_queue -> n_queue -> bool = <fun>
```

* Note that in general for a component type that is the `t` of a module, the name is `My_module.equal` instead of `equal_t` (we will see this later)

### Some other useful `@@deriving` macros

* `[@@deriving compare]` is like `equal` except it makes a `compare` function instead of `equal`

```ocaml
# type nucleotide = A | C | G | T [@@deriving compare];;
type nucleotide = A | C | G | T
val compare_nucleotide : nucleotide -> nucleotide -> int = fun

# compare_nucleotide A C;;
- : int = -1

# compare_nucleotide C A;;
- : int = 1
```
Note that existing types such as `int`, `string`, etc come with `Int.compare`, `String.compare`, etc, along with the `Int.equal`, `String.equal`.

* `[@@deriving show]` produces a pretty-printing function for your type
* Super helpful for debugging
```ocaml
type nucleotide = A | C | G | T [@@deriving eq, show];; (* example of multiple ppxs together *)
type n_list = nucleotide list [@@deriving eq, show];;
show_n_list [A;C;C];; (* returns the string  "[A; C; C]" *)
```
* Enable use in top loop with directive `#require "ppx_deriving.show"` and add to a library as `(preprocess (pps (ppx_deriving.show))`

* An easy short-cut is to use `std`: `#require "ppx_deriving.std"` and `(preprocess (pps ppx_deriving.std))`, which gives you `show`,`eq`,`ord`, and some others all in one go.
TODO: add this to .ocamlinit?

### JSON format

* JSON is a common standard for data-as-text and may be useful in your project
* If you need JSON conversion, use `ppx_deriving_yojson` which works with the `yojson` library (notice its `_yojson` not `.yojson` - its someone elses library)

```ocaml
#require "ppx_deriving_yojson";;
# type nucleotide = A | C | G | T [@@deriving yojson];;
type nucleotide = A | C | G | T
val nucleotide_to_yojson : nucleotide -> Yojson.Safe.t = <fun>
val nucleotide_of_yojson :
  Yojson.Safe.t -> nucleotide Ppx_deriving_yojson_runtime.error_or = <fun>
# type n_list = nucleotide list [@@deriving yojson];;
type n_list = nucleotide list
val n_list_to_yojson : n_list -> Yojson.Safe.t = <fun>
val n_list_of_yojson :
# let j = n_list_to_yojson [A;G;G];;
j : Yojson.Safe.t =
`List [`List [`String "A"]; `List [`String "G"]; `List [`String "G"]]
# let s = Yojson.Safe.to_string j;; (* function to get you the actual JSON *)
val s : string = "[[\"A\"],[\"G\"],[\"G\"]]" (* this is a json rep'n of a list *)
```