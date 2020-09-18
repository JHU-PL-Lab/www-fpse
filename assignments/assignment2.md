Assignment 2: Variants, records, modules and executables
--------------------------------------------------------------

For this assignment you will be writing a binary tree library, some auxiliary functions
for manipulating file information, and finally a standalone executable giving file information.
There are three Sections to the homework.  In order to help you ease into it we will make two due dates, Part I will be Sections 1-2 and Part II will be Section 3.  You will submit the whole assignment each time.

### The file structure

* [Use the this zip file](assignment2.zip) as the starting point for your assignment.  Download and unzip it in a fresh directory/folder that you made (we will suppose you are putting it in a directory `assignment2` in the below).  
* Like assignment 1, we are giving you a skeleton to fill in.  Your answers will go in the files  `.../assignment2/src/trees.ml` (tree and file library code) and `.../assignment2/src/cloc.ml` (executable for Section 3).
* The only other file you will want to edit is `.../assignment2/tests/tests.ml` which contains some initial tests; these tests are not complete and you should add a few more.  Concretely, in the Part II submission we will make sure you added at least 10 tests of your own, each of which covers a slightly different scenario so they are not overly redundant.
* We have made initial `dune` files which generally should work but you can add additional libraries if needed.

### Resources
Here are a few additional resources to keep in mind to help with this assignment.

* For Section 3 we in particular recommend adding the library [`ppx_deriving_yojson` (click for docs)](https://github.com/ocaml-ppx/ppx_deriving_yojson), see the files for details.  This library uses the polymorphic form of variants briefly covered at the end of the [variants lecture](../variants.html).
* In this assignment we are giving you the `Tree` module signature in the form of the file `tree.mli`.  This is the "type" of the module, and you need to construct all the things in the module.  See the [Basic Modules](../basic-modules.html) lecture for more information on this, and there is a [simple-set.zip](http://pl.cs.jhu.edu/pl/fpse/code/simple-set.zip) example there which shows how this works if it is unclear.
* We recommend you use [`Core.Sys`](https://ocaml.janestreet.com/ocaml-core/latest/doc/core/Core__/Core_sys/index.html) and [`Stdio`](https://ocaml.janestreet.com/ocaml-core/latest/doc/stdio/Stdio/index.html) libraries in Section 3.

### Submission and Grading
* We will follow the same protocol for Gradescope submission as with Assignment 1
* We will start evaluating your style as of this assignment, please consult the [FPSE Style Guide](../style-guide.html).
* When you are all done the homework, from directory `.../assignment2` run the command `zip -r submission.zip *` or similar to zip up all the files. Please do a `dune clean` before this so you are submitting only the code, not the binaries.


