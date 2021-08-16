## Lazy Data Structures

* OCaml is by default eager
  - function parameters are evaluated to values before calling functions
  - Pairs, records, and variants all have their internals computed to values recursively.
* But, sometimes laziness can be both useful and more efficient
  - for lazy funcation call, no need to compute arguments that are not used
  - It allows for construction of "infinite" lists, etc
    - Don't compute the nth element until it is asked for
    - But, once it is computed, cache it (a form of memoizing)
    - Just don't ask for all infinitely many elements!

#### Super simple encoding of laziness in OCaml

 * OCaml has no built-in Laziness (Haskell does)
 * But it can be encoded via a *thunk*

```ocaml
let frozen_add = fun () -> printf "Have a smiley day!\n"; 4 + 3
let thaw e = e ()
thaw frozen_add;; (* 4+3 not computed until here *)
```

* This encoding is in fact just "call by name", laziness means memoizing the result.


#### The `Base.Lazy` module

* `Base.Lazy` is a much more usable sugar for the above

```ocaml
# open Lazy;;
# let l = lazy(printf "Have a smiley day!\n";2+3);;
val l : int lazy_t = <lazy> (* lazy_t is the wrapper type *)
# force l;;
Have a smiley day!
- : int = 5
# let f lv =  (force lv) + (force lv);;
val f : int lazy_t -> int = <fun>
# f l;;
Have a smiley day! (* this is printed only once, the 2nd force uses cached 5 value *)
- : int = 10
```

* Fact: laziness is just a "wrapper" on a computation
* So: Lazy is in fact (yet) another monad - !
  - We won't get into `Lazy.bind` etc here but lets make an infinite stream of fib's.

```ocaml
open Core
open Lazy
type 'a stream = Cons of 'a * 'a stream Lazy.t (* List MUST be infinite *)

let rec all_ones : int stream = Cons(1,lazy(all_ones))

let rec ints n : int stream = Cons(n,lazy(ints (n+1)))

(* Code to get the nth element of a lazy list *)

let rec nth (Cons(hd, tl) : 'a stream) (n : int) :'a =
  if n = 0 then hd
  else nth (force tl) (n-1)

(* A more interesting example - shows memoization, this is not exponential *)

let rec fib : int stream = 
  let rec fib_rest (Cons(hd, tl) : int stream) : (int stream) = 
   let Cons(hd',_) = force tl in
    Cons (hd + hd', lazy(fib_rest (force tl))) in
  Cons(1, lazy(Cons(1, lazy(fib_rest fib))))
```

* One thing not clear from the code is that a `Lazy` will not be recomputed
* Once the list is "unrolled" by one call it doesn't need to be "re-unrolled"
* This is a form of caching / memoization built into `Lazy`
   - (but not in our crude encoding of it above)
* Note that becuase of that the above nth function will in fact be linear, not exponential
