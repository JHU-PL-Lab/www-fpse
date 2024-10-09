
## Idiomatic Functional Programming

* Design principles, design patterns, refactoring in Object-Oriented programming
             = 
  **Principles & idioms** in Functional Programming
* **Principles**: overarching principles; **Idioms**: more focused ideas to aid in achieving principles
* We have touched on much of this so much of this is review

### FP Principles

1. "Concise is nice"
 - Goal of making code as short as possible
 - From the classic Strunk and White English writing guide:
     > A sentence should contain no unnecessary words, a paragraph no unnecessary sentences, for the same reason that a drawing should have no unnecessary lines and a machine no unnecessary parts
 - Concise code means that more information will fit in your brain's fixed-size working set
2. Modularity / focus of responsibility
  - Make clear divisions of responsibility between different modules and functions
  - Attempt to make this factoring of responsibilities the most elegant which will aid in theme 1. above.
3. Generally avoid side effects; it will help you achieve 1. and 2.
  - Recall how pure functional code is referentially transparent, the behavior is all in the interface with no "hidden" actions.
  - Side effect world view is a state machine vs functional view as a pipeline explicitly passing data on
  - Occasionally side effects will make code more concise, that is when to use them
4. Speed
  - There is always a trade-off in programming between efficiency and elegance
  - Much of the time it is possible to prioritize concision and modularity over running time and space
      - Note that Python and JavaScript are ~5-10 times slower than C or OCaml, a case in point for speed not a priority
  - **But**, sometimes speed really matters
    - When data sets get large or algorithms get complex
    - Do generally avoid high polynomial or exponential algorithms on potentially large inputs
    - Also pay more attention when data sets get extremely large, even n vs n log n gets noticeable there.

### FP Idioms

Here is a list of idioms, many of which are review as we touched on them before

#### Don't Repeat Yourself (DRY from OO): 
  - Extract duplicate code into its own function
  - if there is common code except for one spot, make that spot a code (i.e.function) parameter
    - example: make a map function on a tree if you are doing many tree operations that are maps.
  - Code usually won't be exact duplicate; extract different bits as function parameters so the different bits are passed in
  - May also entail replacing specific types with generic types `'a` or functor parameter types `t`, `elt` etc

#### Hide it behind an interface
  - Hiding minimizes what programmer-users have to think about, they can think at the higher (simpler) level of the interface
    - and, this again will take up less brain space since they are not seeing lots of low-level details.
  - If a function is auxiliary to only one other function, define it in the body of the latter.
     - i.e. `let f x = let aux y = ..<aux's body>.. in .. <f's body> ..`
  - If a function is not local to a single function but is not used outside its module, leave it out of the module type (the `.mli` file) which will hide it to module users
  - Make a new module for a new data type, and include operations on the type (only) in it
     - This is not just for generic data structures like `Map`/`Set`, it is for app-specific data structures
     - Example: `ChessBoard` is a nontrivial data type for a chess game, make it its own module
  - Hide types `t` in module types if users don't need to see the details
  - Functional code has everything in the interface so it will make a more precice interface
    - Or on the other hand perhaps you can have a simpler interface if it is imperative, e.g. `fresh_name : () -> string` making a different string each time called

#### Have a focus of responsibility
  - Each function and module should have a clear focus that can be summarized in a sentence
  - Divide one function/module into two if it is doing two different things
  - Don't add random stuff to module if it doesn't fit with it's summary purpose
  - If you need more than is in an existing module, make a new one and `include` the old one

#### Concision

(Most of this was already covered in the [FPSE Style Guide](../style-guide.md))

  - **Combinize**: replace recursion with `map`s, `fold`s and the like
    - and, for your own data structures write your own combinators and then use in place of `rec`
  - Use advanced pattern matching (`as`, `with`, deep patterns, partial record patterns, `_`, etc)
  - Use `|>` in place of call sequences, and make your functions amenable to piping
    - Make sure to have the underlying pipe-type be the *first* unnamed parameter
    - Core solution: name most of the parameters in `List` etc (but not the list)
  - Use `@@` in place of parentheses
  - Inline simple `let` definitions to make code read as a concise sentence
    - Also a small function called only once or twice may read better inlined
    - Conversely, make more `let` definitions if the code is too convoluted

<a name ="efficiency"></a>
## Efficiency

* Our main goal is conciseness, but in some cases efficiency does matter
* We already discussed this issue a bit (e.g. cons vs append, tail recursion)
* Here is more detail on efficiency considerations
* We will also cover some case studies in the [efficiency lecture](./efficiency.html).

### Tail recursion

* We covered this earlier: `List.fold_left` is tail-recursive whereas `List.fold_right` is not
* A tail-recursive function is a function where there is no work to do after returning from recursive calls
  - Just bubble up the result
* Observation: since there is no need to mark the call point to resume from, no stack is needed
 - Overwrite the parameters going "down", and return the base case as the final result of the recursion.
* Compilers can see which functions are tail-recursive and eliminate the stack
* Moral: to save space/time you may need to tail-call

### Imperative vs functional data structures

Let us warm up reviewing `'a list` efficiency

* `hd` and `tl` are O(1)
* `List.nth` is O(n) -- lists are not random access
* `append l1 l2` is O(`length l1`) - cons each `l1` elt onto `l2` one by one

Remember that sub-lists are shared since they are immutable

```ocaml
let l1 = [1;2;3;... n] in
let l2 = 0    :: l1 in
let l3 = (-1) :: l1 in ..
```

* `l2` and `l3` share `l1` and all the above is O(1)
* If lists were mutable such sharing would not generally be possible

`List` vs `Array`
 * Adding an element to the front (extending list) is constant time for list, O(n) for array 
   - array needs to be copied to get more memory
   - different lists can share tail due to referential transparency
 * Update of one element in an array is O(1); updating one element of a list is worst-case O(n) - re-build whole list
 * Random access of nth element: O(n) list, O(1) array.
 * If you want fast random access to a "list" that is not growing / shrinking / changing, use an `array`.

`Map` vs `Hashtbl`
 * `Map` is implemented like the `dict` of the homework
 * O(log n) worst case time for `Map` to look up, add, or change an entry
   - only the path to the changed node needs updating, all the sub-trees hanging off it are kept
 * "O(1) amortized" for `Hashtbl` - will only matter for really big data sets.

`Set` vs `Hash_set`
* See previous, `Set` is like `Map` and `Hash_set` is like `Hashtbl`

* [Here is a summary of OCaml data structure complexity](https://ocaml.org/learn/tutorials/comparison_of_standard_containers.html) (for the standard OCaml library but same results as `Core` version)

Summary: functional data structures
  - Feel like they should be much more inefficient but its often "at worst a log factor"
  - In a few cases they are actually better because past states "persist for free"
    - e.g. sub-lists can be shared since copying never needed, etc
    - See [Real World OCaml benchmarks (scroll down)](https://dev.realworldocaml.org/maps-and-hashtables.html) for example benchmarks of this
  - In a few cases speed is critical and mutable structures are required


### Examples of Idiomatic FP
<a name = "examples"></a>
* Here are example codebases we will spend some time inspecting and critiqueing.

  * [Minesweeper](https://exercism.io/tracks/ocaml/exercises/minesweeper) at Exercism.io 
    - [This functional implementation](https://exercism.io/tracks/ocaml/exercises/minesweeper/solutions/ace26e2f446a4a18a3b1bad83dd9487c) shows several nice OCaml patterns. [Here](../examples/minesweeper.ml) is the version we reviewed in class which has several variations on the original implementation.
    - We made a [variation on the functional version](../examples/mine_array.ml) to be cleaner and more efficient
    - Will look at an [imperative approach](../examples/mine_mutate.ml) which has some really poor abstractions and fails to use combinators.
  * [ocaml-cuid](https://github.com/marcoonroad/ocaml-cuid) is a utility to generate highly random string IDs for webpages etc.
     - Lots of nice piping here plus use of functors to build Unix and JavaScript variations
  * [dolog](https://github.com/UnixJunkie/dolog) is a very simple logging utility
     - Shows some nice use of state, `include`, and a `Make` functor.
  * We may also look at a past homework solution so you can compare it with what you did.
