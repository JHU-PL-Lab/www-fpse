Assignment 2: Variants, records, modules and executables
--------------------------------------------------------------

For this assignment you will be writing a binary tree based dictionary library,
and a standalone executable extracting some simple information from a file tree.

There are two Parts to the assignment, with two due dates.  You will submit the whole assignment each time.

### The file structure

* [Use the this zip file](assignment2.zip) as the starting point for your assignment. 
* Like assignment 1, we are giving you a skeleton to fill in.  Part I questions are in file `.../assignment2/src/simpledict.mli` and your answers will go in the file  `.../assignment2/src/simpledict.ml` (tree and dictionary library code). Part II is an executable to go in `.../assignment2/src/keywordcount.ml`, and also put any additional functions you need in `.../assignment2/src/simpledict.ml`.
* The only other file you will want to edit is `.../assignment2/tests/tests.ml` which contains some initial tests; these tests are *not complete at all* and you should add at least 20 tests which cover your functions reasonably well.
* We have made `dune` files which generally should work but you can add additional libraries if needed.

### Resources
Here are a few additional resources to keep in mind to help with this assignment.

* In this assignment we are giving you the `simpledict` module signature in the form of the file `simpledict.mli`.  This is the "type" of the module, and you need to construct all the things in the module in file `simpledict.ml`.  See the [Basic Modules](https://pl.cs.jhu.edu/fpse/lecture/basic-modules.html) lecture for more information on this, in particular the simple [set-example.zip](https://pl.cs.jhu.edu/fpse/examples/set-example.zip) example there.


* For Part II we recommend using the library [`ppx_deriving_yojson` (click for docs)](https://github.com/ocaml-ppx/ppx_deriving_yojson), see the files for details.  This library uses the polymorphic form of variants briefly covered at the end of the [variants lecture](https://pl.cs.jhu.edu/fpse/lecture/variants.html).
* We recommend you use [`Core.Sys`](https://ocaml.org/p/core/v0.15.0/doc/Core/Sys/index.html), [`core_unix`](https://ocaml.org/p/core_unix/v0.15.0/doc/index.html) and [`Stdio`](https://ocaml.org/p/stdio/v0.15.0/doc/Stdio/index.html) libraries in Part II.

### Submission and Grading
* We will follow the same protocol for Gradescope submission as with Assignment 1
  - do a final `dune build` from the main directory and submit the `_build/default/assignment2.zip` file.
* We will start grading your style as of this assignment, please consult the [FPSE Style Guide](https://pl.cs.jhu.edu/fpse/style-guide.html).

