Assignment 1: OCaml Introduction (DRAFT)
--------------------------------

You are to write several small programs in OCaml. 

### The file structure

* [Use the this zip file](assignment1.zip) as the starting point for your assignment.  Download and unzip it in a fresh directory/folder that you made (we will suppose you are putting it in a directory `a1` in the below).  
* We are starting right off with the standard file structure recommended for projects built with the `dune` build tool, and you will be using `dune` to test your program.  Please keep this file structure in your coding and submission.
* The file `.../a1/src/assignment1.ml` is where you will put your answer code.  Currently it has `unimplemented ()` for all the functions, replace that with your code.
* The only other file you will want to edit is `.../a1/tests/tests.ml` which contains some initial tests; these tests are not complete and you should add a few more.
* There is a `.../a1/src/dune` and `.../a1/tests/dune` file we set up for you, they should allow you to run commands `dune build` and `dune test` respectively from the top level directory `.../a1/` to build and/or test your code.  Note you want to stay in the top level to run these commands, unlike `make`, `dune` automatically runs builds in subdirectories.
* When you are all done the homework, from directory `.../a1` run the command `zip -r . submission.zip` or similar to zip up all the files. Please do a `dune clean` before this so you are submitting only the code, not the binaries.

### Resources to help you

Here is a reminder of some resources at your disposal.

-   Consult the [lecture notes posted on the dateline](../dateline.html), and if you want to re-watch any lecture they are on Panopto as per the link pinned on Piazza.
-   Consult the [Course Coding page](../coding.html) for information on installing OCaml and getting a good toolchain setup for development.
-   You are required to use OCaml version 4.10.0 as that is the version we will test your code on.
-   If you are looking for how some standard library function is expressed in OCaml, like not equal, etc, consult the [Caml Pervasives](https://ocaml.org/releases/4.10/htmlman/libref/Stdlib.html) which are the predefined functions available in OCaml.
    - Note there is one exception to this, `Core` overrides the comparison operations to only work on `int`s.  To perform `=`, `<` or the like on e.g. floats you need to write `Float.(=) 3.2 4.7` for example to check for equality on `3.2` and `4.7`, and similarly for `<` etc.
- You can use the `Core` library list functions for the questions we indicate; those functions are generally described under the `Base` docs which is a subset of `Core`, [here](https://ocaml.janestreet.com/ocaml-core/latest/doc/base/Base/List/index.html).
-   You are strongly encouraged to work with other people on the assignment. You just need to list the names of people you worked with. However remember that you should submit your own write up of the answers. **Copying of solutions is not allowed**. For the full collaboration policy see [here](../integrity.shtml).
-   Come to office hours to get help from Prof and CAs.  Office hours are posted on Piazza.
-   Use Piazza for online help and question clarification.

### Coding Methods
- There are two ways you can test your code in OCaml, (1) you can use the top loop (`utop`) to informally run some tests on it, and (2) you can run the `dune test` script which runs all of the small suite of tests in the file `tests/tests.ml` and reports the results. 
    - To load all of your functions into the top loop in one go you can use the OCaml top-loop directive `#use "submission.ml;;` which is the same as copy/pasting that file into the top loop as input.  Make sure you started `utop` from the directory in which the file `submission.ml` is found for this to work.
- It is up to you which way you prefer working in but both have their advantages and we suggest you do some of each.

### Submission and Grading

-   We will be using [Gradescope](https://gradescope.com) to submit programming assignments. The Gradescope entry code is posted on Piazza.
-   When asked, upload your `assignment1.zip` file which you created as described above.
-   We are going to hand-grade your code, but the autograder will at least run some sanity checks on it to make sure it is building properly.  Note that if `dune build` and `dune test` are not working on your own computer it won't pass our sanity checks, either.
-   If you can't fix the Gradescope error and/or it makes no sense, post to Piazza or see someone in office hours.
-   You can submit the HW as many times as you want up to the deadline. Any submissions after the deadline will fall under the late submission policy.
-   Please submit your draft HW at least once well ahead of the deadline, so you do not find some problem right at the deadline.

