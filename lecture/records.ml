let rat = { num = 5 ; denom = 7 } (* doesn't work! Its type isn't defined yet *)

type ratio = { num : int ; denom : int }

let q = { num = 53 ; denom = 6 }

let rat_to_int r =
  r.num / d.denom (* project the labels out from r *)

let rat_to_int r =
  match r with
  | { num = n ; denom = d } -> n / d (* variable n contains numerator, d contains denominator *)

let rat_to_int r =
  match r with
  | { num ; denom } -> num / denom (* sugar for { num = num ; denom = denom } -> .. *)

let rat_to_int { num = n ; denom = d } = (* pattern as a function parameter *)
  n / d

let rat_to_int { num ; denom } = (* pattern parameter plus punning on labels/variables *)
  num / denom

let rat_to_int r =
  let { num ; denom } = r in (* pattern in a value let definition *)
  num / denom

let numerator { num ; _ } = (* the _ catches all the other labels, no matter how many there are *)
   num

type newratio = { num : int ; coeff : float } (* shadows above ratio type's label num *)

(* Inferred type for x is newratio because its num field is more recent *)
let get_num x =
  x.num

(* Resolve the ambiguity by explicitly declaring x's type *)
let get_new_num (x : newratio) =
  x.num

let make_ratio (num : int) (denom : int) =
  { num ; denom } (* sugar for { num = num ; denom = denom } *)

make_ratio 1 2

type abc = { a : int ; b : int ; c : int }

let r1 = { a = 0 ; b = 1 ; c = 2 }

let r2 = { r1 with a = 4 } (* same as writing { a = 4; b = r1.b; c = r1.c } - implicitly copy over others *)
(* Note this is a COPY, NOT a mutate - ! *)

let r2 = { r1 with b = 2 ; c = 3 } (* use semicolons for multiple overrides *)

let c = 4
let r3 = { r1 with b = 2 ; c } (* combining puns, `c = c` can again shorten to `c` *)

type gbu =
  | Good of { sugar : string ; units : int }
  | Bad of { spice : string ; units : int }
  | Ugly

let good_units_exn v =
  match v with
  | Good { units ; _ } -> units (* this works! *)
  | Bad _ | Ugly -> failwith "unhandled"

let good_units_exn v =
  match v with
  | Good r -> r.units (* so does this! *)
  | Bad _ | Ugly -> failwith "unhandled"

let return_good_record v =
  match v with
  | Good r -> r (* This is not allowed! Type error! We cannot let r escape. *)
  | Bad _ | Ugly -> failwith "unhandled"

type 'a bin_tree =
  | Leaf
  | Node of { data : 'a ; left : 'a bin_tree ; right : 'a bin_tree }

