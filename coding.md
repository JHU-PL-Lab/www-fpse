## OCaml Coding Information

We are using [OCaml](https://ocaml.org) version 4.12.0.

### Installing OCaml 4.12.0 and associated tools

We require that you use the [opam packaging system](https://opam.ocaml.org) for installing OCaml and its extensions.  Once you get `opam` installed and working, everything else should be easy to install .. so the only hard part is the first step.

-   For Linux or Mac see [The OPAM install page](https://opam.ocaml.org/doc/Install.html) for install instructions. 
-  For Mac users, the above requires [Homebrew](https://brew.sh) (a package manager for Linux-ish libraries) so here is a more detailed suggestion of some copy/paste that should work.
	- Mac without homebrew installed:`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` will install Homebrew 
	- Mac with Homebrew (make sure you first do a `brew update` before this): `brew install gpatch; brew install opam`
- You will then need to run some terminal commands to set up the basics:
    1.  `opam init` to initialize OPAM;
    2.  `opam switch create 4.12.0` (this will take awhile) to build OCaml version 4.12.0 (the initial install is usually a slightly outdated version; also, if you already had an OPAM install you need to `opam update` before this `switch` to make sure OPAM is aware of the latest version);
	3.  `eval (opam env)` to let your shell know where the OPAM files are (use ``eval `opam env` `` instead if you are using `zsh` on a Mac); and
    4.  Also add the very same line, `eval (opam env)`, to your`.profile`/`.bashrc` shell init file as you would need to do that in every new terminal window otherwise. (for `.zshrc` on macs, add line ``eval `opam env` `` instead)
    

-   Windows Windows Windows.. the OCaml toolchain is unfortunately not good in straight Windows.
    -   If you are running a recent Windows install, we recommend installing [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/) which once you have set up will allow you to follow the Linux Ubuntu install instructions to get `opam`. 
       - Note that your Ubuntu needs the C compiler and tools for the `opam` install to work; the following Linux shell command will get you those: `sudo apt install make m4 gcc unzip`.
       - [More WSL2 for OCaml tips here](https://www.cs.princeton.edu/courses/archive/fall20/cos326/WindowsSemiNative.php).  
    -   Option 2 is to set up a Linux VM on your Windows box, and then set up a Linux install of OCaml within the VM.  There are many good tutorials on how to build a Linux VM, [here is one of them](https://www.lifewire.com/run-ubuntu-within-windows-virtualbox-2202098).  Once your virtual Linux box is set up, you can follow the `opam` Linux install instructions.


#### Required OPAM Standard packages

Once you have `opam` and `ocaml` 4.12.0 installed, run the following `opam` command to install additional necessary packages for the class:

    opam install merlin utop ppx_deriving core bisect_ppx ounit2 async ppx_deriving_yojson


Lastly, in order for the OCaml top loop to start up with some of these libraries already loaded, edit the file `~/.ocamlinit` to add the lines below (note `opam` probably already created this file, just make sure the lines below are in it).  The lines in this file are input to the top loop when it first starts.  `topfind` really should be built-in, it allows you to load libraries.  The `require` command is one thing `topfind` adds, here it is loading the `Core` libraries to replace the standard ones coming with OCaml.  We will be using `Core` as they are improved versions.
```ocaml
#use "topfind";;
#thread;;
#require "core.top";;
open Core;;
```

### OCaml Documentation
[ocaml.org](https://ocaml.org) is the central repository of OCaml information.
#### The OCaml Manual

The OCaml manual is [here](https://ocaml.org/manual/).
* We will cover most of the topics in Part I Chapters 1 and 2 from the manual.
* Manual Chapter 7 is the language reference where you can look up details if needed. 
* We will be covering a few topics in the [language extensions](https://ocaml.org/manual/extn.html) chapter:
  * [locally abstract types](https://ocaml.org/manual/locallyabstract.html),
  * [First-class modules](https://ocaml.org/manual/firstclassmodules.html), and
  * [GADT's](https://ocaml.org/manual/gadts.html).
* Part III of the manual documents the tools, we will not be using much of this because third parties have improved on many of the tools and we will instead use those improved versions.  See below in the Tools list where we give "our" list of tools.
* Part IV describes the standard libraries; as with the tools we will primarily use Jane Street's `Base`/`Core` which replaces these with more modern versions so we will generally be ignoring this Part. 

#### Base and Core
`Core` is a complete rewrite of the standard libraries that come built in to OCaml.  Think of it as a "more modern" version of lists, sets, hash tables, etc, with lots of little improvements in many places.  `Core` is an extension of `Base` which is in fact what we will mainly be using.

* [Core documentation](https://ocaml.janestreet.com/ocaml-core/latest/doc/core/Core/index.html) is not particularly readable as `Core` extends [`Core_kernel`](https://ocaml.janestreet.com/ocaml-core/latest/doc/core_kernel/Core_kernel/index.html) which in turn extends `Base` and most times you probably just want the `Base` version so I would suggest starting there.
* [Base Documentation](https://ocaml.janestreet.com/ocaml-core/latest/doc/base/Base/index.html) - start here for most common data structures.
* [Core_kernel Documentation](https://ocaml.janestreet.com/ocaml-core/latest/doc/core_kernel/Core_kernel/index.html) - occasionally you may need some of the extensions on `Base` here, but not very often.
* The [Real World OCaml](https://dev.realworldocaml.org/index.html) book gives tutorial introductions to many of the `Core`/`Base` features.
* Important note: if you use a search engine to look up e.g. "OCaml Set" to see how the OCaml Set module is defined you will likely not get the `Core` version and it can be very confusing.  Even if you add `Base` or `Core` as keywords to the search you will usually get an outdated version.  So, bookmark the above!

### The FPSE OCaml Toolbox

Here are all the tools we will be using.  You are required to have a build for which all these tools work, and the above `opam` one-liner should install them all.

* [`opam`](https://opam.ocaml.org) is the package management system.  See above for install and setup instructions.
* [`ocamlc`](https://ocaml.org/manual/comp.html) is the standalone compiler which we will be invoking via the `dune` build tool.
* [`utop`](https://opam.ocaml.org/blog/about-utop/) is the read/eval/print loop.  It is a replacement for the original [`ocaml`](https://ocaml.org/manual/toplevel.html) command, with many more features such as command history, replay, etc.
* [`Base`/`Core`](https://opensource.janestreet.com/core/) was described above
* [`ocamldoc`](https://ocaml.org/manual/ocamldoc.html) is the documentation generator, turning code comments into documentation webpages similar to JavaDoc etc.
* [`dune`](https://dune.build) is the build tool (think `make`) that we will be using.
* [OUnit](https://github.com/gildor478/ounit) is the unit tester for OCaml.  The opam package is called `ounit2` for obscure reasons.
* [`ppx_jane`](https://github.com/janestreet/ppx_jane) adds boilerplate functions to type definitions as well as many other macros.  Unfortunately it is not documented, but `[@@deriving equal, compare, sexp]` for example will add equal and compare on a type, and to/from s-expression convertor functions.

The above tools will be our "bread and butter", we will be using them on many assignments.  There are also a few specialized tools used on some specific assignments.

* [Bisect](https://github.com/aantron/bisect_ppx) will be used for code coverage.
* [base_quickcheck](https://opensource.janestreet.com/base_quickcheck/) is a fuzz tester / automated test generator for OCaml.
* [Async](https://opensource.janestreet.com/async/) is a non-preempting asychronous threads library.
* [Domains and Effects](https://github.com/ocaml-multicore/domainslib) are another approach to coroutines and asynchronous programming
* [Multicore OCaml](https://github.com/ocaml-multicore/ocaml-multicore) will be used for parallel programming.

### Development Environments for OCaml

We recommend VSCode since it has OCaml-specific features such as syntax highlighting, auto-indent, and lint analysis to make the coding process much smoother.

**[Visual Studio Code](https://code.visualstudio.com)**: 
VSCode has very good OCaml support and is the "officially recommended editor". Install the **OCaml and Reason IDE** extension to get syntax highlighting, type information, etc: from the `View` menu select `Extensions`, then type in OCaml and this extension will show up; install it. You can also easily run a `utop` shell from within VSCode, just open up a shell from the `Terminal` menu and type `utop`.

If you are on Windows and using WSL2, to run Visual Studio "in WSL2 space" so you get OCaml syntax highlighting and other nice features see [this blog post](https://code.visualstudio.com/blogs/2019/09/03/wsl2) for how you can set it up.

[**Atom**](https://atom.io): 
Atom is unfortunately being slowly phased out after Microsoft bought Github.  So, it is probably a good time to switch from Atom to VSCode if you have not already.  To use Atom with OCaml install the `atom` and `apm` shell commands (see the **Atom..Install Shell Commands** menu option on Macs, or type shift-command-p(⇧⌘P) and then in the box type command `Window: Install Shell Commands`). With those commands installed, type into a terminal

        apm install language-ocaml linter ocaml-indent ocaml-merlin

to install the relevant OCaml packages. Here are some handy Atom keymaps for common operations these extensions support -- add this to your `.atom/keymap.cson` file:

        'atom-text-editor[data-grammar="source ocaml"]':
          'ctrl-shift-t': 'ocaml-merlin:show-type'
          'alt-shift-r': 'ocaml-merlin:rename-variable'
          'ctrl-shift-l': 'linter:lint'
          'ctrl-alt-f': 'ocaml-indent:file'

`linter:lint` will refresh the lint data based on the latest compiled version of your code. In addition, control-space should auto-complete.

**vim**: If you use `vim`, my condolances as it is woefully behind the times in spite of many band-aids added over the years.  Still, if you have been brainwashed to believe it is good, type shell commands `opam install user-setup` and `opam user-setup install` after doing the above  default `opam` install to set up syntax highlighting, tab completion, displaying types, etc. See [here](https://github.com/ocaml/merlin/blob/master/vim/merlin/doc/merlin.txt) for some dense documentation.

**emacs**: See vim.  Confession: I still use emacs a bit but am trying to wean myself.  35-year-old habits die hard.  Note you will need to also `opam install tuareg` to get emacs to work, and follow the instructions the install prints out.

### Books

* The [Real World OCaml](https://dev.realworldocaml.org/index.html) book has a fairly good overlap with what we will cover, and can be used as a supplementary resource.
   - It documents many of the extensions we will be using, `Base`/`Core` libraries in particular
* [Cornell cs3110 book](https://www.cs.cornell.edu/courses/cs3110/2020sp/textbook/) is the online text for a somewhat-related course at Cornell.

### Coding Style

* The [FPSE Style Guide](http://pl.cs.jhu.edu/fpse/style-guide.html) is the standard we will adhere to in the class; it follows general best practices for modern OCaml.  It will be expected of your code from Assignment 2 on.

### Example Worked Exercises
One of the best ways to learn to write elegant OCaml is to study well-written OCaml code.

* [Exercism OCaml Track](https://exercism.io/tracks/ocaml/exercises) has a large set of programming problems to solve which have solutions by many other programmers as well.  We will reference some of these examples in lecture.
* [99 problems](https://ocaml.org/learn/tutorials/99problems.html) solves 99 basic OCaml tasks.
* [Learn OCaml](https://ocaml-sf.org/learn-ocaml-public/#activity%3Dexercises) has a large number of exercises to solve.  The [solutions are online](https://github.com/ocaml-sf/learn-ocaml-corpus/tree/master/exercises).
