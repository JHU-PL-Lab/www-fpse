## Efficiency in Functional Programming

* Our main goal is conciseness, but in some cases efficiency does matter
* We already discussed this issue a bit (e.g. cons vs append, tail recursion)
* Here is more detail on efficiency considerations
* We will conclude with some examples

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
 * `Map` is implemented like the `dict` of the homework: a binary search tree
 * O(log n) worst case time for `Map` to look up, add, or change an entry
   - only the path to the changed node needs updating, all the sub-trees hanging off it are kept
 * "O(1) amortized" for `Hashtbl` - will only matter for really big data sets.
 * *But*, like arrys hash tables can't be shared, need to manually copy instead
   - If you have a map you want to keep many versions of around, `Map` will beat `Hashtbl`.x

`Set` vs `Hash_set`
* See previous, `Set` is like `Map` and `Hash_set` is like `Hashtbl`

* [Here is a summary of OCaml data structure complexity](https://ocaml.org/learn/tutorials/comparison_of_standard_containers.html) (for the standard OCaml library but same results as `Core` version)

Summary: functional data structures
  - Feel like they should be much more inefficient but its often "at worst a log factor"
  - In a few cases they are actually better because past states "persist for free"
    - e.g. sub-lists can be shared since copying never needed, etc
    - See [Real World OCaml benchmarks (scroll down)](https://dev.realworldocaml.org/maps-and-hashtables.html) for example benchmarks of this
  - In a few cases speed is critical and mutable structures are required


### Case Study: Monadic Minesweeper

* Let us analyze the complexity of different implementations of Minesweeper.
* Assume a grid of n elements (a square-root n by square-root n grid)


Our initial implementation  [using a list of strings](../examples/minesweeper/src/minesweeper.ml)
* Each call to `get x y` is O(sqrt n) since we need to march down the lists to find element (x,y)
* So O(sqrt n) for each inc operation so O(n * sqrt n) overall.

Our implementation  [using a functional 2D array](../examples/minesweeper/src/mine_array.ml)
* The array is in fact never mutated, only used for random access to fixed array
* Otherwise this implementation is the same as the above
* `get x y` is now O(1) since it is an array -- random access.
* O(1) for each inc operation so O(n) in total.

Stateful version [using an array](../examples/minesweeper/src/mine_mutate.ml)
* Instead of counting mines around each empty square once and for all, for each mine increment all its non-mine neighbors
* It is a fundamentally mutating alternative algorithm.
* O(n) as with the previous functional array version

Monadic state version 
* A  [state monad version of the original minesweeper](../examples/minesweeper/src/mine_monadic.ml)
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
