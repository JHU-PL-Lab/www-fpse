Assignment 4: Executables, File I/O, S-expressions
--------------------------------------------------------------

In this assignment, you will write an executable to count the number of occurances of each OCaml keyword in a given directory.

### File structure and requirements

* [Use this zip file](assignment4.zip) as the starting point for your assignment. 
* You are given instructions in `src/lib/histogram.mli` to write a `Histogram` module that you will use to count keywords.
  * Implement this module in `src/lib/histogram.ml`.
  * The starter code is incomplete as given. You will need to read the `mli` file and fill in some well-typed value in the `ml` file for each declaration to get the project to build.
  * You may _add_ to the `mli` if needed, but you may not change or delete anything that exists there as given.
  * The histogram works on keywords. A `Keyword` module is implemented for you in `src/lib/keyword.ml`.
* You'll write an executable in `bin/keywordcount.ml`. There are full instructions in that file, and there are lots of tips for this assignment. Some starter code is provided to help with command-line argument parsing.
  * Before beginning anything on this assignment, you should read `src/bin/keywordcount.ml`.
* If you need any helper functions that might be tested, then they go in `src/lib/utils.ml(i)`.
* You are given some initial (incomplete) tests in `src-test/hist_tests.ml` and `src-test/exec_tests.ml`.
  * You must add at least 10 non-redundant `assert_equal` statements to `src-test/tests.ml` to test your code in the `Histogram` and/or `Utils` modules.
  * You are not graded on the total testing coverage of any part of your code, but moving helper functions to `src/lib/utils.ml(i)` gives you more ways to hit those 10 non-redundant `assert_equal` statements.
* We have given you `dune` files which generally should work, but you can add libraries if needed.

### Submission and Grading
* Follow the same protocol for Gradescope submission as previous assignments.
  - do a final `dune clean; dune build` from the main directory and submit the `_build/default/assignment4.zip` file.
* The submitted files include only the files you are supposed to edit, along with your `dune` files and any additional testing resources in the `test/` directory. You do not submit the provided `ml` test files, but you will submit the `mli` files.
* We will grade the style of your code. Please consult the [FPSE Style Guide](https://pl.cs.jhu.edu/fpse/style-guide.html).
* You will also be graded on your added tests.