
## Coroutines for Asynchronous Concurrent Programming

Concurrency is needed for two main reasons
 1. You want to run things in **parallel** for speed gain (multi-core, cluster, etc)
 2. You are **waiting** for a result from an I/O action
     - Disk read/write, network request, remote API call, etc
     - (Sometimes also awaiting for internal actions such as time-outs)

In OCaml
  * Concurrency for speed gain is a work in progress: **OCaml 5** (in beta now)
    - We will cover a bit of OCaml 5 tomorrow
  * Concurrency to support asynchronous waiting: The `Lwt` and `Async` libraries


 * Local concurrency for speed is usually done via *threads*
   - fork off another computation with its own runtime stack etc but share the heap
 * But, threads are notoriously difficult to debug due to number of interleavings
   - Can't test all of the exponentially many ways parallel computations can interleave
   - 100's of patches have been added to limit resource contention (channels, monitors, locks, ownership types, etc etc etc) but still hard
 * So, often better to use a simpler system focused on waiting for I/O if that is all you really need
 * Key difference is **no preemption** - routine runs un-interrupted until it *chooses* to "yield"/"pause".
 * Means that computations are still *deterministic*, much easier to debug!
 * Such an approach is called *coroutines* due to that term being used in some early PLs.

### Coroutines in different languages

Coroutines are found in most modern PLs
 * Python has the built-in [asyncio library](https://docs.python.org/3/library/asyncio-task.html)
 * JavaScript has built-in `async/await` syntax
 * All other commonly-used languages have some third-party library

In OCaml there are currently two competing libraries
 * `Async` - a Jane Street library, very compatible with `Core` but not widely used so fewer other libraries use it.
 * `Lwt` - the standard library for coroutines in OCaml.
 * We will cover `Lwt` primarily since you will likely have the most success with it on your projects.
 * They are more or less the same in principle

### Principles of Coroutines

* The key use of coroutines is in the presence of I/O operations which may block
* *and*, there are multiple I/O operations which are not required to be run in a fixed sequence.
  - For example if you need to read one file and write a tranform to another file and that is it, there is no concurrency, no need for coroutines.
  - But if there are some independent actions or events they are very useful, it will allow the actions to proceed concurrently in the OS layer.

#### Motivating the Need: Photomontage App

* Suppose you want to read a bunch of images from different URLs on the Internet and make a collage of them
* You would like to process them in the order they show up, no need to wait for all the images to come in
* Also if one load is slow don't block all the subsequent loads
  - Kick them all off at the start, then process as they come in
  - Some loads could be from dead URLs so will need to time out on those
* There are some sequencing requirements as well
  - Process each image as it comes in (e.g. make 100x100)
  - Once all images are in and processed or timed out, a collage is created.

#### Idea of the implementation

Q: How do we allow these loads to happen concurrently without fork/threads/parallelism?
A: Use coroutines to split I/O actions in two:
  1. Issue each image request
  2. Package up the processing code (the *continuation*) as a function which will run when each load completes
  3. The coroutine system will run the continuation function when the load is done.

It might seem awkward to package up the continuation as a function but we already did that!

Monad-think on the above:

```ocaml
let img_load url =
bind (* code to issue image request and pause *) 
     (fun img -> (* processing code to run after this image loaded *) )
```
which is, in `let%bind` notation,
```ocaml
let img_load url =
let%bind img = (* code to issue image request and pause *) in
  (* processing code to run after this image loaded*)
```

(Note, `Lwt` uses `let*` or `let%lwt` instead of `let%bind`; `Async` uses `let%bind`)

* Observe how `bind` is naturally making the continuation a function
* So we will be using `bind` a lot when writing coroutine code in OCaml
* In general `Lwt`/`Async` are *monads* as per our effect encoding lecture

### The full loading task here
 * Suppose for simplicity there are only two images.
 * We eventually need to wait for these loads to finish, here is how.

```ocaml
let p1 = img_load url1 in
let p2 = img_load url2 in
(* We immediately get to this line, the above just kicks off the requests *)
(* p1 and p2 are called "promises" for the actual values *)
(* They are the underlying monadic values, we will see that below *)
(* .. we can do any other processing here .. *)
(* When we finally need the results of the above we again use bind: *)
let* load1 = p1 in
let* load2 = p2 in ...
(* ... we will get here once both loads are finished -- promises fulfulled *)
```

* The monad behind the scenes has a data structure holding all the continuations
  (the two image processing actions in this case)
* It will call those continuations when the low-level URL load has completed

## `Lwt`

* The above is some high level idea of the use of coroutines
* We will now fire up `Lwt` and get into the details

<a name="lwt"></a>

To run `Lwt` from `utop` do
```ocaml
#require "lwt";;
#require "lwt.unix";; (* if you also want Lwt-ized I/O functions like file read/write etc *)
```

And you might also want to do this to put the functions at the top level and to enable `let*`.
```ocaml
# open Lwt;;
# open Syntax;;
```

### Promise basics

This example shows the Lwt version of `read_line` in action.
```ocaml
let* str = Lwt_io.read_line Lwt_io.stdin in Lwt_io.printf "You typed %S\n" str;;
```

- This example looks just like the built-in `read_line` except for the `*`; here is why `Lwt` version is better:

```ocaml
let p = Lwt_io.read_line Lwt_io.stdin in 
printf "See how read not blocking now\n"; Stdio.Out_channel.flush stdout; 
let* str = p in Lwt_io.printf "You typed %S\n" str;;
```

What is going on here??

* The first line *immediately* completes and returns a *promise*, `p`, of type `string Lwt.t`
  - "I promise I will *eventually* turn into a <s>pumpkin</s> string"
  - We can use `Lwt.state` to look at what the state the promise `p` is on the way to completion
    - `Sleep` means nothing has happened yet (no input)
    - `Return v` means it has been fulfilled with `v` as the value (the input string in above case)
    - `Fail exn` means it failed with exception condition `exn`.
    - Both `Return` and `Fail` are *resolved* (finished) promises
* The `let*` above is `let%bind` but for `Lwt` - syntactic sugar for `bind`
    - `Lwt` is a monad where `'a Lwt.t` is a promise for a `'a` value.
    - As in any monad, `let* x = <a promise> in .. x normal here .. ` will take a promise back to normal-land
    - To do this, the `in` of the `let*` will need to block until that resolution.

Here is a top-loop example showing some of these promise states; code is a bit convoluted to be able to see results.

```ocaml
 let s,p = let p0 = Lwt_io.read_line Lwt_io.stdin in (state p0, p0);; (* state is Sleep - input not read yet*)
 (* type something at utop and hit return now - not shown for some reason - this is the input *)
 state p;; (* returns `Return <the string you typed>` *)
 (* Here is a failure state.  It is an exception internal to `Lwt`, it doesn't get `raise`d in OCaml except at top *)
 let p' = fail Exit in state p';;
```

## Making our own promises 
We can make (and directly resolve) our own promises; this also shows what `Lwt_io.read_line` et al are doing under the hood

```ocaml
let p = return "done";; (* This is the return of Lwt monad - inject a regular value as a "fulfilled" promise *)
state p;; (* indeed it is already resolved to a `Return`. *)
let p, r = wait ();; (* `wait` starts a promise aSleep; r is a resolver used to resolve it later *)
state p;; (* Sleep *)
wakeup_exn r Exit;; (* `wakeup_exn` makes p a failure  *)
state p;; (* Now a `Fail Exit`.  Note once resolved it is all done, can't Sleep/Return *)

let p, r = wait ();; (* another one, lets resolve this one positively *)
wakeup r "hello";;
state p;; (* now a Return "hello" *)
```

### More operations on Promises

* One common operation is when you have launched a bunch of I/O requests to be able to respond when only one of them has come back
* The `Lwt` combinator for that is `choose` which picks a resolved promise from a list of promises

```ocaml
let p1, r1 = wait ();;
let p2, r2 = wait ();;
let pc = choose [p1; p2];;
state pc;;
wakeup r2 "Good morning";;
state pc;; (* pc chooses r2 here since it is the only resolved one *)
let* s = pc in return s;; (* resolved so immediately returns *)
let* s = p1 in return s;; (* this hangs in the top-loop: p1 is still a`Sleep` *)
```

* If you use `join` instead of `choose` above it will block until all are resolved.
  - They don't return any value with `join`, unlike with `choose`
* You can also create promises which can be cancelled; use `task` instead of `wait` to make those
  - Anything waiting on that promise (e.g. any `let*` on it etc) are recursively cancelled
  - See the manual for how you can cancel promises created with `task`.

### Running a main program

* Playing with `Lwt` in the top loop is a bit cheating, in a standalone executable you are staying in the `Lwt` monad
* For example, `return "hello";;` is of type `string Lwt.t` but in fact in the top-loop it will return a string only.
* That is because things in the top-loop are implicitly wrapped in `Lwt_main.run` so `return "hello";;` is in fact doing 

```ocaml
Lwt_main.run (return "hello")
```
* This runs the `'a Lwt.t` computation supplied until all promises are resolved, and returns the final value if any.
* Any main executable using `Lwt` usually calls this at the top, and when all promises are resolved the app can terminate.
* Note its type: `'a t -> 'a` which is what `run` should be in monad-land: get us out of the monad somehow
  - A common error is to try to call `Lwt_main.run` on your own to get out of monad-land but that won't work, it will destroy all the previous promises.
  - Moral: once in monad-land, always in monad-land when using `Lwt` in an executable.  Or at least til all I/O done.

We will now skim 

* [The manual](https://ocsigen.org/lwt/latest/manual/manual) (we covered the key ideas above already)
* [This `Lwt` tutorial](https://raphael-proust.github.io/code/lwt-part-1.html) which gets into the internals of how promises are stored etc (may not have time for this)


<a name="async"></a>

## `Async`

Here are some notes on `Async` which we don't plan on covering in lecture.  If you use a library over `Async` it may be helpful for you to read this.

 * `Async` is the Jane Street (`Core` people) version of `Lwt`.
 * It is also based on the notion of a *promise*
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
