## Case Studies of Efficiency in Functional Programming

* We already covered efficiency general concepts in the [idiomatic FP lecture](https://pl.cs.jhu.edu/fpse/lecture/idiomatic-fp.html#efficiency)
* It is sometimes important to analyze runtime complexity to make sure the price of using a functional data structure is not too high.


### Case Study: Monadic Minesweeper

* Let us analyze the complexity of different implementations of Minesweeper.
* Assume a grid of n elements (a square-root n by square-root n grid)


Our initial implementation  [using a list of strings](https://pl.cs.jhu.edu/fpse/examples/minesweeper.ml)
* Each call to `get x y` is O(sqrt n) since we need to march down the lists to find element (x,y)
* So O(sqrt n) for each inc operation so O(n * sqrt n) overall.

Our implementation  [using a functional 2D array](https://pl.cs.jhu.edu/fpse/examples/mine_array.ml)
* The array is in fact never mutated, only used for random access to fixed array
* Otherwise this implementation is the same as the above
* `get x y` is now O(1) since it is an array -- random access.
* O(1) for each inc operation so O(n) in total.

Stateful version [using an array](https://pl.cs.jhu.edu/fpse/examples/mine_mutate.ml)
* Instead of counting mines around each empty square once and for all, for each mine increment all its non-mine neighbors
* It is a fundamentally mutating alternative algorithm.
* O(n) as with the previous functional array version

Monadic state version 
* A  [state monad version of the original minesweeper](https://pl.cs.jhu.edu/fpse/examples/mine_monadic.ml)
* We will follow the data structure of the original minesweeper, the list of strings
* But do the imperative increment-the-mine-neighbors instead of the functional count-the-mines
* Each grid square increment will take O(n) since the whole list of strings has to be rebuilt with one change
  - there is some functional sharing of parts not incremented (as in list append above) but means 1/2 n = O(n)
* O(n) inc's are performed total so it will be O(n^2).
* So a bit of a backfire

Imagine an alternative state monad implementation with `Board` state implemented as a `Core.Map` from keys `(i,j)` to characters:
* Lookup and increment will be O(log n) on average since `Core.Map` is implemented as a balanced binary search tree
    - one change to a Map's tree is only log n because only one path in tree is changed, rest can be re-used
    - (yes, one path down a binary tree is only 1/(log n)-th of the tree nodes, and the sub-trees can be reused)
* So total time is O(n log n)

Conclusion
* For Minesweeper, O(n^2) is in fact fine as the grids are always "tiny" in a CPU sense
* But if this grid was instead a large image (pixel grid) this would be intolerable
* With correct functional data structure choices you can often just pay a log n "fee" which will often be fine
  - or even less, witness the functional array solution above
* And, sometimes you just need to get out the imperative `Array`, `Hashset` etc.
* Also recall the Real World OCaml example comparing an [(immutable) Map vs a (mutable) Hashtable](https://dev.realworldocaml.org/maps-and-hashtables.html#time-complexity-of-hash-tables)
  - For standard uses a mutable hashtable will be "O(1)" vs O(log n) for a `Map` version
  - But if there are many minor variations on the Map/Hashset being created the functional data structure will in fact be faster due to all the sharing.
  - Functional can be a big win for a few classes of algorithms (but admitedly not most)

#### FP and paralellism

* In pure FP with no side effects, any independent computation can be done in parallel
* Example: `List.map` could apply `f` on the list elements in parallel
  - but, reconstructing the list has to be in-order so only useful for slow-running `f`'s
  - Also `fold` and the like can't be easily parallelized since the `accum` needs to be passed along sequentially
* Multiple function arguments can be evaluated in parallel if they contain no effects
  - Referential transparency in general makes parallelism much easier to get right
* OCaml also now has parallelism starting with OCaml 5 - [here is a tutorial](https://github.com/ocaml-multicore/parallel-programming-in-multicore-ocaml).


### Writing more efficient functions

* We already covered tail recursion
  - Tail recursion principle: if the last action in a function is a recursive call, compiler can optimize away the call stack
  - Moral: optimize deep recursive functions (e.g. working on long lists) to be tail-recursive if possible
* Let us consider one more now.

#### Memoization

* If a function has no side effects it can easily be *memoized*
   - We saw in the homework how it could take an exponential fibbonicci to linear
   - In general memoization works when there are no effects in the function (and, we have an `=` defined on the arguments)
   - As you saw in the homework, implement memoization by keeping a history of past input -> output pairs and look up input in table first
   - If the function is expensive and is often invoked on the same argument it will be very effective

* Note that memoization implicitly needs a store for this past history
* Could use mutable store, but could also use a state monad
  - pass in and return the store in the memoized function


## Algebraic Effects

If we have extra time we will cover the interesting side topic of [algebraic effects](algebraic_effects.ml): exceptions that can be resumed.
