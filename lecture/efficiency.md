## Efficiency in Functional Programming

* Functional data structures: 
    - at first they may feel super-inefficient
    - but they are usually in practice fine even if asymptotic behavior is worse
    - and, they are better in a few cases because past states "persist for free"

### Functional lists
Let us review the most common OCaml data structure, `'a list`.

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
* if lists were mutable such sharing would not usually be possible!
* In general this shows there is a trade-off in that in some cases functional wins
   - more on this below
### Case Study: Monadic Minesweeper

* Let us analyze the complexity of different implementations of the imperative Minesweeper.
* Assume a grid of n elements (a square-root n by square-root n grid)


Our imperative implementation using a 2D array ([this one](../examples/mine_array.ml))
* O(1) for each inc operation so O(n) in total.

Hypothetic monadic state version 
* Take the imperative 2D array version, implement as state monad on list-of-strings ([code in fact is here](../examples/mine_monadic.ml))
* Each grid square increment will take O(n) since the whole grid has to be rebuilt with one change
  - can in fact share rhs of parts not incremented (as in append above) but means 1/2 n = O(n)
* O(n) inc's are performed total so it will be O(n^2).

Alternative monad implementation as a Core.Map from keys (i,j) to characters:
* lookup and increment will be O(log n) on average since Core.Map is implemented as a balanced search tree
    - one change to a Map's tree is only log n because only one path in tree is changed, rest can be re-used
    - (yes, one path down a binary tree is only 1/(log n)-th of the tree nodes, and the sub-trees can be reused)
* So total time is O(n log n)

Conclusion
* For Minesweeper, O(n^2) is in fact fine as the grids are always "tiny" in a CPU sense
* But clearly in your "big data" app such a penalty could be intolerable
* In general there are some results indicating it should be possible to "only" pay a log n penalty on any data structure if one is clever.
* But, sometimes you need to get out the imperative `Array` and `Hashset` etc in OCaml.

#### When FP wins: Many Related Worlds Algorithms
* Portions of immutable data structures can be shared without conflict
  - alluded to in the list sharing example above
* So if an algorithm has many related stores in it the FP version can be superior
* Example: a simple transactional store monad (here is pseudocode)

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
* Real World OCaml has a similar example comparing an [(immutable) Map vs a (mutable) Hashtable](https://dev.realworldocaml.org/maps-and-hashtables.html#time-complexity-of-hash-tables) 

#### FP and paralellism

* If we know there are no side effects, any independent computation can be done in parallel
* Common example: `List.map` and other `.map`'s can apply `f` in parallel
* Multiple function arguments can be evaluated in parallel if they contain no effects
* ... Referential transparency in general makes parallelism much easier
* Multicore OCaml is in beta, and will be released soon.


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
* Could use mutable store, but could also do the "state monad thing"
  - pass in and return the store in the memoized function

### Coding with tail recursion

* As we discussed earlier in the [idiomatic fp topic](idiomatic-fp.html#tail-recursion), left fold is tail-recursive whereas right fold is not
* In general it is somewhat random whether a given algorithm is tail-recursive or not
* But, we can re-factor many algorithms to be tail recursive
* A classic technique for this is *continuation passing style* aka CPS

#### Continuation Passing Style (CPS)

* Idea: pass the "rest of the computation" as an additional argument `c` to a function
* The last line of the function will be `c(..)` -- call `c`.
* If `c` is the current function itself, it will be a tail call - efficient!
  - in general, if a whole series of calls is in CPS, no stack is needed.
* See file [continuation-trees.ml](../examples/continuation-trees.ml) for how to code tree fold using CPS.

#### CPS and coroutines

* We also saw continuations in `Lwt` where the "callback code" after an I/O operation was a function invoked later:

```ocaml
let* () = Lwt_io.printl "Hello," in
let* () = Lwt_io.printl "world!" in
Lwt.return ()
```

is really 

```ocaml
bind(Lwt_io.printl "Hello,") 
    (fun () -> bind(Lwt_io.printl "world!") 
                   (fun () -> Lwt.return ()))
```

-- each of the 2nd arguments to bind is "the rest of the work", the continuation.

  - In Algebraic Effects world we had explicit `'a continuation` types: the system packed up all the "rest of the work" code for us
    - they are not *encoded* as functions there, the continuations are *built-in*