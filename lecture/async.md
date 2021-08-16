
## Asynchronous Programming

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

## Note in 2021 we will not be covering the `Async` library, the notes below are outdated.

## We will instead cover `Lwt` and the `async`/`await` of Multicore OCaml.

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
