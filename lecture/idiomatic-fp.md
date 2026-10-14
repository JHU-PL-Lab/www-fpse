## Examples of Idiomatic FP

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
        "  *  ";n
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
    - All of these minesweeper versions are in this [zip file](../examples/zips/minesweeper.zip)

#### Other Examples
  * We will review Brandon's solution to Assignment 4

Here are a few other examples of full projects which are worth looking at:

  * [ocaml-cuid](https://github.com/marcoonroad/ocaml-cuid) is a utility to generate highly random string IDs for webpages etc.
     - Lots of nice piping here plus use of functors to build Unix and JavaScript variations
  * [dolog](https://github.com/UnixJunkie/dolog) is a very simple logging utility
     - Shows some nice use of state, `include`, and a `Make` functor.
