The FPSE Mini-Projects
---------------------

For the final Assignment you are to conceive, design, and implement your own standalone application in OCaml.  This represents the culmination of what you have learned in the course.  Given that there is a month for this assignment the scope will be scaled appropriately.

### Requirements
Here are some high-level requirements for the mini-projects.

* All the code must be in OCaml obviously (excepting small bits of glue code)
* You should use the course libraries -- `Core`, `Async`, `Yojson` etc -- as your basis, plus any other libraries you find useful.
* You are encouraged to partner up although there is no requirement to; effort will be scaled accordingly (i.e. two people should have twice as much "stuff" in the end as one person).
* A very rough idea of the scope of the project is around 250-500 lines of code per person.
* There will be two official check-ins: there will be an in-class lab after Thanksgiving with a submission shortly after, and there will be a final demo and code submission on Dec 18th.

### Project Topic Thrusts

* You will need to make a standalone application as you did in assignments 2 and 4.
* Given the time available, we suggest focusing one of the three following tracks.
    1. Libraries: create an application using some of the powerful libraries (see list below).
    2. Algorithm: stick to the class libraries but create a useful algorithm in the model of Assignment 4.
    3. Monad: Re-write some standard algorithms in monadic style.
* Note the above tracks are not necessarily mutually exclusive.
  
### Specific Topic Areas and Associated Libraries

#### Web-based

* We recommend the simple [`Cohttp_async`](https://github.com/mirage/ocaml-cohttp) for both web client (API reading / crawling) and server applications.
* See [Real World OCaml Chapter 15](https://dev.realworldocaml.org/concurrent-programming.html#scrollNav-3) for an example of how to perform http requests with `Cohttp_async`.
* `Cohttp` also supports lightweight web server development.  See the [tutorial](https://github.com/mirage/ocaml-cohttp#basic-server-tutorial) in the `Cohttp` documentation.
* Write a browser app in OCaml, and compile it to JavaScript to run in the browser via [`js_of_ocaml`](https://ocsigen.org/js_of_ocaml/3.7.0/manual/overview).

#### Persistence

* Make a command-line application which persists data in either a file or database.
* If you are familiar with databases, the [sqlite3-ocaml](https://github.com/mmottl/sqlite3-ocaml) and [postgresql-ocaml](https://mmottl.github.io/postgresql-ocaml/) bindings should work for accessing SQLite or Postgres databases from within OCaml.

#### Data Processing
* [Owl](https://ocaml.xyz/book/) is a very well-documented numerical processing library.
* [ocaml-bimage](https://github.com/zshipko/ocaml-bimage) is an image processing library.

#### And more!

* There are many OCaml libraries as well as bindings to existing C etc libraries
* The [OCamlverse Ecosystem page](https://ocamlverse.github.io/content/ecosystem.html) lists many libraries available.
   - Note that some libraries in the list are not particularly up-to-date or reliable or well-documented.  They are roughly sorted though so start with the ones at the top of a given list.
* [Awesome OCaml](https://github.com/ocaml-community/awesome-ocaml) is another such list.

### Some concrete ideas to get the juices flowing

Here are three concrete clusters.

#### Async and web related

* Web crawler using Async, e.g. for word counting
* Command-line web API usage using Async
* RESTFul API collator/processor - see e.g. [Rapid API](https://rapidapi.com) for APIs available

* Simple website
* RSS feed

#### Simple command-line app with persistence
* A command-line minesweeper application with persistence
* To-do or scheduling or memo command-line app
* Other simple terminal-based game

#### Scientific / Machine Learning
For those with some background in this area

* A simple machine learning app using PyTorch or Tensorflow and possibly graphing it in Owl.  [Jane Street Article](https://blog.janestreet.com/deep-learning-experiments-in-ocaml/)


### Submissions

* There will be two submission points in Gradescope, one for the initial design and one for the final code
* The initial design submission must include
  1. An overview of the purpose of the project
  2. A proposed list of libraries you plan on using
  3. Commented module type declarations which will provide you with an initial specification to code to
  4. It may also include any sketches or other information which will make it easier to understand your mini-project.
* The final submission will in addition include 
  0. All of the code of course!
  1. It should include a dune file which successfuly builds your project
  2. It should include a `Readme.md` at the top outlining how to build and run the project.  If any other `opam` installs are needed outside of the offical course list, describe them in your `Readme.md`.
  3. You will also need to include a test suite with good coverage.
* We will put up two submission points in Gradescope for you to upload your zipped hierarchies for the Design and Final submissions.  Please include all the source files needed to build the project but no binary or built files.
