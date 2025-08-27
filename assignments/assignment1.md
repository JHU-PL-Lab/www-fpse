Assignment 1: OCaml Introduction
--------------------------------

In this assignment, you are to write several small programs in OCaml.

### The file structure

* [Use this zip file](https://pl.cs.jhu.edu/fpse/assignments/assignment1.zip) as the starting point for your assignment. Download and unzip it.  
* We are starting right off with the standard file structure recommended for projects built with the `dune` build tool, and you will be using `dune` to test your program.  Please keep this file structure in your coding and submission.
* The file `assignment1/src/submission.ml` is where you will put your answer code.  Currently it has `unimplemented ()` for all the functions, replace that with your code.
    * You may add `rec` to any function you'd like.
    * You can add any auxilliary functions of your own; put them right before you need to use them.
* You may also edit `assignment1/test/tests.ml` which contains some initial tests. These tests are not complete, and you should add more, but you are not required to.
* The file `assignment1/src/submission.mli` states which functions you are required to have in your submission. You will not submit this file. Your submission will not run on Gradescope if you have not defined every function described in `assignment1/src/submission.mli`.
* There is a `assignment1/src/dune` and `assignment1/test/dune` file we set up for you. They allow you to run commands `dune build` and `dune test` respectively from the top level directory `assignment1/` to build and/or test your code.  Note you want to stay in the top level to run these commands, `dune` automatically builds subdirectories.
* There is also an `assignment1/dune` file which just builds a zip of all the files for submission. When you are all done with the homework, perform a final `dune build` to build the zip. See the submission section below for more on this.

### Resources to help you

Here is a reminder of some resources at your disposal.

-   Consult the [Course Coding page](https://pl.cs.jhu.edu/fpse/coding.html) for information on installing OCaml and getting a good toolchain setup for development.
-   Consult the [Basic OCaml lecture notes](https://pl.cs.jhu.edu/fpse/basic-ocaml.html), and if you want to re-watch any lecture they are on Panopto as per the link pinned on Courselore.
-   [Real World OCaml Chapter 1](https://dev.realworldocaml.org/guided-tour.html) is another tutorial introdution in a somewhat different order than we are doing.
-   If you are looking for how some standard library function is expressed in OCaml, like not equal, etc, consult the [Caml Stdlib](https://v2.ocaml.org/manual/stdlib.html) which are the predefined functions available in OCaml.
 - Note that `Core` overrides some of these including the comparison operations which only work on `int`s.  To perform `=`, `<` or the like on e.g. floats you need to write `Float.(3.2 = 4.7)` for example to check for equality on `3.2` and `4.7`, and similarly for `<` etc.  To see what is actually loaded look at the [Core documentation](https://ocaml.org/p/core/latest/doc/index.html).
-   You are strongly encouraged to work with other people on the assignment. You just need to list the names of people you worked with. However remember that you should submit your own write up of the answers. **Copying of solutions is not allowed**. For the full collaboration policy see [here](https://pl.cs.jhu.edu/fpse/integrity.html).
-   Come to office hours to get help from Prof and CAs.  Office hours are posted on Courselore.
-   Use Courselore for online help and question clarification.

### Coding Methods
- Before you even open any files in VSCode, type `dune build` from the `assignment1/` directory.  This will set up the editor to recognize the libraries.
- There are two ways you can test your code in OCaml, (1) you can use the top loop (`utop`) to informally run some tests on it, and (2) you can run the `dune test` script from directory `assignment1/` which runs all of the small suite of tests in the file `tests/tests.ml` and reports the results. 
    - To load all of your functions into the top loop in one go you can use the OCaml top-loop directive `#use "src/submission.ml";;` which is the same as copy/pasting that file into the top loop as input.  Make sure you started `utop` from the `...assignment1` directory for this to work.
    - alternatively, you can issue the command `dune utop` which builds and starts `utop` with your code loaded. Then, type `open Submission;;` in `utop` to open up the module `Submission` comtaining your code so that you can directly use your functions.
- It is up to you which way you prefer, but both have their advantages, and we suggest you do some of each.  You are required to have the `dune test` mode working as that is how we will test your code.
- Note that all `dune` commands should be run directly from the `assignment1/` directory **ONLY**. `dune` automatically will also run the build files in any sub-directories by default, so this will run the `dune` files in `src/` and `test/` if required.  Also note that `dune test` will implicitly invoke `dune build` if your code is not compiled yet.

### Submission and Grading

-   We will be using [Gradescope](https://gradescope.com) to submit programming assignments. The Gradescope entry code is posted on Courselore.
-   Upload your `assignment1.zip` solutions file built by `dune` which you will find in `assignment1/_build/default/assignment1.zip`.
-   The Autograder will run the tests we gave you; it will also run additional tests that you might not see (yet).  On top of the autograder we will be hand-inspecting your code, but we won't be enforcing style guidelines yet.
-   If you can't fix the Gradescope error and/or it makes no sense, post to Courselore or see someone in office hours.
-   You can submit the HW as many times as you want up to the deadline. Any submissions after the deadline will fall under the late submission policy.
-   Please submit your draft HW at least once well ahead of the deadline, so you do not find some problem right at the deadline.

