## List programming
* First we will do a few more recursive functions over lists
* Then we will show how the `Core.List` library functions allow a great many (most?) operations to be written without recursion

#### Reversing a list

* Let us write a somewhat more interesting function, reversing a list.
* Lists are immutable so it is going to create a completely new list, not change the original.
* This style of programming is called "Data structure corresponds to control flow" - the program needs to touch and reconstruct the whole data structure as it runs.

```ocaml
let rec rev l =
  match l with
  |  [] -> []
  |  x :: xs -> rev xs @ [x]
;;
rev [1;2;3];; (* recall input list is the tree 1 :: ( 2 :: ( 3 :: [])) *)
```

* Correctness of a recursive function by induction: assume recursive call does what you expect in arguing it is overall correct.
* For this example, can assume `rev xs` always reverses the tail of the list,  
    - (e.g. in computing `rev [1;2;3]` we match `x` = `1` and `xs` = `[2;3]` and can assume `rev [2;3]` = `[3;2]` )
* Given that fact, `rev xs @ [x]` should clearly reverse the whole list 
    - (e.g. `[3;2] @ [1]` = `[3;2;1]` for the example)
* QED, the function is proved correct! (actually partially correct, this induction argument does not rule out infinite loops)

Of course `rev` is also in `Core.List` since it is a common operation:

```ocaml
# List.rev [1;2;3];;
- : int list = [3; 2; 1]
```

**Another Example: zero out all the negative elements in a list of numbers**

* C solution: `for`-loop over it and mutate all negatives to 0
* OCaml immutable list solution: recurse on list structure, building the new list as we go

```ocaml
let rec zero_negs l =
  match l with
  |  [] -> []
  |  x :: xs -> (if x < 0 then 0 else x) :: zero_negs xs
in
zero_negs [1;-2;3];;
```

### Core.List library functions

* We already saw a few of these above, `List.rev` and `List.nth`.
* `List` is a **module**, think fancy package.  It contains functions *plus* values *plus* types *plus* even other modules
* `List` is itself in the module `Core` so the full name for `rev` is `Core.List.rev`
    * but we put an `open Core` in our `.ocamlinit` (and in the template for A1) so you can just write e.g. `List.rev`
* Note that the `Core` module extends (think subclass) `Base`, look in `Base.List` for documentation.
* Note that `List.hd` is also available, but you should nearly always be pattern matching to take apart lists; don't use `List.hd` on the homework.
* Let us [peek at the documentation for `List`](https://ocaml.janestreet.com/ocaml-core/latest/doc/base/Base/List/index.html) to see what is available; we will cover a few of them now.

#### Some simple but very handy `List` library functions
```ocaml
List.length ["d";"ss";"qwqw"];;
List.is_empty [];;
List.last_exn [1;2;3];; (* get last element; raises an exception if list is empty *)
List.join [[1;2];[22;33];[444;5555]];;
List.append [1;2] [3;4];; (* Usually the infix @ syntax is used for append *)
```

* Let us code a few of these as exercises (you should just use the library function normally, often they are more efficient)

```ocaml
let rec join l = match l with
  | [] -> []
  | l :: ls -> l @ join ls (* " by induction assume join will turn list-of-lists to single list" *)
```

#### OCaml tuples and some `List` library functions using tuples

* Along with lists `[1;2;3]` OCaml has tuples, `(1,2.,"3")`
* It is like a fixed-length list, but tuple elements **can have different types**
* You can also pattern match on tuples

```ocaml
# (1,2.,"3");;
- : int * float * string = (1, 2., "3")
```

* Here is a simple function to break a list in half using the `List.split_n` function
    - a pair of lists is returned by `split_n`

```ocaml
let split_in_half l = List.split_n l (List.length l / 2);;
split_in_half [2;3;4;5;99];;
```

* Now, using the `List.cartesian_product` function we can make all possible pairs of (front,back) elements

```ocaml
let all_front_back_pairs l = 
  let front, back = split_in_half l in List.cartesian_product front back;; (* observe how let can itself pattern match pairs *)
val all_front_back_pairs : 'a list -> ('a * 'a) list = <fun>
# all_front_back_pairs [1;2;3;4;5;6];;
- : (int * int) list =
[(1, 4); (1, 5); (1, 6); (2, 4); (2, 5); (2, 6); (3, 4); (3, 5); (3, 6)]
```

* Fact: lists of pairs are isomorphic to pairs of lists (of the same length)
* zipping and unzipping library functions can convert between these two equivalent forms.

```ocaml
List.unzip @@ all_front_back_pairs [1;2;3;4;5;6];;
```

* Note the use of `@@` here, recall it is function application but with "loose binding", avoids parens
* Here is an even cooler way to write the same thing, with pipe operation `|>` (based on shell pipe `|`)

```ocaml
[1;2;3;4;5;6] |> all_front_back_pairs |> List.unzip;;
```
* In a series of pipes, the leftmost argument is data, and all the others are functions
* The data is fed into first function, output of first function fed as input to second, etc
* This is exactly what the shell `|` does with standard input / standard output.

* `List.zip` is the opposite of unzip:

```ocaml
List.zip [1;2;3] [4;5;6];;
- : (int * int) list List.Or_unequal_lengths.t =
Core.List.Or_unequal_lengths.Ok [(1, 4); (2, 5); (3, 6)]
```
* The strange result is dealing with the case where the lists supplied may not be same length
* This type and value are hard to read, let us take a crack at it.
* `((int * int) list) List.Or_unequal_lengths.t` is the proper parentheses.
* `List.Or_unequal_lengths.t` is referring to the type `t` found in the `List.Or_unequal_lengths` module (a small module within the `List` module)
* We can use the `#show_type` directive in the top loop to see what `t` actually is:
```ocaml
# #show_type List.Or_unequal_lengths.t;;
type nonrec 'a t = 'a List.Or_unequal_lengths.t = Ok of 'a | Unequal_lengths
```
The latter case is for zipping lists of different lengths:

```ocaml
List.zip [1;2;3] [4;5];;
- : (int * int) list List.Or_unequal_lengths.t =
Core.List.Or_unequal_lengths.Unequal_lengths
```

* In the original same-length case we got the result from the first clause in this type, `Core.List.Or_unequal_lengths.Ok [(1, 4); (2, 5); (3, 6)]`.
* They should have just used the `result` type here, these values and types are really ugly!!
* Note `List.zip_exn` will just raise an exception for unequal-length lists, avoiding all of this wrapper ugliness
    - but in larger programs we really want to avoid exceptions at a distance so it is often worth the suffering

#### zip/unzip and Currying

We should be able to zip and then unzip as a no-op, one should undo the other (we will use the `_exn` version to avoid the above error wrapper).

```ocaml
List.unzip @@ List.zip_exn [1;2] [3;4];;
```
And the reverse should also work as it is an isomorphism:

```ocaml
List.zip_exn @@ List.unzip [(1, 3); (2, 4)];;
Line 1, characters 16-43:
Error: This expression has type int list * int list
       but an expression was expected of type 'a list
```

* Oops! It fails.  What happened here?
* `List.zip_exn` takes two arguments, lists to zip, whereas `List.unzip` returns a *pair of lists*.
* No worries, we can write a wrapper turning `List.zip_exn` into a version taking a pair of lists:

```ocaml
let zip_pair (l,r) = List.zip_exn l r in 
zip_pair @@ List.unzip [(1, 3); (2, 4)];;
[(1, 3); (2, 4)] |> zip_pair |> List.unzip;; (* Pipe equivalent form *)
```
* Congratulations, we just wrote a fancy no-op function.
* The general principle here is a Curried 2-argument function like `int -> int -> int` is **isomorphic** to `int * int -> int`
* The latter form looks more like a standard function taking multiple arguments and is the **uncurried** form.
* And we sometimes need to interconvert between the two representations

#### `List` functions which take function arguments

* So far we have done the "easier" functions in `List`; the real meat are the functions taking other functions
* Lets warm up with `List.filter`: remove all elements not meeting a condition which we supply a function to check

```ocaml
List.filter [1;-1;2;-2;0] (fun x -> x >= 0);;
```

* Cool, we can "glue in" any checking function (boolean-returning, i.e. a *predicate*) and `List.filter` will do the rest
* Observe `List.filter` has type `'a list -> f:('a -> bool) -> 'a list` -- the `f` is a *named argument*, we can put args out of order if we give name via `~f:` syntax:
```ocaml
List.filter ~f:(fun x -> x >= 0) [1;-1;2;-2;0];;
```
* And, since OCaml functions are Curried we can leave off the list argument to make a generic remove-negatives function.
```ocaml
let remove_negatives = List.filter ~f:(fun x -> x >= 0);;
remove_negatives  [1;-1;2;-2;0];;
```

Let us use `filter` to write a function determining if a list has any negative elements:

```ocaml
let has_negs l = not (l |> List.filter ~f:(fun x -> x < 0) |> List.is_empty);;
```
 * The example shows the power of pipelining, it is easier to see the processing order with `|>`
 * This is a common operation so there is a library function for it as well: does there *exist* any element in the list where predicate holds?

```ocaml
let has_negs l = List.exists ~f:(fun x -> x < 0) l;;
```
Similarly, `List.for_all` checks if it holds for *all* elements.

#### List.map

* `List.map` is  super cool, apply some operation we supply to every element of a list:

```ocaml
# List.map ~f:(fun x -> x + 1) [1;-1;2;-2;0];;
- : int list = [2; 0; 3; -1; 1]
# List.map ~f:(fun x -> x >= 0) [1;-1;2;-2;0];;
- : bool list = [true; false; true; false; true]
```

#### Folding

* Observe the `for_all` and `exists` functions can be viewed as just mapping over the predicate like in the previous, and inserting an "and" (for all) or an "or" (exists) between each list element.
* The `fold` library functions do exactly that.  Here for example is `List.fold_right` at work 

```ocaml
let exists ~f l =  (* Note the ~f is **declaring** a named argument f, we were only using pre-declared ones above *)
  let bool_result_list = List.map ~f:f l in
  List.fold_right bool_result_list ~f:(||) ~init:false;;
# exists ~f:(fun x -> x >= 0) [-1;-2];;
- : bool = false
# exists ~f:(fun x -> x >= 0) [1;-2];;
- : bool = true
```

* The `~f`  parameter is the operation to put between list elements, disjunction `||` in this example;
* The `~init` is needed because it is a binary operator and an initial value is needed
* For `fold_right` the `~init` is on the **right**, that is why it is called a "fold right":

```ocaml
# List.fold_right ~f:(||) ~init:false [true; false];; (* this is true || (false || (false)), the final false the ~init *)
- : bool = true
```

* `List.fold_left` aka `List.fold` puts the `~init` on the left:
```ocaml
# List.fold_left ~f:(||) ~init:false [true; false];; (* this is false || (true || false), the FIRST false the ~init *)
- : bool = true
```

* Note that in this case folding left or right gives the same answer; 
    - that is because `||` is *commutative and associative*, so e.g. `true || (false || (false) = false || (true || false)`.
* But e.g. `List.fold_left ~f:(-) ~init:0 [1;2;3]` is `-6` and `List.fold_right ~f:(-) ~init:0 [1;2;3]` is `2`
* Folding left is preferred, it is tail recursive and can be optimized (more on this later)