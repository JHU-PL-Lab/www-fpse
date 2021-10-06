Assignment 2: Variants, records, modules and executables
--------------------------------------------------------------

For this assignment you will be writing a binary tree and dictionary library,
and a standalone executable extracting some simple information from a file tree.

There are two Parts to the assignment.  In order to help you ease into it we will make two due dates.  You will submit the whole assignment each time.

### The file structure

* [Use the this zip file](assignment2.zip) as the starting point for your assignment. 
* Like assignment 1, we are giving you a skeleton to fill in.  Part I questions are in file `.../assignment2/src/treedict.mli` and your answers will go in the file  `.../assignment2/src/treedict.ml` (tree and dictionary library code). Part II answers will go in `.../assignment2/src/histo.ml`.
* The only other file you will want to edit is `.../assignment2/tests/tests.ml` which contains some initial tests; these tests are *not complete at all* and you should add at least 20 tests which cover your functions reasonably well. (Note we did not structure the files in a way to allow you to test your histo auxiliary functions so testing on those is not required.)
* We have made initial `dune` files which generally should work but you can add additional libraries if needed.

### Resources
Here are a few additional resources to keep in mind to help with this assignment.

* In this assignment we are giving you the `Treedict` module signature in the form of the file `treedict.mli`.  This is the "type" of the module, and you need to construct all the things in the module in file `treedict.ml`.  See the [Basic Modules](../basic-modules.html) lecture for more information on this, in particular the simple [set-example.zip](../examples/set-example.zip) example there.


* For Part II we recommend using the library [`ppx_deriving_yojson` (click for docs)](https://github.com/ocaml-ppx/ppx_deriving_yojson), see the files for details.  This library uses the polymorphic form of variants briefly covered at the end of the [variants lecture](../variants.html).
* We recommend you use [`Core.Sys`](https://ocaml.janestreet.com/ocaml-core/latest/doc/core/Core__/Core_sys/index.html) and [`Stdio`](https://ocaml.janestreet.com/ocaml-core/latest/doc/stdio/Stdio/index.html) libraries in Part II.

### Submission and Grading
* We will follow the same protocol for Gradescope submission as with Assignment 1
  - do a final `dune build` from the main directory and submit the `_build/default/assignment2.zip` file.
* We will start evaluating your style as of this assignment, please consult the [FPSE Style Guide](../style-guide.html).



