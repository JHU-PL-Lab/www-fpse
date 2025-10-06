
## Idiomatic Functional Programming

* Design principles, design patterns, refactoring in Object-Oriented programming
             =>
  **Idioms** in Functional Programming
* We have touched on much of this so much of this is review


### FP Idioms

Here is a list of principles/idioms, many of which are review as we touched on them before

#### Don't Repeat Yourself (DRY from OO): 
  - Extract duplicate code into its own function
  - if there is common code except for one spot, make that spot a code (i.e.function) parameter
    - example: make a map function on a tree if you are doing many tree operations that are maps.
  - Code usually won't be exact duplicate; extract different bits as function parameters so the different bits are passed in
  - May also entail replacing specific types with generic types `'a` or functor parameter types `t`, `elt` etc

#### Hide it behind an interface
  - Modularity / focus of responsibility: Make clear divisions of responsibility between different modules and functions
  - Hiding minimizes what programmer-users have to think about, they can think at the higher (simpler) level of the interface
    - and, this again will take up less brain space since they are not seeing lots of low-level details.
  - If a function is auxiliary to only one other function, define it in the body of the latter.
     - i.e. `let f x = let aux y = ..<aux's body>.. in .. <f's body> ..`
  - If a function is not local to a single function but is not used outside its module, leave it out of the module type (the `.mli` file) which will hide it to module users
  - Make a new module for a new data type, and include operations on the type (only) in it
     - This is not just for generic data structures like `Map`/`Set`, it is for app-specific data structures
     - Example: `ChessBoard` is a nontrivial data type for a chess game, make it its own module
  - Hide types `t` in module types if users don't need to see the details

####  Generally avoid side effects
  - Recall how pure functional code is referentially transparent, the behavior is all in the interface with no "hidden" actions.
  - Side effect world view is a state machine vs functional view as a pipeline explicitly passing data on
  - Occasionally side effects will make code more concise, that is the only time to use them
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

"Concise is nice"
 - Goal of making code as short as possible
 - From the classic Strunk and White English writing guide:
     > A sentence should contain no unnecessary words, a paragraph no unnecessary sentences, for the same reason that a drawing should have no unnecessary lines and a machine no unnecessary parts
 - Concise code means that more information will fit in your brain's fixed-size working set

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

#### Speed
  - There is always a trade-off in programming between efficiency and elegance
  - Much of the time it is possible to prioritize concision, modularity, functional coding over efficiency
      - Note that Python and JavaScript are ~5-10 times slower than C or OCaml, a case in point for speed not a priority
  - **But**, sometimes speed really matters
    - When data sets get large or algorithms get complex
    - Do generally avoid high polynomial or exponential algorithms on potentially large inputs
    - Also pay more attention when data sets get extremely large, even n vs n log n gets noticeable there.
      - a functional `Map` may need to be replaced with a mutable `Hashtbl`
    - We won't cover performance any more today but there is a [whole lecture](efficiency.html) coming up on the topic.


### Examples of Idiomatic FP
<a name = "examples"></a>
Here are example codebases we will spend time inspecting and critiqueing.

#### Minesweeper
  * [Minesweeper](https://exercism.io/tracks/ocaml/exercises/minesweeper) at Exercism.io 
  * Its not the full game, just calculating the number of mines adjacent to each non-mine square
  * Example input/input:
    ```ocaml
      [ "  *  ";
        "  *  ";
        "*****";
        "  *  ";
        "  *  "; ]
     
      [ " 2*2 ";
        "25*52";
        "*****";
        "25*52";
        " 2*2 "; ]
    ```
      See [test.ml](../examples/minesweeper/test/test.ml) for more examples
    - Before getting into the code let's consider algorithms, there are two distinct approaches
      1. For each non-mine square look around it and add up the mines
      2. Or, for each mine square increment the count on all non-mine squares around it (start at 0)
    - The latter is fundamentally more difficult to do functionally
      - The grid will need to change (mutate) a great many times as counts bump up one by one
    - The former can produce the complete answer for a given cell in one go, no incrementalism
    - We will review [this functional solution](../examples/minesweeper/src/minesweeper.ml)
    - We made another [variation on the functional version](../examples/minesweeper/src/mine_array.ml) to be cleaner and more efficient
    - Will look at an [imperative approach](../examples/minesweeper/src/mine_mutate.ml) which has some  poor abstractions and fails to use combinators.

#### Other Examples
  * [ocaml-cuid](https://github.com/marcoonroad/ocaml-cuid) is a utility to generate highly random string IDs for webpages etc.
     - Lots of nice piping here plus use of functors to build Unix and JavaScript variations
  * [dolog](https://github.com/UnixJunkie/dolog) is a very simple logging utility
     - Shows some nice use of state, `include`, and a `Make` functor.
  * We may also look at a past homework solution so you can compare it with what you did.
