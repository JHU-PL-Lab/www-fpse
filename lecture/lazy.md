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

## Asynchronous Programming

## Note in 2021 we will not be covering the `Async` library, the below is old.

Concurrency is needed for two main reasons
 1. You want to run things in parallel for speed gain (multi-core, cluster, etc)
 2. You are waiting for a result from an I/O action
     - Disk read/write, network request, remote API call, etc
     - (Sometimes also awaiting for internal actions such as time-outs)

In OCaml
  * Concurrency for speed gain is a work in progress, look for a release in a year or two
  * Concurrency to support asynchronous waiting: `Async` library (which is based on the `Lwt` library)

Local concurrency for speed
 * This is usually done via *threads*
 * fork off another computation with its own runtime stack etc but share the heap
 * But, threads are notoriously difficult to debug
   - 100's of patches have been added to help (channels, monitors, locks, ownership types, etc etc etc) but still hard
 * So, better to use a simpler system focused on waiting for I/O if that is all you really need

<a name="async"></a>
### `Async`

 * `Async` is another Jane Street library
 * It is based on the notion of a *promise*
 * Promises have been around for a very long time but are gaining in popularity
 * Many languages have libraries implementing some form
 * In `Async` they are called deferreds, of type `Deferred.t`

#### Deferreds

 * A `Deferred.t` is an action returning a result
 * Until the action is forced, it won't run (like laziness)
 * When it is forced a result will be returned which is an `option`
   - `None` will mean failure; I/O always needs failure case
 * Here is an example using `Async.Reader.file_contents`
   - reads a whole file into a string
   - but, calls to it *immediately* return
   - The file is not in fact read until the deferred is run
   - This is a special file operation function part of `Async` to support deferreds.

```ocaml
# #require "async";;
# #require "ppx_jane";;
# open Async;;
# let eventual_string = Reader.file_contents "update.py";;
val eventual_string : string Deferred.t = <abstr>
# Deferred.peek eventual_string;;
- : string option = None (* nothing has been done to force the Deferred to run *)
# eventual_string;; (* .. utop forces it to run implicitly - like Lazy.force but implicit *)
- : string =
"#!/usr/bin/python\...\n\n"
# Deferred.peek eventual_string;;
- : string option =
Some
 "#!/usr/bin/python\...\n\n"
```
  * An odd thing about the above is let-defining a `Deferred` will not run it
    - but, if it is directly fed into the top loop it will implicitly run
    - this is becuase `utop` when it sees a direct deferred will run it and return the result


(Note the `Async` examples we base on [Real World OCaml Chapter 15](https://dev.realworldocaml.org/concurrent-programming.html) which has a lot more than what we are covering)

#### The Async monad

* `Lazy` and `Option` we saw it was often not hard to avoid the `bind`/`return` view
* This is also possible with `Async` but often I/O actions are sequenced and `bind`/`return` is thus very helpful.

```ocaml
# let uppercase_file (filename : string) : (unit Deferred.t) =
    let%bind s = Reader.file_contents filename in
        Writer.save filename ~contents:(String.uppercase s)
# uppercase_file "t.txt" (* this will implicitly run the Deferred above *)
- : unit = ()
# Reader.file_contents "t.txt"
- : string = "HELLO FOLKS!"
```

`Deferred.return` does the normal wrapping thing, it defers a normal value
```ocaml
let d = return(10);;
val d : int Deferred.t = <abstr>
# d;;
- : int = 10
```

### Ivars

* Deferred's are in fact implemented with `Ivars`
* Think of it as "the implementation of a promise"
* Often you can use library functions that are `Deferred` aware
* But using `Ivar` you can write your own
* Here is an example based on RWOC:

```ocaml
# let ivar = Ivar.create () (* Create an Ivar; think of it like a ref cell *)
val ivar : '_weak1 Ivar.t =
  {Async_kernel__.Types.Ivar.cell = Async_kernel__Types.Cell.Empty}
# let def = Ivar.read ivar  (* Read the contents of the promise -- an empty one now! *)
val def : '_weak2 Deferred.t = <abstr>
# Deferred.peek def
- : '_weak3 option = None (* It is nothing.  Typing `def;;` now will loop forever! *)
# Ivar.fill ivar "Hello" (* Fill a promise explicitly *)
- : unit = ()
# Deferred.peek def
- : string option = Some "Hello" (* Indeed it got filled *)
def;;
- : string = "Hello"
```

### Making the monadic `bind` and return`

* Let us show how `bind` can be defined with `Ivar`s
* This will give us the complete picture of the monad
* Uses `upon : 'a Deferred.t -> ('a -> unit) -> unit`
   - takes an `Ivar` (a promise), and when it is fulfilled runs the `('a -> unit)` code

```ocaml
let bind' (d: 'a Deferred.t) ~(f:('a -> 'b Deferred.t)) : 'b Deferred.t =
    let i = Ivar.create () in
    upon d (fun x -> (* Run this first function when d is determined *)
             upon (f x) (* then run f x *)
                  (fun y -> Ivar.fill i y)
           ); (* call the promise "filled" when f x is determined *)
    Ivar.read i (* this returns a Deferred so users can pull on it *)
```

We covered the basic concepts of `Async` above. See [Real World OCaml Chapter 15](https://dev.realworldocaml.org/concurrent-programming.html) for larger examples including asynchronous http.
