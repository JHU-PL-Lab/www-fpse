utop # 3+4;;
- : int = 7

open Core;; (* Make the Core libraries directly available *)
let hw = "hello" ^ "world";;
printf "the string is %s\n" hw

3 + 4;; (* outputs `- : int = 7` -- the value is 7, int is the type, "-" means no name given *)
let x = 3 + 4;; (* outputs `val x : int = 7` - give the result value a name, via let. *)
let y = x + 5;; (* the above defines `x` so can use it subsequently *)
let z = x + 5 in z - 1;; (* let .. in defines a local variable z *)
(* z is not defined after the `in` is over: z + 1 ;; will give an error. *)

let b = true;;
b && false;;
true || false;;
1 = 2;; (* = not == for equality comparison; note = works on ints only in our OCaml setup *)
1 <> 2;;  (* <>, not !=, for not equal *)

4.5;; (* floats *)
4.5 +. 4.3;; (* operations are +. etc not just + which is for ints only *)
30980314323422L;; (* 64-bit integers *)
'c';; (* characters *)
"and of course strings";;

let squared x = x * x;; (* outputs `val squared : int -> int = <fun>` *)
squared 4;; (* to call a function -- separate arguments with S P A C E S - ! *)

let rec fib n = (* the "rec" keyword needs to be added to allow recursion *)
  if n <= 0 then 0
  else if n = 1 then 1
  else fib (n - 1) + fib (n - 2);; (* notice again everything is an expression, no "return" *)

fib 10;; (* get the 10th Fibonacci number; 2^10 steps so don't make input too big! *)

let rec fib x = match x with
  | 0 -> 0 
  | 1 -> 1 
  | n -> fib (n - 1) + fib (n - 2);;

let add1 x = x + 1;; (* the normal way to define an add1 function in OCaml *)
add1 3;;
let anon_add1 = (function x -> x + 1);; (* equivalent to above; "x" is argument here *)
let anon_add1 = (fun x -> x + 1);;      (* shorthand notation -- cut off the "ction" *)
anon_add1 3;;
(anon_add1 4) + 7;; 
((fun x -> x + 1) 4) + 7;; (* can also inline an anonymous function definition *)

let add x y = x + y;;
add 3 4;;
(add 3) 4;; (* same meaning as previous application -- two applications, " " associates LEFT *)
let add3 = add 3;; (* No need to give all arguments at once - !  
                      Type of add is int -> (int -> int) - "CURRIED" *)
add3 4;;
add3 20;;
(+) 3 4;; (* Putting () around any infix operator turns it into a 2-argument function *)

add3 (3 * 2);;
add3 3 * 2;; (* NOT the previous - this is the same as (add3 3) * 2 - application binds tighter than * *)
add3 @@ 3 * 2;; (* LIKE the original - @@ is like the " " for application but binds LOOSER than other ops *)

3.4 = 4.2;; (* errors, = only works on ints with the Core library in use *)
Float.(3.3 = 4.4);; (* Solution: use the Float module's = function for floats *)

Some 5;;
- : int option = Some 5

None;;
- : 'a option = None

# let nicer_div m n = if n = 0 then Error "Divide by zero" else Ok (m / n);;
val nicer_div : int -> int -> (int, string) result = <fun>

# match (nicer_div 5 2) with 
   | Ok i -> i + 7
   | Error s -> failwith s;;
- : int = 9

let div_exn m n = if n = 0 then failwith "divide by zero is bad!" else m / n;;
div_exn 3 4;;

let l1 = [1; 2; 3];;
let l2 = [1; 1+1; 1+1+1];;
let l3 = ["a"; "b"; "c"];;
let l4 = [1; "a"];; (* error - All elements must have same type *)
let l5 = [];; (* empty list *)

0 :: l1;; (* "::" is 'consing' 0 to the top of the tree - fast *)
0 :: (1 :: (2 :: (3 :: [])));; (* equivalent to [0;1;2;3] *)
[1; 2; 3] @ [4; 5];; (* appending lists - slower, needs to cons 3/2/1 on front of [4;5] *)
let z = [2; 4; 6];;
let y = 0 :: z;; (* in y, 0 is the *head* (first elt) of the list and z is the *tail* (rest of list) *)
z;; (* Observe z itself did not change -- recall lists are immutable in OCaml *)

let tl_exn l =
  match l with
  |  [] -> invalid_arg "empty lists have no tail"
  |  x :: xs -> xs  (* the pattern x :: xs  binds x to the first elt, xs to ALL the others *)
;;
let l = [1;2;3];; 
let l' = tl_exn l;;
l;; (* Note: lists are immutable, l didn't change!! *)
let l'' =  tl_exn l' (* So to get tail of tail, take tail of l' not 2 x tail of l!  THREAD the state! *)
tl_exn [];; (* Raises an `invalid_arg` exception if the list had no tail *)

let tl l =
  match l with
  |  [] -> Error "empty list has no tail"
  |  x :: xs -> Ok xs
;;
let l = [1;2;3];; 
let l' = tl l;;
tl [];;
let l'' = tl l' (* Oops this fails!  As in the div example above need to case on `Ok/Error` *)

let rec nth_exn l n =
  match l with
  |  [] -> invalid_arg "there is no nth element in this list"
  |  x :: xs -> if n = 0 then x else nth_exn xs (n-1)
;;
nth_exn [33;22;11] 1;;
nth_exn [33;22;11] 3;;

# List.nth [1;2;3] 2;;
- : int option = Some 3

