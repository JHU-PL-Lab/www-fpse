Assignment 3: Variants, records, modules, functional data structures
--------------------------------------------------------------

In this assignment, you will be writing a binary-tree-based dictionary library.

### File structure and requirements

* [Use this zip file](assignment3.zip) as the starting point for your assignment. 
* In previous assignments, we gave you an `.mli` and a skeleton of the `.ml` to fill in. This time, you are given just the `.mli` and only a small bit of starter code in `.ml`. Your answers go in these files:
  * `src/simpledict.ml`
  * `src/simpletree.ml`
  * `test/tests.ml`
* These are the only coding files you will submit, so your solution must not involve any other file.
* Most of the instructions for this assignment are in the `.mli` files.
* You are given some initial tests in `test/dict_tests.ml` and `test/tree_tests.ml`. You must add at least 10 non-redundant `assert_equal` statements to `test/tests.ml` to cover your implementations of `Simpletree` and `Simpledict`. You will be graded on adding these 10 tests.
  * While we provide a test for each function, what we provide is not exhaustive.
  * Just a few examples of tests you might like to add are:
    * Nontrivial trees with `is_ordered` and `is_balanced`.
    * Structure preservation of `map`.
    * All cases of `combine`.
* We have given you `dune` files which work out of the box. You may add libraries to them if you would like, but you should not need to.

### Resources
Here are a few additional resources to keep in mind during this assignment.

* See the [Basic Modules](https://pl.cs.jhu.edu/fpse/lecture/basic-modules.html) lecture for information on filling in the module signatures (i.e. writing the `.ml` files such that they compile along with the `.mli` files).
* In particular, see the [set-example.zip](https://pl.cs.jhu.edu/fpse/examples/set-example.zip) example.

### Submission and Grading
* Follow the same protocol for Gradescope submission as previous assignments.
  - do a final `dune clean; dune build` from the main directory and submit the `_build/default/assignment3.zip` file.
* The submitted files include only the files you are supposed to edit, along with your `dune` files. Notably, you do not submit the provided test files or the provided `.mli` files.
* We will grade the style of your code. Please consult the [FPSE Style Guide](https://pl.cs.jhu.edu/fpse/style-guide.html).
* You will also be graded on your added tests.
* You will be graded on having the correct time complexity as is written in some function descriptions. You will lose points if you have time complexity worse than is required.