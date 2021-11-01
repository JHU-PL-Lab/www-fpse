
## Coroutines for Asynchronous Concurrent Programming

Concurrency is needed for two main reasons
 1. You want to run things in parallel for speed gain (multi-core, cluster, etc)
 2. You are waiting for a result from an I/O action
     - Disk read/write, network request, remote API call, etc
     - (Sometimes also awaiting for internal actions such as time-outs)

In OCaml
  * Concurrency for speed gain is a work in progress: **multi-core OCaml**
    - Should be released in a year or so
    - We plan on covering parts of the beta
  * Concurrency to support asynchronous waiting: The `Lwt` and `Async` libraries


 * Local concurrency for speed is usually done via *threads*
   - fork off another computation with its own runtime stack etc but share the heap
 * But, threads are notoriously difficult to debug due to number of interleavings
   - 100's of patches have been added to help (channels, monitors, locks, ownership types, etc etc etc) but still hard
 * So, often better to use a simpler system focused on waiting for I/O if that is all you really need
 * Key difference is no preemption - routine runs un-interrupted until it *chooses* to "yield"/"pause".
 * Means that computations are still *deterministic*, much easier to debug!
 * Such an approach is known as *coroutines*

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

* The key use of coroutines is for I/O operations which may block
* *and*, they are not required to be run in a dependent sequence.
  - For example if you need to read one file and write a tranform to another file and that is it, there is no concurrency, no need for coroutines.
  - But if there are some independent actions or events they are very useful, it will allow the actions to proceed concurrently in the OS layer.

#### Motivating the Need

* Suppose you want to read a bunch of images from different places on the Internet.
* You can process them in the order they show up, no need to wait for all the images to come in
* Also (**key**), if one load is slow don't block all the subsequent loads
  - kick them all off at the start, then process as they come in.
* There could also be some sequencing requirements as well
  - e.g. once all images are in and processed or timed out, a collage is created.
  - (note that implicit in the "timed out" is a timer which can abort some loads as well)

#### Idea of the implementation

Q: How do we allow these loads to happen concurrently without fork/threads/parallelism?
A: Split such I/O actions in two:
  1. Issue image request and `pause`
  2. Package up the processing code (the *continuation*) which will run when the load completes as a function
  3. Run the function when the load is done.

It might seem awkward to package up the continuation as a function but we already did that!

Monad-think on the above:

```ocaml
let img_load url =
bind (* code to issue image request and pause *) 
     (fun img -> (* processing code to run after this image loaded*)
```
which is, in `let%bind` notation,
```ocaml
let img_load url =
let%bind img = (* code to issue image request and pause *) in
  (* processing code to run after this image loaded*)
```

(Note, `Lwt` uses `let*` instead of `let%bind`; `Async` uses `let%bind`)

* Observe how `bind` is naturally making the continuation a function
* So we will be using `bind` a lot when writing coroutine code in OCaml

### The full loading task here
 * Suppose for simplicity there are only two images.
 * We eventually need to wait for these loads to finish, here is how.

```ocaml
let p1 = img_load url1 in
let p2 = img_load url2 in
(* We immediately get to this line, the above just kicks off the requests *)
(* p1 and p2 are called "promises" for the actual values *)
(* They are in fact monadic values, we will see that below *)
(* .. we can do any other processing here .. *)
(* When we finally need the results of the above we again use bind: *)
let* loaded = Lwt.both p1 p2 in
(* ... we will get here once both loads are finished -- promises fulfulled *)
```

* The above is the high level idea of the use of coroutines
* We will now fire up `Lwt` and get into the details

## `Lwt`
<a name="lwt"></a>

To run `Lwt` you need to install it from the shell first:

```sh
opam install lwt
```

Then in `utop` do
```ocaml
#require "lwt";;
```

And you might also want to do this to put the functions at the top level and to enable `let*`.
```ocaml
# open Lwt;;
# open Syntax;;
```

We will now review [this `Lwt` tutorial](https://raphael-proust.github.io/code/lwt-part-1.html) for the details.



<a name="async"></a>

## `Async`

Here are some notes on `Async` which we don't plan on covering in lecture.

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
