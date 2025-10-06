
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
    - We won't cover performance any more today but there is a [whole lecture](efficiency.html) coming up on the topic.

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
  - Functional code has everything in the interface so it will make a more accurate interface
    - This is not always good though: consider e.g. imperative `fresh_name : () -> string` making a different string each time called
      ```ocaml
      let counter = ref 0
      let fresh_name () : string = (counter := !counter + 1); "name"^(Int.to_string !counter)
      ```
    - To make a fresh string in functional code you would need to e.g. pass the previous count and return the next one.
      ```ocaml
      let fresh_name (previous : int) : (string * int) = ("name"^(Int.to_string previous), previous + 1)
      let (name1,count1) = fresh_name 0 in
      let (name1,count2) = fresh_name count1 in ...
      ```
      This is a more accurate interface to what freshness needs, but any function needing to make fresh names would need to be passed and return the current `count` value.  Yuck!
    - The difficulty for long-time imperative programmers is everything looks like a `fresh_name` case at first, it just seems impossible to write an elegant functional version.  Don't give up, you will learn!

#### Have a focus of responsibility
  - Each function and module should have a clear focus that can be summarized in a sentence
  - Divide one function/module into two if it is doing two different things
  - Don't add random stuff to a module if it doesn't fit with it's summary purpose
  - If you need more than is in an existing module, make a new one and `include` the old one

#### Concision

Many particular low-level points were already covered in the [FPSE Style Guide](../style-guide.md), here is a review:

  - **Combinize**: replace `let rec` with `map`s, `fold`s and the like
    - and, for your own data structures write your own combinators and then use in place of `rec`
  - Use advanced pattern matching (`as`, `with`, deep patterns, partial record patterns, `_`, etc)
  - Use `|>` in place of call sequences, and make your functions amenable to piping
    - To have pipes be effective, the best way is to follow `Core` and name the parameters that are not the underlying data you will often want to pipe on. For example `List.filter : 'a list -> f:('a -> bool) -> 'a list` and since `f` named can apply it first to make an `'a list -> 'a list` function ripe for piping:
    ```ocaml
     [2;5;-6;22] |> List.filter ~f:(fun x -> x < 0) |> List.is_empty |> not;;
     ```
  - Use `@@` in place of parentheses
  - Inline simple `let` definitions to make code read as a concise sentence
    - Also a small function called only once or twice may read better inlined
    - Conversely, make more `let` definitions if the code is too convoluted

Functional code is not always more concise than stateful code, but it is surprisingly good
- Let us revisit the [parenthesis matching](https://pl.cs.jhu.edu/fpse/examples/random-examples/matching.ml) example from the previous lecture on side effects.
- At the end of this file is a purely functional version of paren matching; the code is much more concise.

### Examples of Idiomatic FP
<a name = "examples"></a>
* Here are example codebases we will spend some time inspecting and critiqueing.

  * [Minesweeper](https://exercism.io/tracks/ocaml/exercises/minesweeper) at Exercism.io 
    - [This functional implementation](https://exercism.io/tracks/ocaml/exercises/minesweeper/solutions/ace26e2f446a4a18a3b1bad83dd9487c) shows several nice OCaml patterns. [Here](../examples/minesweeper/src/minesweeper.ml) is the version we reviewed in class which has several variations on the original implementation.
    - We made a [variation on the functional version](../examples/minesweeper/src/mine_array.ml) to be cleaner and more efficient
    - Will look at an [imperative approach](../examples/minesweeper/src/mine_mutate.ml) which has some really poor abstractions and fails to use combinators.
  * [ocaml-cuid](https://github.com/marcoonroad/ocaml-cuid) is a utility to generate highly random string IDs for webpages etc.
     - Lots of nice piping here plus use of functors to build Unix and JavaScript variations
  * [dolog](https://github.com/UnixJunkie/dolog) is a very simple logging utility
     - Shows some nice use of state, `include`, and a `Make` functor.
  * We may also look at a past homework solution so you can compare it with what you did.
