
## Idiomatic Functional Programming

* A major theme of the course
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
2. Avoid side effects; it will help you achieve 1.
  - Conversely, use side effects instead of standing on your head to make something functional
  - Side effect world view is a state machine vs functional view as a pipeline explicitly passing data on
  - Get your head into pipeline mode when writing functional code
  - If the pipeline metaphor is failing, add state
    - And if you are a beginning FPer, try three more times to get the pipeline view going
3. Modularity / focus of responsibility
  - Make clear, strong divisions of responsibility between different modules and functions
  - Attempt to make this factoring of responsibilities the most elegant which will aid in theme 1. above.
  - (This is also a theme of OO design, a similar principle applies there)
4. Speed schmeed (much of the time)
  - There is always a trade-off in programming between efficiency and elegance
  - Prioritize concision and modularity over running time and space
  - **unless** speed matters (the point is, it often does not)
    - If speed was so important, Python and JavaScript would not exist; they are ~5-10 times slower.
    - Do generally avoid high polynomial or exponential algorithms

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

#### Have a focus of responsibility
  - Divide one function into two if it is doing two different things
  - A module should have a very clear focus of responsibility
    - Don't add random stuff to module if it doesn't fir with it's big picture
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
    - Conversely, don't use `temp1` etc unless code is highly local
    - Variables tend to have more local scope in FP compared to OO, shorter is better in FP
    - 

### Examples of Idiomatic FP
  * We already have seen many, we will do a couple more now

* Go through some imperative to functional code refactorings
* The expression problem and functional vs OO trade-off.

## Efficiency
* fold l vs r, tail calls
* Imperative vs functional: Map vs Hashmap, Set vs Hashset

* Contrasting OO with functional - state machine vs pipeline of data (data-oriented design).
