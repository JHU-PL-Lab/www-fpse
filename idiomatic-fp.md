
## Idiomatic Functional Programming
This a major theme of the course; we have already covered some of this but let's put it all together now.

* design principles, design patterns, refactoring (OO) = principles & idioms (FP)
* **Principles**: overarching principles; **Idioms**: more focused ideas to aid in achieving principles

### FP Principles

1. "Concise is nice"
 - Goal of making code as short as possible
 - From the classic Strunk and White English writing guide:
     > A sentence should contain no unnecessary words, a paragraph no unnecessary sentences, for the same reason that a drawing should have no unnecessary lines and a machine no unnecessary parts (**and, code should have no unnecessary constructs**).
 - Concise code means on a larger program more will fit in your brain's working set
 - This focus on concision mirrors mathematicians who are obsessed with this in their writing
     - Perhaps in an unhealthy way sometimes
2. Modularity / focus of responsibility
  - Make clear, strong divisions of responsibility between different modules and functions
  - Attempt to make this factoring of responsibilities the most elegant which will aid in theme 1. above.
  - (This is also a theme of OO design, a similar principle applies there)
3. Avoid side effects; it will help you achieve 1. and 2.
  - Recall how pure functional code is referentially transparent, the behavior is all in the interface with no "hidden" effects.
  - Conversely, use side effects instead of standing on your head to make something functional
  - Side effect world view is a state machine vs functional view as a pipeline explicitly passing data on
  - Get your head into pipeline mode when writing functional code
  - If the pipeline metaphor is failing, add state
     - And if you are a beginning FPer, try three more times to get the pipeline view going
4. Speed schmeed (much of the time)
  - There is always a trade-off in programming between efficiency and elegance
  - Prioritize concision and modularity over running time and space
  - **unless** speed matters (the point is, it often does not)
    - If speed was so important, Python and JavaScript would not exist; they are ~5-10 times slower.
    - Do generally avoid high polynomial or exponential algorithms
    - Also pay more attention when data sets get very large, even n vs n log n gets noticeable there.

### FP Idioms

Here is a list of idioms, many of which are review as we touched on them before

#### Don't Repeat Yourself (DRY from OO): 
  - Extract duplicate code into its own function
  - Code usually won't be exact duplicate; extract different bits as function parameters
  - May also entail replacing specific types with generic types `'a` or functor parameter types `t`, `elt` etc

#### Hide it behind an interface
  - If a function is an auxiliary function to another function, define it in the body of the latter.
  - If a function is not local to a single function but is not used outside its module, leave it out of the module type which will hide it to module users
  - Make a new module for a new data type, include operations on the type (only) in it
     - This is not just for generic data structures lke `Map`/`Set`, it is for app-specific data structures
  - Hide types `t` in module types if users don't need to see the details
    - But, open it up if needed for e.g. testing
  - Write specifications (preconditions, postconditions, invariants)
    - Users can then program to the spec., not the implementation
  - Replace imperative code with an equivalent functional implementation which has a clearer interface

#### Have a focus of responsibility
  - Each function and module should have a clear focus that can be summarized in a sentence
  - Divide one function/module into two if it is doing two different things
  - A module should have a very clear focus of responsibility
    - Don't add random stuff to module if it doesn't fit with it's summary purpose
    - If you need more in an existing module, make a new one and `include` the old one
      - Don't just put the new additional functions in some random user-module

#### Concision
  - **Combinize**: replace recursion with `map`s, `fold`s and the like
    - and, for your own data structures write your own combinators and then use in place of `rec`
  - Use advanced pattern matching (`as`, `with`, deep patterns, partial record patterns, `_`, etc)
  - Use `|>` in place of call sequences, use `@@` in place of parentheses
  - Inline simple `let` definitions to make code read as a concise sentence
    - Also a small function called only once or twice may read better inlined
    - Conversely, make more `let` definitions if the code is too convoluted
  - Avoid `long_variable_names_containing_too_much_detail`
    - Conversely, don't use `x` `f` etc unless it is very local (in which case it is preferred)
    - Variables tend to have more local scope in FP compared to OO, shorter is better in FP
    - Declared function names on the other hand can be longer since their scope is broader
    - The general principle is there is a spectrum of local to global
      - The more local the shorter the name, the more global the longer the name


## Efficiency

* Our main goal is conciseness, but in some cases efficiency does matter
* So, here is an initial discussion of some efficiency issues in FP; more later as well

### Tail recursion

* A tail-recursive function is a function where there is no work to do after returning from recursive calls
  - Just bubble up the result
* Observe: since there is no need to mark the call point to resume from, no stack is needed!
 - Overwrite the parameters going "down", and return the base case at the bottom, done!
* Compilers take advantage of this to get rid of stack in this case
* Moral: to save space/time you may want to tail-call

#### Folding left vs right and tail calls

`fold_right` is not tail-recursive; here is an implementation:

```ocaml
let rec fold_right ~f ~init l = 
match l with
  | [] -> init
  | h::t -> f h (fold_right ~f ~init t)

let summate l = fold_right ~f:(+)  ~init:0 l
let concatenate l = fold_right ~f:(^) ~init:"" l
```

* Observe: after each recursive call completes, it must compute `f h rec-call-result`
* That is how folding right can start from the right, it computes `f` on the way up the call stack.
* Folding left is the opposite, computing `f` and passing accumulated result *down* the call stack:

```ocaml
let rec fold_left ~f ~init l = 
match l with
  | [] -> init
  | h::t -> fold_left ~f ~init:(f init h) t

let summate l = fold_left ~f:(+) ~init:0 l
let concatenate l = fold_left ~f:(^) ~init:"" l
```

* Observe that in the recursive case when the `fold_left` completes at the base case there is no more work to do
* Thus, `fold_left` is tail-recursive
  - The `init` of the base case is in fact the final result.
* So, if the choice doesn't matter, use `fold_left` ovef `fold_right`
* `Core` has `fold` as an abbreviation of `fold_left` to bias you to use it over right fold.
* If you are doing millions of iterations, you may have to refactor your code to use tail calls
  - Or you could run out of memory
  - Yes, this is a bit of a wart on the FP approach, sometimes you need to be aware of non-tail calls


### Imperative vs functional data structures

`List` vs `Array`
 * Adding an element to the front (extending list) is constant time for list, O(n) for array 
   - different lists can share tail due to referential transparency
 * But, instead of adding to array you are usually updating in-place which is constant
 * Updating one element of a list is worst-case O(n) - re-build whole list
 * Random access of nth element: O(n) list, O(1) array.

`Map` vs `Hashtbl`
 * `Map` is implemented like the `dict` of the homework, but avoids the worst case of an unbalanced tree (on average the `dict` should be good but it could build a long thin tree in worst case)
 * O(log n) time for `Map` to look up, add, or change an entry
 * O(1) for `Hashtbl` - will matter for really big data sets.

`Set` vs `Hash_set`
* See previous; again the mutable is constant and the immutable is O(log n) for common operations

* [Here is a summary of OCaml data structure complexity](https://ocaml.org/learn/tutorials/comparison_of_standard_containers.html) (for the standard OCaml library but same results as `Core` version)

* Is functional ever any better?  Yes!
  - If you have many related maps, e.g. repeatedly forking off a map into two sub-versions
  - Due to referential transparency the cost of copying is **zero**!!
  - See [Real World OCaml](https://dev.realworldocaml.org/maps-and-hashtables.html) for example benchmarks of this

### Examples of Idiomatic and not so Idiomatic FP
  * We already have seen several, will do more
