## OCaml Coding Information

We are using [OCaml](https://ocaml.org) version 4.10.0.

### Installing OCaml 4.10.0 and associated tools

We require that you use the [OPAM packaging system](https://opam.ocaml.org) for installing OCaml and its extensions.  Once you get `opam` installed and working, everything else should be easy to install .. so the only hard part is the first step.

-   For Linux or Mac see [The OPAM install page](https://opam.ocaml.org/doc/Install.html) for install instructions. 
-  For Mac users, the above requires Homebrew (a package manager for Linux-ish libraries) so here is a more detailed suggestion of some copy/paste that should work.
	- Mac without homebrew installed:`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"` will install Homebrew 
	- Mac with Homebrew (make sure you first do a `brew update` before this): `brew install gpatch; brew install opam`
- You will then need to run some terminal commands to set up the basics:
    1.  `opam init` to initialize OPAM;
    2.  `opam switch create 4.10.0` (this will take awhile) to build OCaml version 4.10.0 (the initial install is usually a slightly outdated version; also, if you already had an OPAM install you need to `opam update` before this `switch` to make sure OPAM is aware of the latest version);
	3.  `eval (opam env)` to let your shell know where the OPAM files are; and
    4.  Also add the very same line, `eval (opam env)`, to your`.profile`/`.bashrc` shell init file as you would need to do that in every new terminal window otherwise. (for `.zshrc` on macs, use ``eval `opam env` ``instead )
    

-   Windows Windows Windows.. the OCaml toolchain is unfortunately not good in straight Windows.
    -   If you are running a recent Windows install, we recommend installing [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/) which once you have set up will allow you to follow the Linux Ubuntu install instructions to get `opam`. 
    -   Option 2 is to set up a Linux VM on your Windows box, and then set up a Linux install of OCaml within the VM.  There are many good tutorials on how to build a Linux VM, [here is one of them](https://www.lifewire.com/run-ubuntu-within-windows-virtualbox-2202098).  Once your virtual Linux box is set up, you can follow the `opam` Linux install instructions.


#### Required OPAM Standard packages

Once you have `opam` and `ocaml` 4.10.0 installed, run the following `opam` command to install additional necessary packages for the class:

    opam install merlin ocp-indent user-setup menhir utop ppx_deriving core bisect_ppx ounit2 qcheck async ppx_deriving_yojson

And there is currently a glitch with a library so if the above fails with an error about `ppx_string`, run the command

    opam pin add ppx_string --dev

and then try the previous command again.


Lastly, in order for the OCaml top loop to start up with some of these libraries already loaded, edit the file `~/.ocamlinit` to add the lines below (note `opam` probably already created this file, just make sure the lines below are in it).  The lines in this file are input to the top loop when it first starts.  `topfind` really should be built-in, it allows you to load libraries.  The `require` command is one thing `topfind` adds, here it is loading the `Core` libraries to replace the standard ones coming with OCaml.  We will be using `Core` as they are improved versions.
```ocaml
#use "topfind";;
#thread;;
#require "core.top";;
open Core;;
```

### OCaml Documentation

#### The OCaml Manual

The OCaml manual is [here](http://caml.inria.fr/pub/docs/manual-ocaml/).
* We will cover most of the topics in Part I Chapters 1 and 2 from the manual.
* Manual Chapter 7 is the language reference where you can look up details if needed. 
* We will be covering a few topics in the [language extensions](http://caml.inria.fr/pub/docs/manual-ocaml/extn.html) chapter:
  * [locally abstract types](http://caml.inria.fr/pub/docs/manual-ocaml/locallyabstract.html),
  * [First-class modules](http://caml.inria.fr/pub/docs/manual-ocaml/firstclassmodules.html), and
  * [GADT's](http://caml.inria.fr/pub/docs/manual-ocaml/gadts.html).
* Part III of the manual documents the tools, we will not be using much of this because third parties have improved on many of the tools and we will instead use those versions.  See below in the Tools list where we give "our" list of tools.
* Part IV describes the standard libraries; as with the tool we will primarily use Jane Street's `Base`/`Core` which replaces these with more modern versions so we will generally be ignoring this Part. 

#### Base and Core
`Core` is a complete rewrite of the standard libraries that come built in to OCaml.  Think of it as a "more modern" version of lists, sets, hash tables, etc, with lots of little improvements in many places.  It is an extension of `Base` which is in fact what we will mainly be using.

* [Core documentation](https://ocaml.janestreet.com/ocaml-core/latest/doc/core/Core/index.html) is not particularly readable as `Core` extends `Core_kernel` which extends `Base` and most times you probably just want the `Base` version so I would suggest starting there: [Base Documentation](https://ocaml.janestreet.com/ocaml-core/latest/doc/base/Base/index.html).
* The [Real World OCaml](https://dev.realworldocaml.org/index.html) book gives tutorial introductions to many of the `Core`/`Base`.

### The FPSE OCaml Toolbox

Here are all the tools we will be using.  You are required to have a build for which all these tools work, and the above `opam` one-liner should install them all.

* [`opam`](https://opam.ocaml.org) is the package management system.  See above for install and setup instructions.
* [`ocamlc`](http://caml.inria.fr/pub/docs/manual-ocaml/comp.html) is the standalone compiler which we will be invoking via the `dune` build tool.
* [`utop`](https://opam.ocaml.org/blog/about-utop/) is the read/eval/print loop.  It is a replacement for the original [`ocaml`](http://caml.inria.fr/pub/docs/manual-ocaml/toplevel.html) command, with many more features such as command history, replay, etc.
* [`Base`/`Core`](https://opensource.janestreet.com/core/) was described above
* [`ocamldoc`](http://caml.inria.fr/pub/docs/manual-ocaml/ocamldoc.html) is the documentation generator, turning code comments into documentation webpages similar to JavaDoc etc.
* [`dune`](https://dune.build) is the build tool (think `make`) that we will be using.  `ocamlbuild` is the standard build tool but it is not very flexible so we will not be using it.
* [OUnit](https://github.com/gildor478/ounit) is the unit tester for OCaml.  The opam package is called `ounit2` for obscure reasons.
* [`ppx_deriving`](https://github.com/ocaml-ppx/ppx_deriving) adds boilerplate code to type declarations including pretty printing (`ppx_deriving.show`) and comparison (`ppx_deriving.eq`,`ppx_deriving.ord`).

The above tools will be our "bread and butter", we will be using them on many assignments.  There are also a few specialized tools used on some specific assignments.

* [Base_quickcheck](https://opensource.janestreet.com/base_quickcheck/) is a fuzz tester / automated test generator for OCaml, designed to work well with the `Base` library.
* [`bisect_ppx`](https://github.com/aantron/bisect_ppx) will be used for code coverage.
* [Async](https://opensource.janestreet.com/async/) is a non-preempting asychronous threads library.
* We may also use `ppx_jane` which has functionality related to `ppx_deriving` and more.


### Development Environments for OCaml

You should use one of Atom or VSCode since they have OCaml-specific features such as syntax highliting, auto-indent, and lint analysis to make the coding process much smoother. If you are using a VM under Windows, you should aim to run one of these editors *within* the VM to take advantage of syntax highlighting and the like for OCaml.

**[Visual Studio Code](https://code.visualstudio.com)**: 
VSCode has very good OCaml support and is the "officially recommended editor". Install the **OCaml and Reason IDE** extension to get syntax highlighting, type information, etc: from the `View` menu select `Extensions`, then type in OCaml and this extension will show up; install it. You can also easily run a `utop` shell from within VSCode, just open up a shell from the `Terminal` menu and type `utop`.

[**Atom**](https://atom.io): 
Atom is very good with OCaml, but is unfortunately being slowly phased out after Microsoft bought Github.  So, it is probably a good time to switch from Atom to VSCode if you have not already.  To use Atom with OCaml install the `atom` and `apm` shell commands (see the **Atom..Install Shell Commands** menu option on Macs, or type shift-command-p(⇧⌘P) and then in the box type command `Window: Install Shell Commands`). With those commands installed, type into a terminal

        apm install language-ocaml linter ocaml-indent ocaml-merlin

to install the relevant OCaml packages. Here are some handy Atom keymaps for common operations these extensions support -- add this to your `.atom/keymap.cson` file:

        'atom-text-editor[data-grammar="source ocaml"]':
          'ctrl-shift-t': 'ocaml-merlin:show-type'
          'alt-shift-r': 'ocaml-merlin:rename-variable'
          'ctrl-shift-l': 'linter:lint'
          'ctrl-alt-f': 'ocaml-indent:file'

`linter:lint` will refresh the lint data based on the latest compiled version of your code. In addition, control-space should auto-complete.

**vim**: If you use `vim`, my condolances as it is woefully behind the times in spite of many band-aids added over the years.  Still, if you have been brainwashed to believe it is good, type shell command `opam user-setup install` after doing the above  default `opam` install to set up syntax highlighting, tab completion, displaying types, etc. See [here](https://github.com/ocaml/merlin/blob/master/vim/merlin/doc/merlin.txt) for some dense documentation.

**emacs**: See vim.  Confession: I still use emacs a bit but am trying to wean myself.  35-year-old habits die hard.  Note you will need to also `opam install tuareg` to get emacs to work, and follow the instructions the install generates.

### Real World OCaml

* The [Real World OCaml](https://dev.realworldocaml.org/index.html) book has recently been updated to a new edition.
* It documents many of the extensions we will be using, `Base`/`Core` libraries in particular, and we will be referencing several of the chapters for various lecture topics.

### Coding Style

* The [FPSE Style Guide](http://pl.cs.jhu.edu/fpse/style-guide.html) is the standard we will adhere to in the class; it follows general best practices for modern OCaml.  It will be expected of your code from HW 2 on.
