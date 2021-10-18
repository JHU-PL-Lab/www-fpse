The FPSE Projects
---------------------

For the projects you are to conceive, design, and implement your own standalone application in OCaml.  This represents the culmination of what you have learned in the course.  
### Requirements
Here are some high-level requirements for the projects.

* All the code must be in OCaml obviously (excepting small bits of glue code)
* Use the standard course libraries -- `Core`, `Async`, `Yojson` etc -- as your basis, plus any other libraries you find useful.
* Project groups can be from 1-3 people, any of these three options is good.
* A very rough idea of the scope of the project is around 500-1000 lines of code per person.
* There will be two official check-ins: there will be a lab before Thanksgiving with a submission shortly after, and there will be a final demo and code submission on Dec 1Xth (insert our final exam day here -- 19th?).


### Potential Project Topic Thrusts

* You will need to make a standalone application as you did in assignments 2 and 4.
* Here are are three approaches to give some potential directions; feel free to do whatever you like though.

#### 1. A command-line app with persistence
* The idea here is to make some application where all the interaction is via the command line.
* Persistent data across command invocations could be saved in a file using the `Stdio` library.
* This path is the most straightforward of the three choices.
* Here are some simplistic examples, you would need more than these

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
  1. Replace the command line with a web server interface a la `Cohttp_async` mentioned below which could be invoked on the command line by `curl`
  ```sh
  $ curl http://localhost/mine/move?1,1
  ```
  2. In addition to 2., write a JavaScript front-end to put a UI on your app.  Obviously you would need to be familiar with JavaScript web programming already if you chose this.
  3. Replace the file-based persistence model with a database; see the list of libraries below for Postgres and MySql bindings for OCaml.
  4. Rather than using your own ad-hoc format for data in the file or database, make your own JSON representation and use `yojson` to convert back and forth.  
    - You should do this from the beginning in fact, it will be easier and more robust.

#### 2. Async and web related
The combination of the `Async` and `Cohttp_async` libraries allow for both web server and web client applications.  See below for links to the libraries.

Here are some concrete project ideas.
* Some of the extensions suggested above involved writing a web server interface for your app, you could instead make that your only focus and skip the command-line version
* Another approach is to write a command line app which would access, process, and present data from an existing RESTFul API collator/processor 
   - see e.g. [Rapid API](https://rapidapi.com) for a large list of APIs available
   - Some free APIs there include data for shopping, weather, recipes, COVID, etc etc 
   - One concrete idea could be to grab both historical weather and COVID data for a location using two different RESTful APIs and compute the correlation between temperature and new COVID cases five days later
   - etc etc etc.
* You could write a web crawler app
    - starting from a URL grab it and all contained URL (up to some breadth and depth limit)
    - Then, compute some aspects on the pages, e.g. count how many lines of code, etc

#### 3. Scientific / Machine Learning

This approach is for those with some background in this area.

* A simple machine learning app using PyTorch or TensorFlow and possibly graphing it in Owl; see below for links to the OCaml libraries
* Here is a [Jane Street Article](https://blog.janestreet.com/deep-learning-experiments-in-ocaml/) on use of TensorFlow within OCaml.


### Libraries Catalog
Here is a list of well-maintained libraries we recommend using for the above approaches, as well as some lists you can find other libraries on.

#### Web-based

* Since web-based applications may have delayed response or may fail, you should use the `Async` library for any web client or server app.
  - See the [async lecture notes](../lazy-async.html#async) and [Real World OCaml Chapter 15](https://dev.realworldocaml.org/concurrent-programming.html) for more information on using `Async`.
* We recommend the simple [`Cohttp_async`](https://github.com/mirage/ocaml-cohttp) for both web client (API reading / crawling) and server applications.
* See [Real World OCaml Chapter 15](https://dev.realworldocaml.org/concurrent-programming.html#scrollNav-3) for an example of how to perform http requests with `Cohttp_async`.
* `Cohttp` also supports lightweight web server development.  See the [tutorial](https://github.com/mirage/ocaml-cohttp#basic-server-tutorial) in the `Cohttp` documentation.  (This tutorial uses the `lwt` bindings; see the [Cohttp async examples](https://github.com/mirage/ocaml-cohttp/tree/master/examples/async) for `async` versions)
* Write a browser app in OCaml, and compile it to JavaScript to run in the browser via [`js_of_ocaml`](https://ocsigen.org/js_of_ocaml/3.7.0/manual/overview).

#### Persistence

* For simple persistence you can just read and write from a file, via the `Stdio` Jane Street library.
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

* There will be two submission points in Gradescope, one for the initial design and one for the final code
* The initial design submission must include
  1. An overview of the purpose of the project
  2. A list of libraries you plan on using
  3. Commented module type declarations which will provide you with an initial specification to code to
    - You can obviously change this later and don't need every single detail filled out
    - But, do include an initial pass at key types and functions needed and a brief comment if the meaning of a function is not clear.
  4. Include a mock of a use of your application, along the lines of the Minesweeper example above but showing the complete protocol.
  5. Make sure you have installed and verified any extra libraries will in fact work on your computer setup, by running their tutorial examples.
  6. Also include a brief list of what order you will implement features.
  7. You may also include any other information which will make it easier to understand your project.
* For the demo you should be prepared to 
  1. Demo the project showing all the functionality
  2. We may ask questions during this and perhaps ask you to try additional cases
  3. Code review: take us through your code, we will be commenting as we go.  
     - Make sure to describe your use of libraries; if you are using a novel library we may not know, give a brief overview of it.
  4. Build and test: build your project and tests, and then review your test suite.

* The final submission will in addition include 
  0. All of the code of course!
  1. It should include a dune file which successfuly builds your project
  2. It should include a `Readme.md` at the top outlining how to build and run the project.  If any other `opam` installs are needed outside of the offical course list, describe them in your `Readme.md`.
  3. You will also need to include a test suite with good coverage.
* We will put up two submission points in Gradescope for you to upload your zipped hierarchies for the Design and Final submissions.  Please include all the source files needed to build the project but no binary or built files.
* If you are working with a team-mate, make sure the submission is marked as such.  Only one person on the team needs to upload the submission.
