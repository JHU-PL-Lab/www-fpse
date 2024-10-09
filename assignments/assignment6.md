Assignment 6: N-Grams and a real app
------------------------------------

You will write an exectuable for an n-gram model generator. This is a large assignment, so you have two weeks to do it. All expectations for this assignment are written here. There is nothing notable shared in the `.ml` or `.mli` files.

### The file structure

* [Use this zip file](http://pl.cs.jhu.edu/fpse/assignments/assignment6.zip) for your assignment. 
* There is `src/bin/ngrams.ml` that compiles to an executable. You will write a library (called `src/lib/utils.ml`, and/or anything else you like, as long as it's in the `src/lib/` directory) to support its functionality.
  * Your library must have a  well-documented `.mli`. See the provided `.mli` files in previous homeworks for what we consider to be well-documented.
  * You need to add these files to the `dune` rule in the top-level directory to submit them in your zip file.
* The code to test your library and the executable is in `src-test/`. We provide some tests to convey functionality expectations and to kick off the testing of the executable.
  * When you test, your should probably run `dune build` **before** you run `dune test` to make sure the executable is up to date.
  * All of your tests will go in `src-test/tests.ml`. Feel free to use functions from `src-test/ngrams_tests.ml` when testing.
* The resources to test are in `test/`. Provided is one corpus file `test/ddse.txt`. If you're curious about its source, see [here](https://www.pl.cs.jhu.edu/projects/demand-driven-symbolic-execution/papers/icfp20-ddse-full.pdf). Add any resources you like to `test/`.

### Motivation

#### Broad overview

In this assignment you will implement a simple n-gram model.

You will have some library routines and a command-line tool to build and use an n-gram model which makes use of your library.

Using the n-gram model of sequences and probabilities, we'll take in some sequence of items, and then use it as a basis to generate more similar sequences (for example, sentences of words, lists of numbers, etc.), or evaluate the likelihood of seeing particular sequences.

There is a lot to read in this file, and you should read it all. The information is better found here than in student questions on Courselore.

#### Background

The general intuition is simple: if we want to predict what comes next in a sequence of items, we can probably do so on the basis of the elements which preceded it. Moreover, we can probably ignore parts of the sequence which came _far_ before the element we want to predict and focus our attention on the immediately previous couple of items.

Consider sentences of words in English text, a very common type of sequence to apply this approach to. If we are given that the word we want to predict came after:

  "take this boat for a spin out on the" ???

Then we could say that "water" is more likely than "town" to follow. If we have less context, say only 2 words:

  "on the" ???

We will naturally make a poorer approximation of the true distribution, but it may be sufficient for some purposes anyway and will be easier to estimate. How can we estimate the actual distribution of words efficiently, then?

We will need to take in some observed sequence of words or tokens, called a _corpus_.  Let's say we want to keep two words of context when predicting what comes next, based on the provided corpus. Then we can just keep track of every 3-tuple of consecutive words in the input, and count how often they appear.

For example, say we observe the triples (i.e. 3-grams)

("take", "this", "boat"), ("this", "boat", "for"), ... ("on", "the", "water").

Then, if we index these properly, we can predict what should follow ("on", "the") by just sampling randomly from among all the tuples which started with that prefix, and using the last element of the tuple as our prediction. Naturally, words which appear more frequently in the context specified should then be given more weight, and words which do not appear in our corpus after the given sequence will not be chosen at all, so our prediction should be a reasonable estimate for the empirical distribution.

If we instead count 5-tuples rather than 3-tuples, we can make better predictions with the greater context, which will then more closely match the true sequence properties. However, we will also be able to observe fewer unique 5-tuples overall than 3-tuples, which will mean we need greater amounts of data to properly use a larger n-gram size.

Feel free to read these useful resources to better understand n-grams:
- https://blog.xrds.acm.org/2017/10/introduction-n-grams-need/
- https://web.stanford.edu/~jurafsky/slp3/slides/LM_4.pdf
- https://medium.com/mti-technology/n-gram-language-model-b7c2fc322799

In this document we follow the standard terminology (which can be confusing) and refer to "n-grams" when it seems like we might mean "(n-1)-grams" since there are n-1 items of prefix in an n-gram.  For example, a 3-gram has two items of prefix, and the prefix plus the one-item of prediction gives a 3-gram.

#### Sampling

You'll sample from a distribution until the desired output length is hit, or until there is no possible following item. Let's see an example.

If the corpus is this list of integers
```
[1; 2; 3; 4; 4; 4; 2; 2; 3; 1]
```

Then we might describe the distribution using bigrams (2-grams) like this:
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

We will walk you through one example of sampling from this distribution (the 3-gram, two item of context distribution) with input ngram `[1; 2]` and a desired 5-length sequence.

The only possible item to sample first is `3` (because `[1; 2] -> {3}` above), and the running sequence is
```
[1; 2; 3].
```
Now the context is
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

If from `{4; 1}` we pulled the item `1`, then the sequence would have become `[1; 2; 3; 1]`, and the new context is `[3; 1]`, which never appears in the original sequence, and hence there's no appropriate next item, so we stop at length 4, which is short of `k = 5`. That's okay, and it's a valid output.


### Functionality

You will implement an executable `ngrams.exe` which can use n-gram models in several ways. It should expect to be called with the following arguments, with bracketed ones optional:

  $ ngrams.exe N CORPUS-FILE [--sample SAMPLE-LENGTH [INITIAL-WORDS...]] [--most-frequent N-MOST-FREQUENT]

See `src-test/ngrams_tests.ml` for example uses. See `src/bin/ngrams.ml` for a simple argument parser.

Functionality should be as follows:

- Load the file specified by `CORPUS-FILE` and split its contents into a sequence of strings based on whitespace. Treat newlines and spaces, etc. equally.

- Sanitize each of the strings in this sequence by sending to lowercase and removing non-alphanumeric characters. Say a "sanitized" word is lowercase and uses only alphanumeric characters.

- Initialize an n-gram distribution using `N` and the sanitized sequence of words. The `N` is the length of the n-grams used when building the distribution, so N = 3 means two items of context because the last item is used for sampling, and the first two are used for context of the sampled element.

If the option `--sample SAMPLE-LENGTH` is provided:

  To stdout, output a sequence of `SAMPLE-LENGTH` words randomly sampled from the n-gram model as described in the "sampling" section above. Print them out separated by single spaces. 
  
  To begin the sequence, use the `INITIAL-WORDS` arguments provided after `--sample` to seed the sequence, or if none are provided, choose a random starting n-gram to begin. You may assume that the words provided as `INITIAL-WORDS` are already sanitized, and that there are zero or at least `N - 1` of them.

  Sample the words according to the description in the "sampling" section above. If too many words are provided, then output the first `SAMPLE-LENGTH` of them, and ignore anything else.

If the option `--most-frequent N-MOST-FREQUENT` is provided:

  To stdout, output a sorted sexp-formatted list of length `N-MOST-FREQUENT` containing information about the most common n-grams seen in the `CORPUS-FILE`, like so:

    (((ngram(hello world goodbye))(frequency 5))...)

  Where the ["hello"; "world"; "goodbye"] n-gram showed up 5 times, and "..." is for the remaining, less-frequent n-grams. In this example, `N` = 3.

  Higher frequency n-grams should come first, and frequency ties should be broken by n-gram alphabetical order. Print the sexp-formatted list, followed by a newline.

You may assume that only one of `--sample` or `--most-frequent` will be supplied at a time, and that at exactly one will be given. Handle ill-formed arguments gracefully by printing to stderr and terminating.

Some basic command line argument parsing is done for you. You should feel free to change the provided code in any way.

We will reveal only one test for each option to help you get the right output format, but you are expected to thoroughly test your own code. Testing is an important part of software development. The same test is revealed on Gradescope as is provided in `src-test/ngrams_tests.ml`. If you feel the desired functionality is still ambiguous, then please ask nicely on Courselore for clarification.

### Implementation requirements.

* There are several requirements to recieve full credit for this assignment. You are at risk of losing many points if you don't follow any of these requirements. They are in place to help you write good code and to prepare you for the project.
  * You must have a library, so only a very, very small portion of your code is in `src/bin/ngrams.ml`.
  * You need a type to represent an n-gram.
  * You need a type to represent a distribution of many n-grams: how the first "n minus 1" items can be followed by a next item.
  * This must be done with a functor such that the n-grams can be of any item type--strings, ints, anything comparable--even though the executable will only use it with strings.
  * Your code is functional with no mutation.
  * You choose efficient data structures and reasonable, clear types.
    * e.g. if you have something like `type 'tok t = int * 'tok N_gram.t`, you should probably instead have `type 'tok t = { frequency : int ; ngram : 'tok N_gram.t }`.
* If you're about to ask a question on Courselore like "Am I allowed to do x?", first ask yourself if it is in direct conflict with any of the requirements above. What is given above is what must *at least* be in your code; it is not what *only* may be in your code. You can do whatever you'd like outside of the above requirements. Just fulfill those requirements, and you're fine.
* We also expect that you sufficiently test your code.
  * We expect good code coverage.
    * Anything testable should be in your library instead of your executable. You must use `Bisect` to show at least 95% code coverage.
    * In addition, write  at least one `Base_quickcheck` random test for one of your OUnit tests following the [Quickcheck lecture](https://pl.cs.jhu.edu/fpse/lecture/specification-test.html#quickcheck). Since the input data is random, you may not necessarily know the correct answer but it suffices to perform sanity checks. For example, the requirements indicate a need to sanititize the input strings, and you could perform some check on this function.
      * Indicate with a very clear comment containing the capitalized word "INVARIANT" somewhere inside of it to help the graders find your invariant test.
  * Notice that only library functions are susceptible to coverage. You should test your executable as well to increase your chances at a good autograder score, but you will not be graded on executable testing.

### Submission and grading

* Make sure your `dune` files are updated for each library you make. Any file you create should be added to the zip rule, and your libraries should be dependencies of `ngrams.exe`.
* Run a final `dune clean` and `dune build`, and upload `_build/default/assignment6.zip` to Gradescope.
* Any requirement expressed or suggested in this file is subject to grading. Make sure you've read it carefully. Design and implement your solution with all requirements in mind.
