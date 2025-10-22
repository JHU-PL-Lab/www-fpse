
## Coroutines for Asynchronous Concurrent Programming

Concurrency is needed for two main reasons
 1. You want to run things in **parallel** for speed gain (multi-core, cluster, etc)
 2. You are **waiting** for a result from an I/O action and want to do other work while waiting
     - Disk read/write, network request, remote API call, internal timer, etc
In OCaml
  * Concurrency for speed gain is new, its in OCaml 5
  * Concurrency to support asynchronous waiting via **coroutines**: The `Lwt` and `Async` libraries

#### Threads
 * Concurrency for speed is usually done via *threads*
   - fork off another computation with its own runtime stack etc but share the heap
 * But, threads are notoriously difficult to debug due to the number of interleavings of control flows
   - Can't test all of the exponentially many ways parallel computations can interleave
   - Many tools today are used to limit resource contention (channels, monitors, locks, ownership types, etc etc etc) but it's still hard

#### Coroutines
 * So if all you need is to wait for some I/O, its often better to use coroutines
 * Key difference of a coroutine is **no preemption** - routine runs un-interrupted until it *chooses* to "yield"/"pause".
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
 * We will cover `Lwt` since most useful libraries are built over `Lwt`: `Cohttp`, `Dream`, and `Opium` for example.

### Principles of Coroutines

* Coroutines are only useful if there is some action started that will complete in the future, and you want to get some work done meanwhile.
* Scenario: You just need to read in a file and write a tranformed version to another file and that is it
  - There isn't really anything else you need to do while waiting for I/O, no need for coroutines.
* Scenario: You want you algorithm to do ten seconds of searching for a best answer, and return the best answer when the timer goes off
  - The timer is an action that will complete in the future and you indeed want to get some work done meanwhile: use a coroutine!

### A Larger Example of Coroutines: Photomontage App

* Suppose you want to read a bunch of images from different URLs on the Internet and make a collage of them
* You would like to resize them in the order they show up, no need to wait for all the images to come in
* Also if one load is slow don't block all the subsequent loads
  - Kick them all off at the start, then process as they come in
  - Some loads could be from dead URLs so will need to time out on those
* There are some sequencing requirements as well
  - Resize each image as it comes in (e.g. make 100x100)
  - Once all images are in and resized or timed out, a collage is created.

#### Idea of the implementation

Q: How do we allow these loads to happen concurrently without fork/threads/parallelism?

A: Use coroutines to split I/O actions in two:
  1. Issue each image GET request
  2. Package up the resizing code (the *continuation*, the "rest of the work") as a function which will run when each load completes
  3. The coroutine system will run the continuation function for each load when that load is done.

It might seem odd to package up the continuation as a function, but we already did that, with Monads!

Monad-think on the above:

```ocaml
let img_load url =
bind (* code to issue image request and pause *) 
     (fun img -> (* the continuation: processing code to run after this image loaded *) )
```
which is, in `Core`'s `let%bind` notation,
```ocaml
let img_load url =
let%bind img = (* code to issue image request and pause *) in
  (* processing code to run after this image loaded*)
```

(Note, `Lwt` uses `let%lwt` or `let*` instead of `let%bind`; you can view them all as synonyms)

* Observe how `bind` is naturally making the continuation a function
* So we will be using `bind` a lot when writing coroutine code in OCaml
* In general `Lwt` is a *monad*
* We won't be looking at the underlying structure of the `Lwt` monad, but the type `Lwt.t` is keeping a list of active coroutines and swapping between them.

#### More details on phtomontage
 * Suppose for simplicity there are only two images.
 * We eventually need to wait for these loads to finish, here is how.

```ocaml
let p1 = img_load url1 in
let p2 = img_load url2 in
(* We immediately get to this line; the above just kicks off the requests *)
(* p1 and p2 are called "promises" for the actual values: "I promise I'll eventually be the value" *)
(* They are the underlying monadic ("wrapped") values, we will see that below *)
(* .. we can do any other processing here .. *)
(* When we finally need the results of the above we use bind *)
(* The bind will block if value not there yet: *)
let%lwt load1 = p1 in
let%lwt load2 = p2 in ...
(* ... we will get to this line once both loads are finished -- promises fulfulled 
   If we had other coroutines they can wake up and run while waiting for these loads
   Note we could have instead used Lwt.choose to get the *first* one completed:
     let%lwt a_load = Lwt.choose [ p1; p2 ]
   For this application Lwt.choose is important to get the advantage of coroutines: block minimally
*)
```

* When `let%lwt load1 = ...` is hit, recall this is a `bind` and all the rest of the code is in fact a function:
  `fun load1 -> let%lwt load2 = p2 in ...`
* The monad behind the scenes has a data structure holding this function (aka continuation)
* Other coroutines if any can run while waiting, this code is just sitting
* It will call the continuation when the low-level URL load has completed
  - in Lwt terminology, *when the promise is fulfilled*.
  - this will then allow the second load to happen.

## Running Lwt
* The above is some high level idea of the use of coroutines
* We will now fire up `Lwt`, first in the top-loop
* See [The manual](https://ocsigen.org/lwt/latest/manual/manual) for all the details

<a name="lwt"></a>

To run `Lwt` from `utop` do
```ocaml
#require "lwt";;
#require "lwt.unix";; (* if you also want Lwt-ized I/O functions like file read/write etc *)
#require "lwt_ppx";; (* for the let%lwt syntax; need to `opam install lwt_ppx` first *)
```

And you might also want to do this to put the functions at the top level.
```ocaml
open Lwt;;
```

### Promise basics

This example shows the Lwt version of `read_line` in action.
```ocaml
let%lwt str = Lwt_io.read_line Lwt_io.stdin in Lwt_io.printf "You typed %S\n" str;;
```

- This example looks just like the built-in `read_line` except for the `%lwt`; here is why `Lwt` version is better:

```ocaml
let p = Lwt_io.read_line Lwt_io.stdin in
printf "See how read not blocking now\n"; Stdio.Out_channel.flush stdout;
let%lwt str = p in Lwt_io.printf "You typed %S\n" str;;
```

Lets expand the `let%lwt` to `bind` to make this more clear:
```ocaml
let p = Lwt_io.read_line Lwt_io.stdin in
printf "See how read not blocking now\n"; Stdio.Out_channel.flush stdout;
Lwt.bind p (fun str -> Lwt_io.printf "You typed %S\n" str);;
```
What is going on here?

* The first line *immediately* completes and returns a *promise*, `p`, of type `string Lwt.t`
  - "I promise I will *eventually* turn into a <s>pumpkin</s> string"
  - We can use `Lwt.state` to look at what the state the promise `p` is on the way to completion
    - `Sleep` means nothing has happened yet (no input)
    - `Return v` means it has been fulfilled with `v` as the value (the input string in above case)
    - `Fail exn` means it failed with exception condition `exn`.
    - Both `Return` and `Fail` are *resolved* (finished) promises
* The `let%lwt` above is `let%bind` but for `Lwt` - syntactic sugar for `bind`
    - `Lwt` is a monad where `'a Lwt.t` is a promise for a `'a` value.
    - As in any monad, `let%lwt x = <a promise> in .. x normal here .. ` will take a promise back to normal-land
    - To do this, the `in` of the `let%lwt` will need to block until that resolution.

Here is a top-loop example showing some of these promise states; code is a bit convoluted to be able to see results.

```ocaml
 let s,p = let p0 = Lwt_io.read_line Lwt_io.stdin in (Lwt.state p0, p0);; (* state is Sleep - input not read yet*)
 (* type something at utop and hit return now - not shown for some reason - this is the input *)
 Lwt.state p;; (* returns `Return <the string you typed>` *)
 (* Here we artificially make  a failure state.  It is an exception internal to `Lwt`, 
    it doesn't get `raise`d in OCaml except at top *)
 let p' = Lwt.fail Exit in Lwt.state p';;
```

## Making our own promises 
We can make (and directly resolve) our own promises; this also shows what `Lwt_io.read_line` *et al* are doing under the hood

```ocaml
let p = return "done";; (* This is the return of Lwt monad - inject a regular value as a "fulfilled" promise *)
state p;; (* indeed it is already resolved to a `Return`. *)
let p, r = wait ();; (* `wait` returns a pair of a sleeped promise and a resolver for it *)
state p;; (* Sleep *)
wakeup_exn r Exit;; (* `wakeup_exn` uses r to resolve p to failure  *)
state p;; (* p is now a `Fail Exit`.  Note once resolved it can't change any more. *)

let p, r = wait ();; (* another one, lets resolve this one positively *)
wakeup r "hello";;
state p;; (* now a Return "hello" *)
```

## Lwt in an executable

* So far we have only shown promises, not general coroutines
* For coroutines we need to call `Lwt_main.run` which works best in a standalone executable
* See [lwteg.zip](../examples/random-examples/lwteg.zip) for a zipfile of the examples below (most from Lwt manual)
* Note you can also invoke `Lwt_main.run` in the top loop but it could run forever

### A simple Example
* Here is an example of promise resolution in an executable
* Note this one we can test in the top loop since it finishes (all promises are resolved)

```ocaml
  Lwt_main.run
    (let three_seconds : unit Lwt.t = Lwt_unix.sleep 3. in
     let five_seconds : unit Lwt.t = Lwt_unix.sleep 5. in
     let%lwt () = three_seconds in
     let%lwt () = Lwt_io.printl "3 seconds passed" in
     let%lwt () = five_seconds in
     Lwt_io.printl "Only 2 more seconds passed")
```

What is `Lwt_main.run` doing exactly?
```ocaml
Lwt_main.run (return "hello")
```
* This runs the `'a Lwt.t` computation supplied until all promises are resolved, and returns the final value if any.
* Any main executable using `Lwt` usually calls this at the top, and when all promises are resolved the app can usually terminate.
  - Apps such as servers will never terminate, they listen for requests until killed.
* Note its type: `'a t -> 'a` which is what `run` should be in monad-land: get us out of the monad somehow
  - A common error is to try to call `Lwt_main.run` on your own to get out of monad-land but that won't work, it will destroy all the previous promises.
  - Moral: once in monad-land, always in monad-land when using `Lwt_main.run` in an executable.

### More operations on Promises

* One common operation is when you have launched a bunch of I/O requests to be able to respond when only one of them has come back
* The `Lwt` combinator for that is `choose` which picks a resolved promise from a list of promises
* This example also terminates so we can test it in the top loop.

```ocaml
let () =
   let p_1 =
     let%lwt () = Lwt_unix.sleep 3. in
     Lwt_io.printl "Three seconds elapsed"
   in

   let p_2 =
     let%lwt () = Lwt_unix.sleep 5. in
     Lwt_io.printl "Five seconds elapsed"
   in

   let p_3 = Lwt.choose [ p_1; p_2 ] in (* Lwt.join will resolve when both finish *)
   Lwt_main.run p_3
```

* If you use `join` instead of `choose` above it will block until all are resolved.
  - They don't return any value with `join`, unlike with `choose`
* You can also create promises which can be cancelled; use `task` instead of `wait` to make those
  - Any continuations waiting on that promise (e.g. any `let%lwt` on it) are recursively cancelled
  - See the manual for how you can cancel promises created with `task`.

### Launching a new Coroutine

* The examples above had only one *user* routine running at a time, but multiple routines possible
* `Lwt.async` launches a new coroutine
* The engine will then round-robin between all the active coroutines
* The coroutine will at some point need to do an Lwt operation so it can yield to others
* Here is an example which asynchronously keeps nagging user for input:
```ocaml
let () =
   let rec show_nag (n : int) : _ Lwt.t =
     if n = 0 then Lwt.return ()
     else
     let%lwt () = Lwt_io.printl "Please enter a line" in
     let%lwt () = Lwt_unix.sleep 1. in
     show_nag (n-1)
   in
   Lwt.async (fun () -> show_nag (5));

   Lwt_main.run begin
     let%lwt line = Lwt_io.(read_line stdin) in
     Lwt_io.printl line
   end
```
* In this case the `Lwt.sleep` will yield, so the read line can happen if data appeared.
* Note the `n` counter is used so this won't nag forever.

#### Pausing

* Here is an example that shows how `Lwt.pause` is used in a compute-intensive task to let other coroutines run.


```ocaml
let () =
  let rec handle_io (n) () =
    if n = 0 then Lwt.return ()
    else
    let%lwt () = Lwt_io.printl ".. Imagine we are handling I/O here .." in
    let%lwt () = Lwt_unix.sleep 0.1 in
    handle_io (n-1) ()
  in

  let rec compute n =
    if n = 0 then Lwt.return ()
    else
      let%lwt () = (* pause in the below will cause this bind to block and put continuation on queue *)
        if n mod 1_000_000 = 0 then Lwt.pause () else Lwt.return ()
      in
      compute (n - 1)
  in

  Lwt.async @@ handle_io 50;
  Lwt_main.run (compute 10_000_000)
```

### Using Libraries that are built on Lwt

* Web libraries Cohttp, Dream, and Opium all use `Lwt`.
* For example for Dream when you say `Dream.run` at the top of your main program it in turn will call `Lwt_main.run`
* `Lwt` then is running the whole time the server is up, and all of your own server code is running inside the Lwt monad.
* The `simple_counter.ml` example in the zip gives a very high-level idea how a server like Dream works, but this example just works from stdio.
  - In this example the `handle_connection` function is repeatedly listening for input and invoking `handle_message` to handle messages.  This is a super simplified idea of what the Dream library is doing
  - Your code in Dream is something like `handle_message`, it is just OCaml code which is not directly aware of `Lwt` etc.
* The `counter_server.ml` example in the above zip is actually listening on a network port so is one step closer to a web server.
  - Again the "user" of the server just writes `handle_message` here and the server invokes that on each input to get the output.

If you want to learn more about Lwt internals, see  [This `Lwt` tutorial](https://raphael-proust.github.io/code/lwt-part-1.html)
