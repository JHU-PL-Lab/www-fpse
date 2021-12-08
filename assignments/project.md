The FPSE Projects (REVISED 11/9/2021)
---------------------

For the projects you are to conceive, design, and implement your own standalone application in OCaml.  This represents the culmination of what you have learned in the course.  
### Requirements
Here are some high-level requirements for the projects.

* All the code must be in OCaml obviously (excepting small bits of glue code)
* Use the standard course libraries -- `Core`, `Lwt`, `Yojson` etc -- as your basis, plus any other libraries you find useful.
* Project groups can be from 1-3 people, any of these three options is good.
* A very rough idea of the scope of the project is around 1000-2000 lines of code per person.  This will depend a lot on the particular application; we will not be putting line count as part of your grade.

### Potential Project Topic Thrusts

* You will need to make a standalone application as you did/will do in assignments 2 and 4.
* Here are are three approaches to give some potential directions; feel free to do whatever you like though.

#### 1. A command-line app with persistence
* The idea here is to make some application where all the interaction is via the command line.
* Persistent data across command invocations could be saved in a file using the `Stdio` library.
* This path is the most straightforward of the three choices.
* Here is a simplistic example, you would need much more than this

* A minesweeper game.  Here is a mock of such a game:
```sh
$ ./mine.exe init 5x4 # initialize a new game, 5x4 board
-----
-----
-----
-----
$ ./mine.exe move 0,3
-----
-----
12---
 1---
$ ./mine.exe move 2,2
BOOM!
-----
-----
12*--
 1---
$ # etc
```
See [Simon Tatham's Puzzle Collection](https://www.chiark.greenend.org.uk/~sgtatham/puzzles/) for a bunch of ideas for games with running demos.

* For all command-line apps some ways to beef them up once the basic app is working include
  1. Replace the command line with a RESTful web server using [`Dream`](https://aantron.github.io/dream) mentioned below.
  2. In addition to 2., `Dream` supports html templates and you could "reply" to the `http` queries with html and so you can run your app in the browser.
  3. If you know JavaScript you can beef up 2. a bit with some dynamic content.
  4. Replace a file-based persistence model with a database; see the list of libraries below for Postgres and MySql bindings for OCaml.
  5. Rather than using your own ad-hoc format for data in the file or database, make your own JSON representation and use `yojson` to convert back and forth.  
    - You should do this from the beginning in fact, it will be easier and more robust.
  6. Add more options to the underlying application.  Think about ways to make the application more generic, which also can give you some practice at abstractions in OCaml.  For example for Minesweeper consider adding e.g. anti-mines (subtracting one instead of adding one), lighthouses (expose mines in an area around it), etc.

#### 2. Web client
If  you want to suck down some data from a public RESTful API, `Cohttp` is a good library to use. 

Here are some concrete project ideas involving web client:
* A command line app which would access, process, and present data from an existing RESTFul API collator/processor 
   - see e.g. [Public APIs](https://github.com/public-apis/public-apis) for a large list of APIs available
   - Some free APIs there include data for shopping, weather, recipes, COVID, etc etc 
   - One concrete idea could be to grab both historical weather and COVID data for a location using two different RESTful APIs and compute the correlation between temperature and new COVID cases five days later
   - etc etc etc.
* A web crawler app
    - starting from a URL grab it and all contained URL (up to some breadth and depth limit)
    - Then, compute some aspects on the pages, e.g. count how many lines of code, etc

#### 3. Scientific / Machine Learning

This approach is for those with some background in this area.

* A simple machine learning app using PyTorch or TensorFlow and possibly graphing it in Owl; see below for links to the OCaml libraries
* Here is a [Jane Street Article](https://blog.janestreet.com/deep-learning-experiments-in-ocaml/) on use of TensorFlow within OCaml.


### Libraries Catalog
Here is a list of well-maintained libraries we recommend using for the above approaches, as well as some lists you can find other libraries on.

#### Web-based

* All web-based applications may have delayed response or may fail, and so all of the web libraries below are built on an OCaml coroutine library, either `Lwt` or `Async`.  `Async` is the Core version, but it is not gaining a lot of traction so you will probably be better off with a library over `Lwt`.  
  - See the [coroutines lecture notes](../coroutines.html) for more information on using `Lwt`.
* We recommend the simple [`Cohttp_lwt_unix`](https://github.com/mirage/ocaml-cohttp) for web client (API reading / crawling) applications.
* We recomend [`Dream`](https://aantron.github.io/dream) for web applications.  (Note on Macs with homebrew you will need to  `brew install node`, `brew install openssl` and `brew install libev` along with the other install instructions. on Linux or WSL2 you will probably need to use `apt` to install similar libraries if you don't have them already.)  It supports full web applications.  If you just want to make a simple RESTful server, `Cohttp` (below) is also a good choice.
* [`Opium`](https://github.com/rgrinberg/opium) is a good alternative to `Dream` to consider as well.  Both are built on `Lwt`.
* `Cohttp` also supports lightweight web server development, it is perfectly fine for a RESTful server protocol.  See the [tutorial](https://github.com/mirage/ocaml-cohttp#basic-server-tutorial) in the `Cohttp` documentation. 

#### Persistence

* For simple persistence you can just read and write from a file, via the `Stdio` Jane Street library.  Make sure to use a structured file format such as json.
* If you are familiar with databases, the [sqlite3-ocaml](https://github.com/mmottl/sqlite3-ocaml) and [postgresql-ocaml](https://mmottl.github.io/postgresql-ocaml/) bindings should work for accessing SQLite or Postgres databases from within OCaml.

#### Data Processing
* [Owl](https://ocaml.xyz/book/) is a very well-documented numerical processing library.
* [ocaml-torch](https://github.com/LaurentMazare/ocaml-torch) PyTorch bindings for OCaml
* [tensorflow-ocaml](https://github.com/LaurentMazare/tensorflow-ocaml) TensorFlow bindings for OCaml
* [ocaml-bimage](https://github.com/zshipko/ocaml-bimage) is an image processing library.

#### And more!

* There are many OCaml libraries as well as bindings to existing C etc libraries
* The [OCamlverse Ecosystem page](https://ocamlverse.github.io/content/ecosystem.html) lists many libraries available.
   - Note that some libraries in the list are not particularly up-to-date or reliable or well-documented.  They are roughly sorted though so start with the ones at the top of a given list.
* [Awesome OCaml](https://github.com/ocaml-community/awesome-ocaml) is another such list.



### Submissions

* There will be FOUR (revised!) submission points in Gradescope, one ungraded one for initial group and idea, one for the design, one for a code checkpoint and one for the final code.  For each group only one person needs to submit to Gradescope.

#### Initial Group and Idea(s) 
 
 The initial group and idea should include 1) list of names in the group and 2) a sentence or two on a potential idea or two plus 3) potential libraries.  Basically, the result of one initial brainstorming session.

#### Project Design Proposal

The design submission must include
  1. An overview of the purpose of the project
  2. A list of libraries you plan on using
  3. Commented module type declarations (`.mli` files) which will provide you with an initial specification to code to
    - You can obviously change this later and don't need every single detail filled out
    - But, do include an initial pass at key types and functions needed and a brief comment if the meaning of a function is not clear.
  4. Include a mock of a use of your application, along the lines of the Minesweeper example above but showing the complete protocol.
  5. Make sure you have installed and verified any extra libraries will in fact work on your computer setup, by running their tutorial examples.
  6. Also include a brief list of what order you will implement features.
  7. You may also include any other information which will make it easier to understand your project.

#### Code Checkpoint

For the code checkpoint you will need to submit your current codebase
  1. You don't have to have anything finished
  2. But, you should have good progress on library usage and have a some unit tests operational on your own library code.
  3. Your project will need to be buildable with `dune build` at the top level, and testable with `dune test` If you have some non-buildable code at submission time, just comment that out.
  4. We won't require 97% coverage but do at least run a coverage tool and cover a few of the holes.

<a name="demo"></a>
#### Demo and Final Code Submission

For the demo you should be prepared to have a 5-10 minute presentation on your project.
  1. A Powerpoint slide deck intro might be useful depending on your project; it is not required.
  2. Demo the project showing all the functionality.
  3. We may ask questions during this and perhaps ask you to try additional cases
  4. Code review: take us through your code, we will be commenting as we go.  
     - Make sure to describe your use of libraries; if you are using a novel library we may not know, give a brief overview of it.
  5. Build and test: build your project and tests, and then review your test suite.

The final code submission should include 
  1. All of the code of course! (And no binaries - please `dune clean` before zipping)
  2. It should include a `dune` file which successfuly builds your project with `dune build`
  3. It should include a top-level `Readme.md` outlining how to build and run the project.  If any other system-level installs are needed outside of the offical course list, describe them in your `Readme.md`.
  4. In order to be clear on what `opam` packages your project depends on you are required to include information to build a `.opam` file in your project root. This is described below in more detail.
  5. You will also need to include a test suite with good coverage which runs automatically via `dune test` from the top-level directory.


Here are some clarifications.
  1. For test coverage, you should have very good coverage on your core logic.  Make sure to cover the corner cases in the code with tests.
  2. You do not need to cover I/O aspects of the code, those fall under acceptance tests and we are only requiring unit tests at this point.  There is no need to mark all of your I/O code as coverage off.

#### Making and testing an `.opam` package file
 As was mentioned above you will need to make an `.opam` file for your project to package it up for potential distribution.  The main reason for this is both to learn a bit about how opam packages are made, and for us to easily install any `opam` dependencies of your project.  To do so, the easiest way is to copy and paste the below at the end of your `dune-project` file and edit as appropriate.
  ```scheme
  (generate_opam_files true)
  (authors "Yours Truly" "Truly Yours")
  (maintainers "your@email.org")
  (package
   (name hello_world) ; put in your own project name here
   (synopsis "An OCaml library for Helpful Helloing")
   (description "A longer description")
   (depends
    (ounit2 (> 2.0)) ; for each opam dependency list the version
    (core (> 0.14.1)) ; `opam list core` will display which version of core you have
 ))
 ```
 
With these lines, `dune build` will build a file `<your_project>.opam`.  You can then use command `opam install .` to attempt to install your project as a local opam package; this will install any of the `opam` dependencies if they are not already installed.  We will use this command to install all of your `opam` dependencies.  See [dune opam integration](https://dune.readthedocs.io/en/stable/opam.html) for details on this dune file format, and [opam packaging](https://opam.ocaml.org/doc/Packaging.html) for details on the `.opam` file format.

Note that any non-`opam` dependencies you will need to list in your `Readme.md` file.  You can in fact add them to the `.opam` file with `depexts` but it is not trivial to do so we will not require it.

#### Code Submissions
We will put up two submission points in Gradescope for you to upload your zipped hierarchies for the Design and Final submissions.  Please include all the source files needed to build the project but no binary or other built files - run a `dune clean` before zipping!


## The FPSE Labs
<a name="labs"></a>

We will be using a new method for project labs this year.  The goal of the labs is for your group (or you if a singleton) to have plenty of time to get feedback from the course staff on all aspects of your project.

Here are some defining features.

1. There will be five in-class labs.  Your group will be required to attend the first lab in-person on Nov 10th.
2. Attending a lab means showing up and spending the whole period working on your FPSE project, not on homework or other coursework.
3. Attendance will be taken at all labs and will be a part of your final grade. 
4. Your group is required to attend **five** labs total.  Conveniently, there are five class periods which are project labs, but you may alternatively select any CA office hour (the whole hour) to be a "lab".  If you wish to do that, show up in-person at the start of the office hour and notify the CA that you are doing a lab, and they will mark you down for attendance.
5. All labs must be attended in-person, but you may petition for an exception.
6. Attendance is all or none, for a lab to count all group members must be present.
7. You are of course also welcome to show up to either the class or an office hour as a "non-lab", meaning you don't need to work on your project for the whole period and it will not count as one of your five labs.
999. ... We may need to evolve some of the above if something is not working.