## OCaml Coding Information

We are using [OCaml](https://ocaml.org) version 5.3.0.

### Installing OCaml 5.3.0 and associated tools

We require that you use the [opam packaging system](https://opam.ocaml.org) for installing OCaml and its extensions.  Once you get `opam` installed and working, everything else should be easy to install .. so the only hard part is the first step.

-  For Linux or Mac see [The OPAM install page](https://opam.ocaml.org/doc/Install.html) for install instructions. 
-  For Mac users, the above requires [Homebrew](https://brew.sh) (a package manager for Linux-ish libraries) so here is a more detailed suggestion of some copy/paste that should work.
	- Mac without homebrew installed:`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` will install Homebrew.  Follow the instructions of things to copy/paste into your shell to complete the setup.
	- Mac with Homebrew already installed, or if you just installed as per above: run `brew update; brew install gpatch; brew install opam`
-   For Windows you should use WSL2, the Windows Subsystem for Linux.  It creates a Linux-like system from within Windows.
    - Once you install [WSL 2](https://learn.microsoft.com/en-us/windows/wsl/) you will be able to follow the Linux Ubuntu install instructions linked above. 
       - Note that your WSL2 Ubuntu needs the C compiler and tools for the `opam` install to work; the following Linux shell command will get you those: `sudo apt install make m4 gcc zip unzip bubblewrap`.
       - You can still use your Windows install of VSCode to edit files by using the [VSCode Remote WSL Extension](https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-vscode) -- it will connect the Windows editor to the underlying WSL2 subsystem.  See below where VSCode is described for details on how to set this up.
    -  WSL2 has been working well for most people, but another option is to set up a Linux VM on your Windows box, and then set up a Linux install of OCaml within the VM.  There are many good tutorials on how to build a Linux VM, [here is one of them](https://www.lifewire.com/run-ubuntu-within-windows-virtualbox-2202098).  Once your virtual Linux box is set up, you can follow the `opam` Linux install instructions.

### Initial setup of `opam`
You will need to run some terminal commands to set up the basics:
   1.  `opam init` will initialize OPAM (it should give a list of options 1/2/3/4/5, pick 1, `Yes update ~/.bash_profile` or something similar depending on your shell setup);
   2.  If you didn't get that question or said to do nothing, you will need to add line, `eval $(opam env)`, to your `~/.bash_profile` or `~/.profile` or `~/.bashrc` shell init file (add to the first one of these files that exists already) as you would need to do that in every new terminal window otherwise. If you are using `zsh` on macs, add line ``eval `opam env` `` instead to your `~/.zshrc` file.
   3. `opam update` to make sure your `opam` is aware of all the versions of OCaml that are out there;
   4. `opam switch create 5.3.0` will build OCaml version 5.3.0.;
   5.  After a `opam switch` command it might instruct you to reset your path with some instructions like "Run `eval $(opam env --switch=5.3.0)` to update the current shell environment" -- if you get that message, follow those instructions and copy/paste the in the command into the shell (if you are on a Mac you may be using `zsh`; replace the `$(...)` with back-quotes `` `...` ``).

If you already have an earlier version of OCaml installed via `opam`, start on step 3. above to update to 5.3.0.

#### Required OPAM Standard packages

Once you have `opam` and `ocaml` 5.3.0 installed, run the following `opam` command to install additional necessary packages for the class (just copy/paste these two lines into your shell):

```sh
opam install ocaml-lsp-server ocamlformat ocamlformat-rpc utop ounit2 base \
base_quickcheck core async lwt ppx_jane ppx_deriving ppx_deriving_yojson bisect_ppx
```

Lastly, in order for the OCaml top loop to start up with some of these libraries already loaded, create  or edit the file `~/.ocamlinit` to contain the lines below.  The lines in this file are input to the top loop when it first starts.  `topfind` really should be built-in, it allows you to load libraries.  The `require` command is one thing `topfind` adds, here it is loading the `Core` libraries to replace the standard ones coming with OCaml.  We will be using `Core` as they are improved versions.
```ocaml
#use "topfind";;
#require "ppx_jane";; 
#require "core.top";;
open Core;;
```

And here is a shell command which you can simply copy/paste to make the above file:
```sh
(echo '#use "topfind";;'; echo; echo '#require "ppx_jane";;'; echo; \
echo '#require "core.top";;'; echo; echo 'open Core;;') >~/.ocamlinit
```

To test that your install works, type the shell command `utop` which will start up an interactive OCaml session (more later on that).  Type `Fn.id;;` into the `utop` prompt followed by return, this is just a test to make sure the `Core` libraries were properly loaded.  If you didn't get an error message you are all good!  Type control-D to quit `utop`.

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
* Part IV describes the standard libraries but we are *not* using them so please *don't* look here for `List`, `Map`, etc documentation.  Note that if you Google up some OCaml library name you will likely get these libraries which will have subtly wrong documentation for us.  We will primarily use Jane Street's `Core` which replaces these with more modern versions, see the next item.

#### Core
`Core` is a complete rewrite of the standard libraries that come built in to OCaml.  Think of it as a "more modern" version of lists, sets, hash tables, etc, with lots of little improvements in many places.  `Core` itself an extension of `Base` and many modules in `Core` are directly lifted from `Base`.

* [Core documentation](https://ocaml.org/p/core/latest/doc/index.html)
* The [Real World OCaml](https://dev.realworldocaml.org/index.html) book gives tutorial introductions to many of the `Core`/`Base` features.
* **Important note**: if you use a search engine to look up e.g. "OCaml Set" to see how the OCaml Set module is defined you will likely not get the `Core` version and it can be very confusing as it is similar.  Even if you search "OCaml Set Core" you will likely get an outdated version of `Core.Set`.  So, please **bookmark the above use it, and avoid countless hours of fruitless debugging because you are using the wrong library docs**.

### The FPSE OCaml Toolbox

Here are all the tools we will be using.  You are required to have a build for which all these tools work, and the above `opam` one-liner should install them all.

* [`opam`](https://opam.ocaml.org) is the package management system.  See above for install and setup instructions.
* [`ocamlc`](https://ocaml.org/manual/comp.html) is the standalone compiler which we will be invoking via the `dune` build tool.
* [`utop`](https://opam.ocaml.org/blog/about-utop/) is the  read/eval/print loop.  It is a replacement for the original [`ocaml`](https://ocaml.org/manual/toplevel.html) command, with many more features such as command history, replay, etc.
* [`Core`](https://opensource.janestreet.com/core/) was described above
* [`odoc`](https://ocaml.github.io/odoc/odoc/index.html) is the OCaml documentation generator, turning code comments into documentation webpages similar to JavaDoc etc.
* [`dune`](https://dune.build) is the build tool (think `make`) that we will be using.
* [OUnit](https://github.com/gildor478/ounit) is the unit tester for OCaml.  The opam package is called `ounit2` for obscure reasons.
* [`ppx_jane`](https://github.com/janestreet/ppx_jane) adds boilerplate functions to type definitions as well as many other macros.  Unfortunately it is not documented, but `[@@deriving equal, compare, sexp]` for example will add equal and compare on a type, and to/from s-expression convertor functions.

All of the above packages have documentation, but you may also want to try [sherlodocs](https://doc.sherlocode.com/) where you can find documentation on all opam package details in one spot.  For example typing `Core.Array` into the search will give all the documentation for the `Array` module in `Core`.  Another documentation compilation is [The OCaml Documentation Hub](https://docs.ocaml.pro/about.html).

The above tools will be our "bread and butter", we will be using them on many assignments.  There are also a few specialized tools used on some specific assignments.

* [Bisect](https://github.com/aantron/bisect_ppx) will be used for code coverage.
* [base_quickcheck](https://opensource.janestreet.com/base_quickcheck/) is a fuzz tester / automated test generator for OCaml.
* [Lwt](https://ocsigen.org/lwt/latest/api/Lwt) is a non-preempting asychronous threads library.

### Development Environments for OCaml

We recommend VSCode since it has OCaml-specific features such as syntax highlighting, auto-indent, and lint analysis to make the coding process much smoother.

**[Visual Studio Code](https://code.visualstudio.com)**

VSCode has very good OCaml support and is the "officially recommended editor". 

* To make VSCode OCaml-aware you will need to install the **OCaml Platform**.   To install it, from the `View` menu select `Extensions`, and type OCaml in the search box and this extension will show up: select **OCaml Platform** from the list.

* You can easily run a `utop` shell from within VSCode, just open up a shell from the `Terminal` menu and type `utop`.

* If you are on Windows and using WSL2, you need to run Visual Studio "in WSL2 space" to get OCaml syntax highlighting and other nice features. See the [Remote WSL Extension Docs](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-vscode) for details on how to set up the VSCode-WSL2 connection.  If you are having trouble look at the [Additional Resources](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-vscode#additional-resources) on that page.  Once you have the above set up, install the OCaml Platform as described above and you should have syntax highlighting etc working.

**vim**: If you use `vim`, my condolances as it is woefully behind the times in spite of many band-aids added over the years.  Still, if you have been brainwashed to believe it is good, type shell commands `opam install merlin user-setup` and `opam user-setup install` after doing the above default `opam` install to set up syntax highlighting, tab completion, displaying types, etc. See [here](https://github.com/ocaml/merlin/blob/master/vim/merlin/doc/merlin.txt) for some dense documentation.

**emacs**: See vim. You will need to also `opam install tuareg` to get emacs to work, and follow the instructions the install prints out.

### Books

* The [Real World OCaml](https://dev.realworldocaml.org/index.html) book has a fairly good overlap with what we will cover, and can be used as a supplementary resource.
   - It documents many of the extensions we will be using, the `Core` libraries in particular.
* [Cornell cs3110 book](https://cs3110.github.io/textbook/cover.html) is the online text for a somewhat-related course at Cornell.  They have recently added many videos if you like watching videos to learn.  Note that they are not using `Core`.
* [OCaml from the very beginning](https://johnwhitington.net/ocamlfromtheverybeginning/) is a free online book.

### Coding Style

* The [FPSE Style Guide](http://pl.cs.jhu.edu/fpse/style-guide.html) is the standard we will adhere to in the class; it follows general best practices for modern OCaml.  It will be expected of your code from Assignment 2 on.

### Example Worked Exercises
One of the best ways to learn to write elegant OCaml is to study well-written OCaml code.

* [Exercism OCaml Track](https://exercism.io/tracks/ocaml/exercises) has a large set of programming problems to solve which have solutions by many other programmers as well.  We will reference some of these examples in lecture.
* [99 problems](https://ocaml.org/problems) solves 99 basic OCaml tasks.
* [Learn OCaml](https://ocaml-sf.org/learn-ocaml-public/#activity%3Dexercises) has a large number of exercises to solve.  The [solutions are online](https://github.com/ocaml-sf/learn-ocaml-corpus/tree/master/exercises).
