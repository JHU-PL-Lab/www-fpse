
## Coroutines for Asynchronous Concurrent Programming

Concurrency is needed for two main reasons
 1. You want to run things in **parallel** for speed gain (multi-core, cluster, etc)
 2. You are **waiting** for a result from an I/O action
     - Disk read/write, network request, remote API call, etc
     - (Sometimes also awaiting for internal actions such as time-outs)

In OCaml
  * Concurrency for speed gain is a recent addition to OCaml 5
    - We will cover a bit of OCaml 5 parallelism later
  * Concurrency to support asynchronous waiting: The `Lwt` and `Async` libraries


 * Local concurrency for speed is usually done via *threads*
   - fork off another computation with its own runtime stack etc but share the heap
 * But, threads are notoriously difficult to debug due to the number of interleavings
   - Can't test all of the exponentially many ways parallel computations can interleave
   - 100's of patches have been added to limit resource contention (channels, monitors, locks, ownership types, etc etc etc) but still hard
 * So, its often better to use a simpler system focused on waiting for I/O if that is all you really need
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
     (fun img -> (* the continuation: processing code to run after this image loaded *) )
```
which is, in `let%bind` notation,
```ocaml
let img_load url =
let%bind img = (* code to issue image request and pause *) in
  (* processing code to run after this image loaded*)
```

(Note, `Lwt` uses `let%lwt` or `let*` instead of `let%bind`)

* Observe how `bind` is naturally making the continuation a function
* So we will be using `bind` a lot when writing coroutine code in OCaml
* In general `Lwt` is a *monad*
* We won't be looking at the underlying structure of the `Lwt` monad, but the type `Lwt.t` is keeping a list of active coroutines and swapping between them.

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
let%lwt load1 = p1 in
let%lwt load2 = p2 in ...
(* ... we will get here once both loads are finished -- promises fulfulled 
   Note we can also Lwt.choose to get the first one completed 
   - process them as they come in.. more below on this *)
```

* The monad behind the scenes has a data structure holding all the continuations
  (the two image processing actions in this case)
* It will call those continuations when the low-level URL load has completed
  - in Lwt terminology, *when the promise is fulfilled*.

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
  - Moral: once in monad-land, always in monad-land when using `Lwt` in an executable.  Or at least til all I/O done.

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
  - Anything waiting on that promise (e.g. any `let%lwt` on it etc) are recursively cancelled
  - See the manual for how you can cancel promises created with `task`.

### Launching a new Coroutine

* `Lwt.async` can launch a new coroutine
* The engine will then round-robin between all the active coroutines
* The coroutine will at some point need to do an Lwt operation so it can yield to others
* In this case the sleep is an Lwt operation that will yield, so other actions can happen then.
* Note this one is not good to run in the top loop as the nag runs forever
  - it is commented out in the file `manual_examples.ml` if you want to try the executable.

```ocaml
let () =
   let rec show_nag () : _ Lwt.t =
     let%lwt () = Lwt_io.printl "Please enter a line" in
     let%lwt () = Lwt_unix.sleep 1. in
     show_nag ()
   in
   Lwt.async (fun () -> show_nag ());

   Lwt_main.run begin
     let%lwt line = Lwt_io.(read_line stdin) in
     Lwt_io.printl line
   end
```

* Here is an example that shows how `Lwt.pause` is used in a compute-intensive task to let other coroutines run.
* Note this one is also not good to run in the top loop as `handle_io` runs forever
  - it is in the file `manual_examples.ml` if you want to try it.

```ocaml
let () =
  let rec handle_io () =
    let%lwt () = Lwt_io.printl "Handling I/O" in
    let%lwt () = Lwt_unix.sleep 0.1 in
    handle_io ()
  in

  let rec compute n =
    if n = 0 then Lwt.return ()
    else
      let%lwt () =
        if n mod 1_000_000 = 0 then Lwt.pause () else Lwt.return ()
      in
      compute (n - 1)
  in

  Lwt.async handle_io;
  Lwt_main.run (compute 100_000_000)
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
