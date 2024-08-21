The FPSE Projects
-----------------

For the projects you are to conceive, design, and implement your own standalone application in OCaml. This represents the culmination of what you have learned in the course. You will submit an initial idea, a design proposal, a code checkpoint, and a final code submission. At the time of the final submission, you will give a short demo to the course staff.

### Requirements
Here are the high-level requirements for the projects.

* All the code must be in OCaml (excepting small bits of glue code, or explicit exceptions if you petition).
* You must use the standard course libraries -- `Core`, `Lwt`, `OUnit2` etc -- as your basis, plus any other libraries you find useful.
* Project groups can be from 2-4 people.
* OCaml excels for non-trivial algorithms, and you will be **required** to make a non-trivial algorithm(s) a key feature of your app.  If you are just doing some simple webpage front-end with a database back-end (shopping cart, To Do list, etc) OCaml can work but doesn't have any real advantage.  Non-trivial algorithms can either be that the algorithm itself is complex, or that things need to be composed/combined in ways that higher-order functions can really help.
* You need to make a general library as part of your project, to get more experience with modules and functors in OCaml. You can/should do this by making an abstraction of something more concrete or specific to your project such that it is more widely usable as a library.
* A very rough idea of the scope of the project is around 1000-2000 lines of code per person.  This will depend a lot on the particular application; we will not be making line count an explicit part of your grade.

### Project Topic Thrusts

You will need to make a standalone application as in assignments 4 and 6. Here are are three high-level approaches to perhaps get the juices flowing.  Also see the bottom of this page for some past projects.

1. A command-line app with persistence.
    * The focus is on complex user interaction through the command line.
2. A web interface app.
    * The focus is on interaction through a UI.
3. A complex library.
    * The focus is on some sophisticated algorithm, and there may be a simple usage through the command line.

Note that in all three, **there must be a non-trivial algorithm as a key feature**. For example, in the projects linked below, we have sudoku solvers, chess AI, complex-number mathematics with a rasterizer and ASCII image generator, etc. The complexity of the user interaction makes up for lack of complexity in the algorithm and underlying behavior and vice versa.

For all command-line apps, here are some ways to beef them up once the basic app is working:

  1. Replace the command line with a RESTful web server using [`Dream`](https://aantron.github.io/dream) mentioned below.
  2. In addition to 1., `Dream` supports html templates and you could "reply" to the `http` queries with html and so you can run your app in the browser.
  3. Use Rescript and React to beef it up and make an OCaml front-end in the browser. You may not use JavaScript unless you petition to the course staff.
  4. Replace a file-based persistence model with a database; see the list of libraries below for Postgres and MySql bindings for OCaml.
  5. Rather than using your own ad-hoc format for data in the file or database, make an s-expression representation and convert back and forth.  
    - You should do this from the beginning in fact, it will be easier and more robust.
  6. Add more options to the underlying application.  Think about ways to make the application more generic, which also can give you some practice at abstractions in OCaml.


### Libraries Catalog
Here is a list of well-maintained libraries we recommend using for the above approaches, as well as some resources where you can find other libraries.

#### Web-based

* All web-based applications may have delayed response or may fail, and so all of the web libraries below are built on an OCaml coroutine library, either `Lwt` or `Async`.  `Async` is the Core version, but it is not gaining a lot of traction so you will probably be better off with a library over `Lwt`.  
  - See the [coroutines lecture notes](../coroutines.html) for more information on using `Lwt`.
* We recommend the simple [`Cohttp_lwt_unix`](https://github.com/mirage/ocaml-cohttp) for web client (API reading / crawling) applications.
* We recommend [`Dream`](https://aantron.github.io/dream) for web applications.  (Note on Macs with homebrew you will need to  `brew install node`, `brew install openssl` and `brew install libev` along with the other install instructions. on Linux or WSL2 you will probably need to use `apt` to install similar libraries if you don't have them already.)  It supports full web applications.  If you just want to make a simple RESTful server, `Cohttp` (below) is also a good choice.
* [`Opium`](https://github.com/rgrinberg/opium) is a good alternative to `Dream` to consider as well.  Both are built on `Lwt`.
* `Cohttp` also supports lightweight web server development, it is perfectly fine for a RESTful server protocol.  See the [tutorial](https://github.com/mirage/ocaml-cohttp#basic-server-tutorial) in the `Cohttp` documentation. 
* For the client, it is possible to code your client in "OCaml" using [ReScript](https://rescript-lang.org) which is OCaml but with a  different looking syntax that compiles to JavaScript and which has bindings for React.  ReScript front-ends will count toward your "OCaml code" whereas JavaScript front-ends will not.

#### Persistence

* For simple persistence you can just read and write from a file with the `Stdio` Jane Street library.  Make sure to use a structured file format such as json or sexp.
* If you are familiar with databases, the [sqlite3-ocaml](https://github.com/mmottl/sqlite3-ocaml) and [postgresql-ocaml](https://mmottl.github.io/postgresql-ocaml/) bindings should work for accessing SQLite or Postgres databases from within OCaml.

#### Data Processing
There are some good libraries here but they don't have many users and we have had **many issues with people being able to install these libraries in the past**.  If you wanted to base your project around one of these libraries **you will be required to** (1) get the library successfully installed on all your team members' computers; (2) get a basic demo app running using the library, both at the design proposal submission deadline below. 
* [Owl](https://ocaml.xyz/) is a very well-documented numerical processing library.
* [ocaml-torch](https://github.com/janestreet/torch) PyTorch bindings for OCaml.   (Note that the OCaml TensorFlow bindings are old and don't seem to work.)
* [ocaml-bimage](https://github.com/zshipko/ocaml-bimage) is an image processing library.

#### And more!

* There are many OCaml libraries as well as bindings to existing C etc libraries
* The [OCamlverse Ecosystem page](https://ocamlverse.github.io/content/ecosystem.html) lists many libraries available.
   - Note that some libraries in the list are not particularly up-to-date or reliable or well-documented.  They are roughly sorted though so start with the ones at the top of a given list.
* [Awesome OCaml](https://github.com/ocaml-community/awesome-ocaml) is another such list.


### Submissions

* There will be **four** submission points in Gradescope, one ungraded for initial group and idea, one for the design, one for a code checkpoint, and one for the final code.  For each group only one person should submit to Gradescope, as a group submission.

#### Initial Group and Idea(s) 
 
The initial group and idea should include 1) list of names in the group and 2) a sentence or two on a potential idea or two plus 3) potential libraries.  Basically, the result of one initial brainstorming session.  This can just be a pdf or markdown file.

E.g.

>Group members: Earl Wu, Shiwei Weng, Brandon Stride
>
>We are going to make a Rubik's Cube solver for the 4x4x4 Rubik's Cube where the user inputs their cube through a web frontend, and they get back a sequence of moves to solve the cube.
>
>To get the Web frontend to work, we need Dream and Lwt, and for the OCaml backend, we will only use Core because the Rubik's Cube library will be from scratch. We might use OCamlGraph in case we choose some graph search method to solve parts of the cube.

This submission will count for very little; its purpose is just to get your group off the ground, and to give us some direction in who to assign as your group advisor.

After this submission, you will have lab days to have designated time to work together and discuss with your advisor.


#### Project Design Proposal

For this submission and all subsequent submissions, you are required to submit to Gradescope via a GitHub repo. If you have large datasets in files, please put them on Google Drive or similar and provide a link - Gradescope and/or Github may be unhappy otherwise.

You will have created a project on GitHub, and the content of this submission is found top-level in `Design.md` with module type declarations in `src/`.

The design submission must include
  1. An overview of the purpose of the project.
  2. A complete mock use of the application.
    - If you have a graphical user interface, show a mock up of every page and how the user can interact.
    - ... similarly if you have a command line interface.
    - If the basis of your project is just some hard algorithm, take this chance to describe the algorithm and how OCaml will work with it. Show example uses and discuss desired performance.
  3. A list of libraries you are using or plan to use in your implementation. For all non-standard libraries used in the rest of the course (e.g. if you are using `Dream`), you need to have successfully installed the library on all team member computers and have a small demo working to verify the library really works. We require this because OCaml libraries can be flaky. This will be submitted in `demo/` with a subdirectory for each library.
  4. Commented module type declarations (`.mli` files) which will provide you with an initial specification to code to.
    - You can change this later and don't need every single detail filled out, but it should include as many details as you can think of, and you should try to cover the entire project.
    - Include an initial pass at key types and functions needed and a brief comment if the meaning of a function is not clear.
  5. An implementation plan: a list of the order in which you will implement features and by what date you hope to have them completed.
  6. You may also include any other information that will make it easier to understand your project.

*Grading rubric*

* 30% mock use: depicts each usage case clearly and accurately.
* 15% libraries: has a working demo folder for each library to be used in the final submission.
* 15% project scope: the project is not too big or too small, has enough algorithmic complexity, and has room to make a general library.
* 10% plan of implementation: there is a detailed implementation plan that covers all aspects of the project.
* 30% module declarations: there are reasonable module interfaces for core components that are well thought-through and well designed.

#### Code Checkpoint

On the last day of class you will submit your current codebase as a code checkpoint.

1. You should have made significant progress on your project.
2. Your code should be tested.
3. Run a coverage tool to demonstrate test coverage.
4. Your project must be buildable with `dune build` at the top level and testable with `dune test`. Comment out any code that doesn't build before your submission.
5. You should have a `Readme.md` that explains your progress so far: what is working, what is not, etc.

The code checkpoint is an important opportunity to get feedback from your advisor and correct issues before your final submission. Having a significant amount of code done for this checkpoint has always proven extremely helpful for groups in years past.

Make sure it is clear where your library code is. Consider some specific requirement of the final product, and then abstract it: use functors, parametrized types, all of that.

You should have a well-structured GitHub repository for all of your code that contains no binaries, and you submit to Gradescope with this repository. You should have a `.gitignore` so that you're not submitting binaries or `_opam/` files, or anything else buildable from the source code.

*Grading rubric*

* 30% progress: has made sufficient progress towards the end goal; seems close to 1/2 of the way through the project.
* 3% evidence of a library: there is an abstraction of features into a library, and it's clear what the library will be by the final submission.
* 3% has enough algorithmic complexity: at this rate, the complexity of the project is high and will seem to meet the standard for the final submission.
* 24% module design and structure: module design is well-structured, is thought through, considers advisor's comments from the proposal, and won't need significant change heading forward.
* 25% code quality: the code that implements the module design is high quality with good types, functional data structures, lots of modules, etc.
* 15% tests: there are tests covering a significant portion of the functionality that is implemented so far.

<a name="demo"></a>
#### Demo and Final Code Submission

For the demo you should prepare a 5-10 minute presentation on your project.
  1. A Powerpoint slide deck intro might be useful depending on your project; it is not required.
  2. You will demonstrate the project, showing all the functionality.
  3. We will ask you questions during this and perhaps ask you to try additional cases.
  4. Code review: take us through your code, we will be commenting as we go.  
     - Make sure to describe your use of libraries; if you are using a novel library we may not know, give a brief overview of it.
  5. Build and test: build your project and tests, and then review your test suite. Show us the coverage report.

The final submission should include 
  1. Everything in your repository, of course!
  2. A `dune` file that successfully builds your project with `dune build` and tests it with `dune test`.
  3. A top-level `Readme.md` that describes the project and tells users how to build and run it. The `Readme` also explains how to handle any other system-level installs that are needed outside of the official course list.
  4. A `.opam` file in your project root: in order to be clear on what `opam` packages your project depends on, you are required to include information to build a `.opam` file. This is described below in more detail.

We should be able to run and reproduce everything from the demo just using what is submitted to Gradescope.

A few comments on testing:
  1. For test coverage, you should have very good coverage on your core logic.  Make sure to cover the corner cases in the code with tests.
  2. Run a coverage report, but don't worry about turning off lines with `[@@@ coverage off]` because we won't grade for a specific coverage percentage.

*Grading rubric*

* 5% quality of demo presentation: project is described well, and the presentation is clear.
* 20% demonstration of functionality: during the demo, there is lack of errors/glitches, the UI is quality, the edge cases we ask you to try work well, etc.
* 25% code quality: good FP practice, following style guidelines, proper dune and opam files, good module design, etc.
* 15% tests: good coverage of code, runs with `dune test`.
* 20% accomplishment: library usage, conceptual challenge, degree of completion, general remarks.
* 8% library: the project is written with abstraction and a general library.
* 7% algorithmic complexity: there are significantly challenging underlying algorithms in the project.

#### Making and testing an `.opam` package file
 As was mentioned above you will need to make an `.opam` file for your project to package it up for potential distribution.  The main reason for this is both to learn a bit about how opam packages are made, and for us to easily install any `opam` dependencies of your project.  To do so, the easiest way is to copy and paste the below at the end of your `dune-project` file and edit as appropriate.  Make sure to include any `opam` packages you are using in the `depends` section.
  ```scheme
  (lang dune 3.16)
  (generate_opam_files true)
  (authors "Yours Truly" "Truly Yours")
  (maintainers "your@email.org")
  (package
   (name hello_world) ; put in your own project name here
   (allow_empty)
   (synopsis "An OCaml library for Helpful Helloing")
   (description "A longer description")
   (depends
    (ounit2 (>= 2.2.7)) ; for each opam dependency list the version
    (core (>= 0.17.1)) ; `opam list core` will display which version of core you have
 ))
 ```
 
With these lines, `dune build` will build a file `<your_project>.opam`.  You can then use command `opam install . --deps-only --working-dir` to install any of the `opam` dependencies if they are not already installed.  We will use this command to install all of your `opam` dependencies.  See [dune opam integration](https://dune.readthedocs.io/en/stable/explanation/opam-integration.html) for details on this dune file format, and [opam packaging](https://opam.ocaml.org/doc/Packaging.html) for details on the `.opam` file format.

Note that any non-`opam` dependencies you will need to list in your `Readme.md` file. You can also add them to the `.opam` file with `depexts`, but it is not trivial to do, so we will not require it.


## The FPSE Project Labs
<a name="labs"></a>

The project labs are classes later in the semester where your group can collaborate on project work.  The goal of the labs is to get work done on your project, and for your group to have plenty of time to get feedback from the course staff on all aspects of your project. Your advisor will check in with you and give you feedback and advice during the lab. Make use of your advisor and benefit from their expertise!

Here are some defining features of the labs.

1. There will be seven labs.  Your group will be required to attend the first lab in-person on Nov 6th.
2. Attending a lab means showing up and spending the whole period working on your FPSE project, not on homework or other coursework. You won't get credit for a lab if you show up and choose to work on anything other than your FPSE project.
3. Attendance will be taken at all labs and will be a part of your final grade. 
4. Your group is required to attend **seven** labs total.  Conveniently, there are seven class periods which are project labs, but you may alternatively select a CA office hour (the whole hour and it should be your group advisor if at all possible) to be a "lab".  If you wish to do that, show up in-person at the start of the office hour and notify the CA that you are doing a lab, and they will mark you down for attendance.  At most two in-class labs can made up in this way.
5. All labs must be attended in-person, but you may petition for an exception.
6. **Attendance is all or none** -- for a lab to count all group members must be present.  Group work is group work.

## Sample projects

Here are a few FPSE projects from last year (2023) to give you an idea of the scope etc. Please pick a different idea.

* [Sudoku solver](https://github.com/TheHarcker/FPSE_Project)

* [Boggle game](https://github.com/edlwang/FPSE-Boggle)

* [Moebius transformation in ASCII](https://github.com/cli135/mobius-transformation)

* [Chess AI](https://github.com/jchen362/finalfpse)

* [Go](https://github.com/avnukala/ocaml_go)