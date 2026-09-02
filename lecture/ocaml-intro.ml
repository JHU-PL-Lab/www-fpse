utop # 3+4;;
- : int = 7

let hw = "hello" ^ "world";;
Printf.printf "the string is %s\n" hw

3 + 4;; (* outputs `- : int = 7` -- the value is 7, int is the type, "-" means no name given *)

let x = 3 + 4;; (* outputs `val x : int = 7` - give the result value a name, via let. *)

let y = x + 5;; (* the above defines `x`, so can use it subsequently *)

let z = x + 5 in z - 1;; (* let .. in defines a local variable z *)
(* z is not defined after the `in` is over: z + 1 ;; will give an error. *)

let b = true;;

b && false;;

true || false;;

1 = 2;; (* equality comparison, not ==; can compare at any type with = *)

1 <> 2;;  (* <>, not !=, for not equal *)

4.5;; (* floats *)

4.5 +. 4.3;; (* float operations are +. etc not just + which is for ints only.  Why? type inference! *)

30980314323422L;; (* 64-bit integers *)

'c';; (* characters *)

"and of course strings";;

let squared x = x * x;; (* outputs `val squared : int -> int = <fun>` *)

squared 4;; (* this calls the function -- separate arguments with S P A C E S - ! *)

let rec fib n = (* the "rec" keyword needs to be added to allow recursion *)
  if n <= 0 then
    0 (* e.g. just write `0` to return `0`, not `return(0)` *)
  else if n = 1 then
    1
  else
    fib (n - 1) + fib (n - 2)
;;

fib 10;; (* get the 10th Fibonacci number; 2^10 steps so don't make input too big! *)

let rec fib x =
  match x with
  | 0 -> 0
  | 1 -> 1
  | n -> fib (n - 1) + fib (n - 2)
;;

let add1 x = x + 1;; (* the normal way to define an add1 function in OCaml *)

add1 3;;

let add1' = (function x -> x + 1);;  (* another way: define a `function` value and put in a regular variable *)

let add1'' = (fun x -> x + 1);;      (* equivalent shorthand -- cut off the "ction" *)

add1'' 3;;

(add1'' 4) + 7;;

((fun x -> x + 1) 4) + 7;; (* can inline so function NEVER named; useful when passing one function to another *)

let add x y = x + y;;

add 3 4;;

(add 3) 4;; (* same meaning as previous application -- two applications, " " associates LEFT *)

let add3 = add 3;; (* No need to give all arguments at once - !
                      Type of add is int -> (int -> int) - "CURRIED" *)
add3 4;;

add3 20;;

(+) 3 4;; (* Putting () around any infix operator turns it into a prefix function *)

add3 (3 * 2);;

add3 3 * 2;; (* NOT the previous - this is the same as (add3 3) * 2 - application binds TIGHTER than `*` *)

add3 @@ 3 * 2;; (* LIKE the original - @@ is like " " for application BUT binds LOOSER than all other ops *)

let add (x : int) (y : int) : int = x + y;;

Some 5;;
- : int option = Some 5

None;;
- : 'a option = None

# let nicer_div m n =
  if n = 0 then
    Error "Divide by zero" (* main difference of `result`: can return information about the error *)
  else
    Ok (m / n)
;;
val nicer_div : int -> int -> (int, string) result = <fun>

# match nicer_div 5 2 with
  | Ok i -> i + 7
  | Error s -> failwith s;;
- : int = 9

let div_exn m n =
  if n = 0 then
    failwith "divide by zero is bad!"
  else
    m / n
;;

div_exn 3 4;;

let l1 = [1; 2; 3];; (* notice the type here is `int list` a list of integers *)
let l0 = 0 :: l1;; (* "::" is 'consing' 0 to the top of the tree - fast *)
l1;; (* observe that l1 didn't change, its data is just shared with l0 *)

let l1' = 1 :: (2 :: (3 :: [])) in l1 = l1' ;; (* [1;2;3] is just sugar for serial consing *)

let l2 = ["a"; "b"; "c"];; (* list elements can be of any type *)

let l3 = [1; "a"];; (* error - all elements must have same type *)

let l5 = [];; (* the empty list *)

[1; 2; 3] @ [4; 5];; (* `@` appends lists - slower than `::`, needs to cons 3/2/1 on front of [4;5] *)

let tl l =
  match l with
  |  [] -> invalid_arg "empty lists have no tail"
  |  h :: t -> t  (* the pattern h :: t  binds h to the first elt (left subtree), t to rest (right subtree) *)
;;

let l = [1;2;3];;

let l' = tl l;;

l;; (* lists are immutable, so l didn't change *)

let l'' =  tl l' (* To get tail of tail, take tail of l' .. build on value returned from previous op *)

tl [];; (* Raises `invalid_arg` exception if the list had no tail *)

let tl' l =
  match l with
  |  [] -> Error "empty list has no tail"
  |  h :: t -> Ok t
;;

let l = [1;2;3];;

let l' = tl' l;;

tl' [];;

let l'' = tl' l' (* Oops this fails!  As in the div example above need to match on `Ok/Error` *)

let rec nth l n =
  match l with
  |  [] -> invalid_arg "there is no nth element in this list"
  |  hd :: tl ->
    if n = 0 then
      hd
    else
      nth tl (n-1) (* "the nth element of l is the (n-1)-th element of tl" *)
;;

nth [33;22;11] 1;;

nth [33;22;11] 3;;

# List.nth [1;2;3] 2;;
- : int = 3

# List.nth [1;2;3] 5;;
Exception: Failure "nth".

# List.nth_opt [1;2;3] 5;;
- : int option = None

# List.nth_opt [1;2;3] 1;;
- : int option = Some 2

let rec zero_negs l =
  match l with
  | [] -> []
  | hd :: tl -> (if hd < 0 then 0 else hd) :: zero_negs tl (* assume by induction that zero_negs tl will properly zero tl *)
;;

zero_negs [1;-2;3];;

