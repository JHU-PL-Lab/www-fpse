Assignment 3: Modules and Testing
---------------------------------

For Part I of this assignment you will be writing various modules, module types,
and functors, to better understand how they work.  You will also use them
a little bit to be sure they actually work.

For Part II you will write your own test suite from scratch, and configure it to use
the Bisect code coverage tool which will verify you have good coverage with your tests.  You will also write a couple specifications.

As usual we will give two due dates for the two parts.

### The file structure

* [Use the this zip file](assignment3.zip) for your assignment.  Download and unzip it in a fresh directory/folder that you made (we will suppose you are putting it in a directory `assignment3` in the below).  
* Like assignment 1-2, we are giving you a skeleton to fill in.  Your Part I answers will go in the file  `.../assignment3/src/abstraction.ml` and Part II will be in `.../assignment3/test/`.
* We have made initial `dune` files which generally should work but you can add additional libraries if needed.

### Part II
* Your primary task in Part II is to write your own test suite which has good coverage of the code you wrote for part I.
* You will also need to incorporate the Bisect tool into your dune file yourself, and use its output to improve the coverage of your test suite.
* Lastly we would like you to write some specifications for various functions as per the lecture, which we now list.

#### Specifications to write

 1. For the `Multiset.union` specify a post-condition reflecting the fact that it is a union of multisets.
 2. Write a data structure invariant on the type of trees `'a t` in your binary tree `Dict` implementation.
 3. Write a recursion/loop/fold invariant for your `mode` function of exercise 5.
 4. For Exercise 6b, write a data structure invariant on your `Hashtbl`

For each of the above, add your specifications as comments to your existing code.

### Resources
Here are a few resources to keep in mind to help with this assignment.

* Make sure to review the [lecture notes on modules and functors](../more-modules.html) for Part I.  
* If you feel like you need more on the subtleties of information hiding in functors, the [Real World OCaml book chapter on functors](https://dev.realworldocaml.org/functors.html) may be worth looking at.
* For part II this was covered in the [Specification and Testing Lecture](../specification-test.html); these notes also contain links to OUnit and Bisect documentation.

### Submission and Grading
* From directory `.../assignment3` do a `dune clean` and then run the command `zip -r submission.zip *` or similar to zip up all the files for submission.