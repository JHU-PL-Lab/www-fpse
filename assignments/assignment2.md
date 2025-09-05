Assignment 2: List module, special integers, and the Towers game.
--------------------------------

This assignment is split into three separate files, each unrelated to the other.
* `src/reimplementation.ml`: you write new solutions to some problems from Assignment 1, but you can only use the `List` module and *cannot* use explicit recursion (i.e., no `let rec`).
* `src/divisors.ml`: you write a few functions around divisors of integers.
* `src/towers.ml`: you verify that the solution to a Towers game is correct.

### File structure and requirements

* [Use this zip file](https://pl.cs.jhu.edu/fpse/assignments/assignment2.zip) as the starting point for your assignment. Download and unzip it.  
* Your code will go in three files, each of which contains a full description of the requirements for that file:
    * `src/reimplementation.ml`
    * `src/divisors.ml`
    * `src/towers.ml`
* Thoroughly read the instructions in each of these files and write your code to follow the instructions.
* You must add five non-redundant `assert_equal` statements to the tests in `test/tests.ml`.
    * Note there are other provided tests in the following files:
        * `tests/reimplementation_tests.ml`
        * `tests/divisors_tests.ml`
        * `tests/towers_tests.ml`
    * Your new `assert_equal` statements must be complementary to all tests in these files. Your tests can be on any part of this assignment (e.g. on divisors, towers, etc.).
* There are corresponding `.mli` files that state which functions you must have in your submission. You will not submit these files, so do not edit them. If you edit them, then Gradescope may fail to run your code.  Note that for this assignment we also list all funtions you need to define in the `.ml` files so you can largely ignore them now; it is more of a warm-up to how real OCaml development works.
* The `dune` files are set up for you. They allow you to run `dune build` and `dune test` from the top level directory `assignment2/`

### Resources to help you

Here is a reminder of some resources at your disposal.

-   Consult the [Basic OCaml lecture notes](https://pl.cs.jhu.edu/fpse/basic-ocaml.html), and if you want to re-watch any lecture they are on Panopto as per the link pinned on Courselore.
-   [Real World OCaml Chapter 1](https://dev.realworldocaml.org/guided-tour.html) is another tutorial introdution in a somewhat different order than we are doing.
-   If you are looking for how some standard library function is expressed in OCaml, like not equal, etc, consult the [Caml Stdlib](https://v2.ocaml.org/manual/stdlib.html) which are the predefined functions available in OCaml.
 - Note that `Core` overrides some of these including the comparison operations which only work on `int`s.  To perform `=`, `<` or the like on e.g. floats you need to write `Float.(=) 3.2 4.7` for example to check for equality on `3.2` and `4.7`, and similarly for `<` etc.  To see what is actually loaded look at the [Core documentation](https://ocaml.org/p/core/latest/doc/index.html).
- Use `Core`'s `List` module functions where possible; those functions are generally described under the [`Core` list docs](https://ocaml.org/p/core/latest/doc/Core/List/index.html).
-   You are allowed to work with other people on the assignment; you just need to list the names of people you worked with. However, remember that you should submit your own write up of the answers. **Copying of solutions is not allowed**. For the full collaboration policy see [here](https://pl.cs.jhu.edu/fpse/integrity.html).
-   Come to office hours to get help from Prof and CAs.  Office hours are posted on Courselore.
-   Use Courselore for online help and question clarification.

### Coding Methods

* There are two ways to test your code.
    * Run it in the top loop with `utop`. To load all of your functions into the top loop in one go you can use the OCaml top-loop directive `#use "src/submission.ml";;` which is the same as copy/pasting that file into the top loop as input. Make sure you started `utop` from the `assignment2/` directory for this to work. Alternatively, you can use the `dune utop` command to load your code upon starting.
    * Run `dune test` from the main directory (`assignment2/`). All of these tests should pass because we will run it when you submit your code. Remember to add five of your own tests.
- Note that all `dune` commands should be run directly from the `assignment2/` directory **ONLY**. `dune` automatically will also run the build files in any sub-directories by default, so this will run the `dune` files in `src/` and `test/` if required. Also note that `dune test` will implicitly invoke `dune build` if your code is not compiled yet.

### Submission and Grading

* Follow the same procedure as Assignment 1 to upload to Gradescope.
    * Run `dune clean; dune build` and submit the zip file at `_build/default/assignment2.zip`.
* The autograder will run the tests we gave you and any additional tests you add.
    * You will be graded on adding five additional tests.
* The autograder will also run our own tests that you might not see (yet). Ensure your own tests are complete to pass all of our hidden tests.
* We will hand-inspect your code, but we won't enforce style guidelines until the next assignment.
* You can submit the HW as many times as you want up to the deadline. Any submissions after the deadline will fall under the late submission policy.
* Please submit your draft HW at least once well ahead of the deadline, so you do not find some problem right at the deadline.

