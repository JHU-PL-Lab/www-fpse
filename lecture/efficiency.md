## Efficiency in Functional Programming

Functional data structures: 
    - Feel very inefficient at first
    - This is supported by asymptotics
    - But they are often fine in practice even if asymptotic behavior is worse
    - in a few cases they are better because past states "persist for free"

We covered some of this in the [idiomatic FP lecture](https://pl.cs.jhu.edu/fpse/lecture/idiomatic-fp.html#efficiency)

### Functional lists
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
* if lists were mutable such sharing would not generally be possible!
* In general this shows there is a trade-off in that in some cases functional wins
   - more on this below
### Case Study: Monadic Minesweeper

* Let us analyze the complexity of different implementations of the imperative Minesweeper.
* Assume a grid of n elements (a square-root n by square-root n grid)


Our imperative implementation using a 2D array ([this one](https://pl.cs.jhu.edu/fpse/examples/mine_array.ml))
* O(1) for each inc operation so O(n) in total.

Hypothetic monadic state version 
* Take the imperative 2D array version, implement as state monad on list-of-strings ([code is here, we will glimpse](https://pl.cs.jhu.edu/fpse/examples/mine_monadic.ml))
* Each grid square increment will take O(n) since the whole grid has to be rebuilt with one change
  - there is some functional sharing of parts not incremented (as in list append above) but means 1/2 n = O(n)
* O(n) inc's are performed total so it will be O(n^2).

Imagine an alternative monad implementation using a `Board` implemented as a `Core.Map` from keys `(i,j)` to characters:
* lookup and increment will be O(log n) on average since `Core.Map` is implemented as a balanced binary search tree
    - one change to a Map's tree is only log n because only one path in tree is changed, rest can be re-used
    - (yes, one path down a binary tree is only 1/(log n)-th of the tree nodes, and the sub-trees can be reused)
* So total time is O(n log n)

Conclusion
* For Minesweeper, O(n^2) is in fact fine as the grids are always "tiny" in a CPU sense
* But if this grid was instead a large image (pixel grid) this would be intolerable
* With correct functional data structure choices you can usually pay a log n "fee" which will often be fine
* But, sometimes you just need to get out the imperative `Array`, `Hashset` etc.

#### When FP wins: Many Related Worlds Algorithms
* Portions of immutable data structures can be shared without conflict
  - alluded to in the list sharing example above
* So if an algorithm has many related stores in it the FP version can be superior
* Example: a simple transactional store monad (here is pseudocode)
   - a transactional store is a memory where you might want to undo ("roll back") some writes
   - it is what is at the heart of a database implementation: if transactions conflict, roll back to past store

```ocaml
module Transactional_store = struct
    type store = (* The type of the heap data here, say it is a Map *)
    (* In the monad type, pass two stores, one in-use one saved *)
    type 'a t = store * store -> 'a * store * store 
    let bind (x : 'a t) ~(f: 'a -> 'b t) : 'b t =
      fun (s : store * store) -> let (x', s1', s2') = x s in f x' (s1', s2')
    let return (x : 'a) : 'a t = fun ss -> (x, ss)
    let set (v : data) =
      fun (s1, s2) -> ((),store_put s1 v,s2) (* update s1, pass along s2 *)
    let get () =
      fun (s1, s2) -> (store_get s1,s1,s2) (* fetch data from s1 *)
    let save () = 
      fun (s1, s2) -> ((),s1,s1) (* save the current store *)
    let rollback () = 
      fun (s1, s2) -> ((),s2,s2) (* toss s1, rollback to the saved store s2 *)
  end
end
```

* If the `store` in the above is say a Map, the `s1` and `s2` maps should be "nearly all shared" on average.
* So, copying and memory use minimized.
* The real benefit comes when there are `n` stores `s1`, ..., `sn` with sharing
* Real World OCaml has a similar example comparing an [(immutable) Map vs a (mutable) Hashtable](https://dev.realworldocaml.org/maps-and-hashtables.html#time-complexity-of-hash-tables) which we looked at earlier

#### FP and paralellism

* In pure FP with no side effects, any independent computation can be done in parallel
* Example: `List.map` could apply `f` on the list elements in parallel
  - but, reconstructing the list has to be in-order so only useful for slow-running `f`'s
  - Also `fold` and the like can't be easily parallelized since the `accum` needs to be passed along sequentially
* Multiple function arguments can be evaluated in parallel if they contain no effects
  - Referential transparency in general makes parallelism much easier to get right
* OCaml 5 has parallelism (threads with shared memory); we will take a [glimpse at a tutorial](https://github.com/ocaml-multicore/parallel-programming-in-multicore-ocaml) to see how `Task` pools and `parallel_for` work.


### Writing more efficient functions

* We already covered some of this with tail recursion
  - tail recursion principle: if the last action in a function is a recursive call, compiler can optimize away the call stack
* Let us consider that and a few other topics now.

#### Memoization

* If a function has no side effects it can easily be *memoized*
   - we saw in HW, took exponential fibbonicci to linear
   - in general works when there are no effects in the function (and, we have an `=` defined on the arguments)
   - As you know, implement by keeping a history of past input -> output pairs and look up input in table first
   - if the function is expensive and is often invoked on the same argument it will be very effective

* Note that memoization implicitly needs a store for this past history
* Could use mutable store, but could also use a state monad
  - pass in and return the store in the memoized function

### Tail recursion and CPS

* As we discussed earlier in the [idiomatic fp topic](idiomatic-fp.html#tail-recursion), left fold is tail-recursive whereas right fold is not
* And tail-recursive functions get optimized to not make call frames
  - Not only is memory saved but cache coherency is better so faster!
* Moral: if efficiency is important try to re-factor to be tail recursive
