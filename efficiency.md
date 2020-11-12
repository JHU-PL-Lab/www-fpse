## Efficiency in Functional Programming

* Functional data structures: 
    - at first they may feel super-inefficient
    - but they are often in practice perfectly fine even if asymptotic behavior is worse
    - and, they are better in a few cases because past states "persist for free"

### Case Study: Minesweeper

* Let us analyze the complexity of different implementations of Minesweeper.
* Assume a grid of n elements (a square-root n by square-root n grid)

Monadic version with 2D array update as a copy in implementation
* Each grid square increment will take O(n) since the whole grid has to be rebuilt with one change
* O(n) inc's are performed total so it will be O(n^2).

Alternative monad implementation as a Core.Map from keys (i,j) to characters:
* lookup and increment will be O(log n) since Core.Map is implemented as a balanced search tree
    - one change to a Map's tree is only log n because only one path in tree is changed, rest can be re-used
* So total time is O(n log n)

Regular imperative implementation using a 2D array
* O(1) for each inc operation so O(n) in total.

Conclusion
* For Minesweeper, O(n^2) is in fact fine as billion-by-billion grids are not used
* But clearly in your "big data" app such a penalty could be intolerable
* It is in general a waste of power .. more greenhouse gases

### When FP wins

* Some algorithms are in fact better in the FP world

#### Many Related Worlds Algorithms
* Portions of immutable data structures can be shared without conflict
* So if an algorithm has many related stores in it the FP version can be superior
* Example: a simple transactional store in pseudocode

```ocaml
module Transactional_store = struct
    type store = (* The type of the heap data here *)
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


#### FP and paralellism

* If we know there are no side effects, any independent computation can be done in parallel
* Common example: `List.map` and other `.map`'s can apply `f` in parallel
* Multiple function arguments can be evaluated in parallel
* etc..


### Writing more efficient FP

* We already covered some of this with the tail recursion topic
  - tail recursion principle: if the last action in a function is a recursive call, compiler can optimize away the call stack
* Let us consider that and a few other topics now.

#### Memoization

* If a function has no side effects it can easily be *memoized*
  - given a fixed input, the output is always the same
  - so, keep a history of past input -> output pairs and look up input in table first
  - if the function is expensive and is often invoked on the same argument it will be very effective
  - example of fibbonici from your assignment: exponential to linear

* Note that memoization implicitly needs a store for this past history
* Could use mutable store, but could also do the "state monad thing"
  - pass in and return the store in the memoized function
```ocaml
fib : int -> (int,int,..) Map.t -> (int * (int,int,..) Map.t)
```
  - Requires monadic state threading and store itself will be less efficient


### Tail recursion hacks

* As we discussed earlier in the [idiomatic fp topic](idiomatic-fp.html#tail-recursion), left fold is tail-recursive whereas right fold is not
* The problem is it is somewhat random whether a given algorithm is tail-recursive or not
* But, we can re-factor many algorithms to be tail recursive
* A classic technique for this is *continuation passing style* aka CPS

#### Continuation Passing Style (CPS)

* Idea: pass the "rest of the computation" as an additional argument `c` to a function
* The last line of the function will be `c(..)` -- call `c`.
* If `c` is the current function itself, it will be a tail call - efficient!
* See file [continuation-trees.ml](continuation-trees.ml) for how to code tree fold using CPS.


#### Other uses of CPS
* CPS looks related to how we encoded a store in a monad 
   - both involve passing an extra argument along hand over fist
* In fact, there is a deeper connection: the Continuation monad, with type
```ocaml
  type 'a t = ('a -> answer) -> answer
```
  - we will not explore this monad in detail
* What we will explore is how *coroutines* can be expressed with continuations.

