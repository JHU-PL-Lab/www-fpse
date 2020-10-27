Assignment 4: N-Grams and a real app
------------------------------------

For Part I of this assignment you will be writing various modules and functions which will lead to a n-gram model generator.  This is Exercises 1-8 in the file `src/lib.ml` (at the download link below).  Nearly all the details of the assignment you will find in that file.

For Part II you will 

  1) make a standalone app which uses the functions from part I. That is exercises 8 and 9 in `lib.ml`.
  2) You will also need to write a test suite for your application.  Note we recommend you start on this in Part I of the submission so you can help debug issues in your code more quickly.
  3) In addition, for your exercise 8 sanitizer answer write a `Base_quickcheck` random test as one of your OUnit tests following the [Quickcheck lecture](../specification-test.html#quickcheck).  To partially verify the random test data follows the specification just perform sanity checks, e.g. verify there are no "%" etc in the output, and that no words in the input were dropped.

As usual we will give two due dates for the two parts.

### The file structure

* [Use the this zip file](assignment4.zip) for your assignment.  Download and unzip it in a fresh directory/folder that you made (we will suppose you are putting it in a directory `assignment4` in the below).  
* Like assignment 1-3, we are giving you a skeleton to fill in.  Your Part I answers will go in the file  `.../assignment4/src/lib.ml` and Part II will mostly be in `.../assignment4/src/ngrams.ml`.  You will also need to make a unit tester in `.../assignment4/tests/tests.ml` etc following the previous assignments.

### Submission and Grading
* From directory `.../assignment4` do a `dune clean` and then run the command `zip -r submission.zip *` or similar to zip up all the files for submission.