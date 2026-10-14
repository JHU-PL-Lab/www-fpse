Assignment 6: N-Grams and a real app
------------------------------------

You will write an executable for an n-gram model generator. This is a large assignment, so you have two weeks to do it. All expectations for this assignment are written here. There is nothing notable shared in the `.ml` or `.mli` files.

### The file structure

* [Use this zip file](http://pl.cs.jhu.edu/fpse/assignments/assignment6.zip) for your assignment.
* There is `src/bin/ngrams.ml` that compiles to an executable. Your code with side-effects will go here.
* There is `src/lib/`, which is where you will put your library code.
  * Your library modules must have well-documented `.mli` files. See the provided `.mli` files in this or previous assignments for what we consider to be well-documented.
* The code to test your library and the executable is in `src-test/`. We provide some tests to convey functionality expectations and to kick off the testing of the executable.
  * All of your tests will go in `src-test/tests.ml`.
  * When testing the executable, you should use the helper functions from `src-test/ngrams_tests.ml` to avoid duplicate code.
* The resources to test are in `test/`. Provided is one corpus file `test/ddse.txt`. If you're curious about its source, see [here](https://www.pl.cs.jhu.edu/projects/demand-driven-symbolic-execution/papers/icfp20-ddse-full.pdf). Add any resources you want to `test/`.

### Motivation

#### Background

The general intuition is simple: if we want to predict what comes next in a sequence of items, we can probably do so on the basis of the items that preceded it. Moreover, we can probably ignore parts of the sequence which came _far_ before the item we want to predict and focus our attention on the immediately previous couple of items.

Consider sentences of words in English text, a very common type of sequence to apply this approach to. If we are given that the word we want to predict came after:

  "take this boat for a spin out on the" ???

Then we could say that "water" is more likely than "town" to follow. If we have less context, say only 2 words:

  "on the" ???

We will naturally make a poorer approximation of the true distribution, but it may be sufficient for some purposes anyway and will be easier to estimate. How can we estimate the actual distribution of words efficiently, then?

We will need to take in some observed sequence of words or tokens, called a _corpus_.  Let's say we want to keep two words of context when predicting what comes next, based on the provided corpus. Then we can just keep track of every 3-tuple of consecutive words in the input, and count how often they appear.

For example, say we observe the triples (i.e. 3-grams)

("take", "this", "boat"), ("this", "boat", "for"), ... ("on", "the", "water").

Then, if we index these properly, we can predict what should follow ("on", "the") by just sampling randomly from among all the tuples which started with that prefix, and using the last element of the tuple as our prediction. Naturally, words which appear more frequently in the context specified should then be given more weight, and words which do not appear in our corpus after the given sequence will not be chosen at all, so our prediction should be a reasonable estimate for the empirical distribution.

If we instead count 5-tuples rather than 3-tuples, we can make better predictions because of the greater context, which will then more closely match the true sequence properties. However, we will also be able to observe fewer unique 5-tuples overall than 3-tuples, which will mean we need greater amounts of data to properly use a larger n-gram size.

Feel free to read these useful resources to better understand n-grams:
- https://blog.xrds.acm.org/2017/10/introduction-n-grams-need/
- https://web.stanford.edu/~jurafsky/slp3/slides/LM_4.pdf
- https://medium.com/mti-technology/n-gram-language-model-b7c2fc322799

In this document we follow the standard terminology and refer to an "n-gram" as a list of n items, which has n-1 items of prefix/context. For example, a 3-gram has two items of context, and the context plus the one final item of prediction gives a 3-gram.

#### Sampling

You'll sample from a distribution until the desired output length is hit, or until there is no possible following item. Let's see an example.

If the corpus is this list of integers

```
[1; 2; 3; 4; 4; 4; 2; 2; 3; 1]
```

Then all of the bigrams (2-grams) are

```
[ (1, 2); (2, 3); (3, 4); (4, 4); (4, 4)
; (4, 2); (2, 2); (2, 3); (3, 1)]
```

and we might describe the distribution using bigrams (2-grams) like this:

```
{
  [1] -> {2};
  [2] -> {3; 2; 3};
  [3] -> {4; 1};
  [4] -> {4; 4; 2};
    |        |
    |        \------------------------ ...was followed by each of these elements
    \-- this sequence (of length 1 in this example)  ...
}
```

Suppose instead there are two items of context because the model used 3-grams. Then the distribution would look like...

```
{
  [1; 2] -> {3};
  [2; 3] -> {4; 1};
  [3; 4] -> {4};
  [4; 4] -> {4; 2};
  [4; 2] -> {2};
  [2; 2] -> {3};
    |        |
    |        \------- ...was followed by each of these elements
    \-- this sequence...
}
```

We will walk you through one example of sampling from this distribution (the 3-gram, two-items-of-context distribution) with input ngram `[1; 2]` and a desired 5-length sequence.

The only possible item to sample first is `3` (because `[1; 2] -> {3}` above), and the running sequence is

```
[1; 2; 3].
```

Now the context for the next item is

```
[2; 3].
```

Look at the above distribution to see what can follow this context (here, `[2; 3] -> {4; 1}`). So we sample from

```
{4; 1}
```

at random. Say this comes out as 4. So the running sequence is now

```
[1; 2; 3; 4]
```

and the new context is

```
[3; 4].
```

So we sample from

```
{4}
```

which makes the running sequence

```
[1; 2; 3; 4; 4]
```

which has length `k = 5`, and we're done because we hit the desired length.

If from `{4; 1}` we pulled the item `1`, then the sequence would have become `[1; 2; 3; 1]`, and the new context is `[3; 1]`, which is never followed by any item in the original sequence, and hence there's no appropriate next item, so we stop at length 4, which is short of `k = 5`. That's okay, and it's a valid output.


### Functionality

You will implement an `ngrams.exe` executable that will use N-gram models in several ways. It will be called according to the following manual:

```
SYNOPSIS
       ngrams.exe COMMAND …
COMMANDS
       most-frequent K-MOST-FREQUENT CORPUS N

       sample MAX-SAMPLE-LENGTH CORPUS N [--initial-words=INITIAL-WORDS]
```

See `src-test/ngrams_tests.ml` for example uses. See `src/bin/ngrams.ml` for the argument parser. Run `ngrams.exe --help` to find the manual.

There are two commands: `most-frequent` and `sample`. Each will use a `CORPUS` and a positive `N`.
- Read the file at the path `CORPUS` and split its contents into a sequence of non-empty strings separated by whitespace. Treat newlines, spaces, etc. all equally.
- Sanitize each of the strings in this sequence by making it lowercase and removing non-alphanumeric characters. Say a "sanitized" word is lowercase and uses only alphanumeric characters.
- Parse all N-grams from the sanitized sequence of words, where each N-gram is of length `N`. You may assume the corpus file contains enough words to form at least one N-gram of the specified size `N` and that `N` is positive.

Now, if the command is `sample`:
- Initialize a distribution from the parsed N-grams. Since `N` is the length of the N-grams used to build the distribution, there are `N - 1` items of context for sampling. For example, `N = 3` means two items of context because the last item is used for sampling, and the first two are used for context of the sampled element.
- To stdout, output a sequence of `MAX-SAMPLE-LENGTH` words randomly sampled from the N-gram model as described in the "sampling" section above. Print them out separated by single spaces, followed finally by a newline.
- To begin the sequence, use the `INITIAL-WORDS` arguments provided after `--initial-words` to seed the sequence, or if none are provided, then choose a random starting context from the distribution to begin. You may assume that the words provided as `INITIAL-WORDS` are already sanitized, and that there are **at least** `N - 1` of them if they are provided. There may be more, in which case you should keep all of them for the output but begin sampling with the final `N - 1` of them as context, just as you would if you had already sampled some words.
- Sample the words according to the description in the "sampling" section above. If too many words are provided as `INITIAL-WORDS`, then output only the first `MAX-SAMPLE-LENGTH` of them, and ignore the rest.
- You may run `./ngrams.exe sample --help` to see the manual.
- An example call is `./ngrams.exe sample 3 dune-project 2 --initial-words 'lang dune'`, which will output `lang dune 324` when run from the `assignment6/` directory; it samples 3 words from the dune-project file using 2-grams and starting from "lang dune".

Otherwise, if the command is `most-frequent`:
- To stdout, output a sorted json-formatted list of length `K-MOST-FREQUENT` containing information about the most common N-grams seen in the `CORPUS`. For example:
  ```
  [
    { "ngram": [ "hello", "world", "goodbye" ], "count": 5 },
    { "ngram": [ "lexicographically", "greater", "ngram" ], "count": 5 },
    { "ngram": [ "less", "frequent", "ngram" ], "count": 4 },
    { "ngram": [ "lesser", "frequent", "ngram" ], "count": 3 }
  ]
  ```
  where the ["hello"; "world"; "goodbye"] n-gram showed up 5 times, as did ["lexicographically"; "greater"; "ngram"], and so on. In this example, `N` = 3, and `K-MOST-FREQUENT` = 4.
- If there are fewer than `K-MOST-FREQUENT` unique n-grams, then print as many as possible.
- Higher frequency (greater count) N-grams must come first, and frequency ties should be broken by N-gram alphabetical order. Print the pretty json-formatted list, followed by a newline.
- You may run `./ngrams.exe most-frequent --help` to see the manual.
- An example call that you can try yourself is `./ngrams.exe most-frequent 2 dune-project 1`, which will output this:
  ```
  [ { "ngram": [ "324" ], "count": 1 }, { "ngram": [ "dune" ], "count": 1 } ]
  ```

All of the command line argument parsing is done for you. You should feel free to change the provided code in any way and learn about how it works.

We will reveal only a few tests to help you get the right output format, but you are expected to thoroughly test your own code. Testing is an important part of software development. The same tests are revealed on Gradescope as are provided in `src-test/ngrams_tests.ml`. If you feel the desired functionality is still ambiguous, then please ask on Courselore for clarification after reading this entire file.

### Implementation requirements.

There are several requirements to receive full credit for this assignment. You are at risk of losing many points if you don't follow any of these requirements. They are in place to help you write good code and to prepare you for the project.

#### Architecture requirements
* You must have a library, so only a very, very small portion of your code is in `src/bin/ngrams.ml`.
* All library code exposed by the `.mli` files should be well-documented (just like how the `.mli` files provided with each prior assignment have been well-documented), and all library modules have an `.mli` file.
* You need a type to represent an n-gram.
* You need a type to represent a distribution of many n-grams: how the first "n minus 1" items can be followed by a next item.
* This must be done with a functor such that the n-gram distributions can be of any item type--strings, ints, anything comparable--even though the executable will only use it with strings.
* Your code is modular with separation of responsibilities and good use of abstraction.
* You should use external tools for json conversions and formatting. We recommend `yojson` and/or `ppx_deriving_yojson`. Add them to the `dune` files for your library to use them.

#### Testing requirements

We also expect that you sufficiently test your code.

* We expect good code coverage.
  * Anything testable should be in your library instead of your executable. You must use `Bisect` to show at least 94% code coverage.
    * Make sure you have instrumented your libraries properly, as suggested in the `src/lib/dune` file. The testing support for `Bisect` has been done for you in `src-test/dune` otherwise.
    * To get a coverage report of your code, you can run `dune test --instrument-with bisect_ppx_ng`, and then either `bisect-ppx-report summary` to quickly see the coverage, or `bisect-ppx-report html` to generate a detailed report, found at `_coverage/index.html`.
  * In addition, write at least one `QCheck` random test for one of your `OUnit2` tests, like the [Quickcheck lecture](https://pl.cs.jhu.edu/fpse/lecture/specification-test.html#quickcheck). Since the input data is random, you may not necessarily know the correct answer, but it suffices to perform sanity checks. For example, for any n-gram used to create the distribution, it's possible to sample _something_ from the distribution using the n-gram's context.
    * Indicate with a very clear comment containing the capitalized word "INVARIANT" somewhere inside of it to help the graders find your invariant test.
* Notice that only library functions are susceptible to coverage. You should test your executable as well to increase your chances at a good autograder score, but you will not be graded on executable testing.

### Example interfaces

We do not provide you any starter code for your library, but here, we give you just part of an example interface that might be used to solve this assignment. You do not have to use anything from this interface, and if you do, then you will probably have to add to it. **It is not complete.**

These interfaces are intentionally not commented or explained. Notice that they are small and modular, and they hide the implementation details.

```ocaml
(* ngram.mli *)
type 'token t
val parse : int -> 'token list -> 'token t list
val split_last : 'token t -> 'token list * 'token
val k_most_to_string : (module Token : Utils.TOKEN) -> k:int -> Token.t t list -> string

(* distribution.mli *)
module Make (Token : Utils.TOKEN) : sig
  type t
  val make : Token.t Ngram.t list -> t
  val sample : t -> max_length:int -> init:Token.t list option -> Token.t list
end

(* utils.mli *)
module type TOKEN = sig
  type t [@@deriving yojson, ord]
end
val get_sanitized_words_from_file : string -> string list
```

Do not get caught up trying to write a solution with exactly this interface. Write your own libraries to best implement your own solution, but take from this as you wish.

### Submission and grading

* Make sure your `dune` files are updated for each library you make. Your libraries should be dependencies of each other or the `ngrams` executable.
* Run a final `dune clean ; dune build`, and upload `_build/default/assignment6.zip` to Gradescope.
* Any requirement expressed or suggested in this file, or on the course webpage regarding coding style and best practices, is subject to grading. Make sure you've read it carefully. Design and implement your solution with all requirements in mind.
