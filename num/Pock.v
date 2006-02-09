Require Import List.
Require Import ZArith.
Require Import Zorder.
Require Import ZAux.
Require Import LucasLehmer.
Require Import Pocklington.
Require Import ZnZ.
Require Import Zmisc.
Require Import Pmod.
Require Import Mod_op.
Require Import W.
Require Import Lucas.
Require Export PocklingtonCertificat.

Open Scope Z_scope. 

Section test.

Variable w: Set.
Variable w_op: znz_op w.
Variable op_spec: znz_spec w_op.
Variable p: positive.
Variable b: w.

Notation "[| x |]" :=
   (znz_to_Z w_op x)  (at level 0, x at level 99).

Hypothesis b_pos: 0 < [|b|].

Variable m_op: mod_op w.
Variable m_op_spec: mod_spec w_op b m_op.

Open Scope positive_scope.
Open Scope P_scope.

Let pow := m_op.(power_mod).
Let times := m_op.(mul_mod).
Let pred:= m_op.(pred_mod).

(* [fold_pow_mod a [q1,_;...;qn,_]] b = a ^(q1*...*qn) mod b *)
(* invariant a mod N = a *)
Definition fold_pow_mod (a: w) l := 
  fold_left
    (fun a' (qp:positive*positive) =>  pow a' (fst qp))
    l a.

Lemma fold_pow_mod_spec : forall l (a:w), 
  [|a|] < [|b|] -> [|fold_pow_mod a l|] = ([|a|]^(mkProd' l) mod [|b|])%Z. 
intros l; unfold fold_pow_mod; elim l; simpl fold_left; simpl mkProd'; auto; clear l.
intros a H; rewrite Zpower_exp_1; rewrite Zmod_def_small; auto with zarith.
case (spec_to_Z op_spec a); auto with zarith.
intros (p1, q1) l Rec a H.
case (spec_to_Z op_spec a); auto with zarith; intros U1 U2.
rewrite Rec.
rewrite m_op_spec.(power_mod_spec) with (t := [|a|]); auto with zarith.
rewrite <- Zmod_Zpower.
rewrite times_Zmult; rewrite Zpower_mult; auto with zarith.
apply Zle_lt_trans with (2 := H); auto with zarith.
rewrite Zmod_def_small; auto with zarith.
rewrite m_op_spec.(power_mod_spec) with (t := [|a|]); auto with zarith.
match goal with |- context[(?X mod ?Y)%Z] =>
  case (Z_mod_lt X Y); auto with zarith
end.
rewrite Zmod_def_small; auto with zarith.
Qed.


Fixpoint all_pow_mod (prod a: w) (l:dec_prime) {struct l}: w*w :=
  match l with
  | nil => (prod,a)
  | (q,_) :: l => 
    let m := pred (fold_pow_mod a l) in
    all_pow_mod (times prod m) (pow a q) l
  end.


Lemma snd_all_pow_mod :
 forall l (prod a :w), [|a|] < [|b|] ->
   [|snd (all_pow_mod prod a l)|] = ([|a|]^(mkProd' l) mod [|b|])%Z.
intros l; elim l; simpl all_pow_mod; simpl mkProd'; simpl snd; clear l.
intros _ a H; rewrite Zpower_exp_1; auto with zarith.
rewrite Zmod_def_small; auto with zarith.
case (spec_to_Z op_spec a); auto with zarith.
intros (p1, q1) l Rec prod a H.
case (spec_to_Z op_spec a); auto with zarith; intros U1 U2.
rewrite Rec; auto with zarith.
rewrite m_op_spec.(power_mod_spec) with (t := [|a|]); auto with zarith.
rewrite <- Zmod_Zpower.
rewrite times_Zmult; rewrite Zpower_mult; auto with zarith.
apply Zle_lt_trans with (2 := H); auto with zarith.
rewrite Zmod_def_small; auto with zarith.
rewrite m_op_spec.(power_mod_spec) with (t := [|a|]); auto with zarith.
match goal with |- context[(?X mod ?Y)%Z] =>
  case (Z_mod_lt X Y); auto with zarith
end.
rewrite Zmod_def_small; auto with zarith.
Qed.

Lemma fold_aux : forall a N l prod,
  (fold_left
     (fun (r : Z) (k : positive * positive) =>
      r * (a ^(N / fst k) - 1) mod [|b|]) l (prod mod [|b|]) mod [|b|] = 
  fold_left
     (fun (r : Z) (k : positive * positive) =>
      r * (a^(N / fst k) - 1)) l prod mod [|b|])%Z.
induction l;simpl;intros.
rewrite Zmod_mod; auto with zarith.
rewrite <- IHl; auto with zarith.
rewrite Zmod_mult; auto with zarith.
rewrite Zmod_mod; auto with zarith.
rewrite <- Zmod_mult; auto with zarith.
Qed.

Lemma fst_all_pow_mod :
 forall l (a:w) (R:positive) (prod A :w),
  [|prod|] = ([|prod|] mod [|b|])%Z ->
  [|A|] = ([|a|]^R mod [|b|])%Z ->
  [|fst (all_pow_mod prod A l)|] = 
    ((fold_left
      (fun r (k:positive*positive) => 
        (r * ([|a|] ^ (R* mkProd' l / (fst k)) - 1))) l [|prod|]) mod [|b|])%Z.
intros l; elim l; simpl all_pow_mod; simpl fold_left; simpl fst;
  auto with zarith; clear l.
intros (p1,q1) l Rec; simpl fst.
intros a R prod A H1 H2.
assert (F: 0 <= [|A|] < [|b|]).
rewrite H2.
match goal with |- context[(?X mod ?Y)%Z] =>
  case (Z_mod_lt X Y); auto with zarith
end.
assert (F1: ((fun x => x = x mod [|b|])%Z [|fold_pow_mod A l|])).
rewrite Zmod_def_small; auto.
rewrite fold_pow_mod_spec; auto with zarith.
match goal with |- context[(?X mod ?Y)%Z] =>
  case (Z_mod_lt X Y); auto with zarith
end.
assert (F2: ((fun x => x = x mod [|b|])%Z [|pred (fold_pow_mod A l)|])).
rewrite Zmod_def_small; auto.
rewrite(fun x => m_op_spec.(pred_mod_spec) x [|x|]);
  auto with zarith.
match goal with |- context[(?X mod ?Y)%Z] =>
  case (Z_mod_lt X Y); auto with zarith
end.
rewrite (Rec a (R * p1)); auto with zarith.
rewrite(fun x y => m_op_spec.(mul_mod_spec) x y [|x|] [|y|]);
  auto with zarith.
rewrite(fun x => m_op_spec.(pred_mod_spec) x [|x|]);
  auto with zarith.
rewrite fold_pow_mod_spec; auto with zarith.
rewrite H2.
repeat rewrite Zpos_mult.
repeat rewrite times_Zmult.
repeat rewrite <- Zmult_assoc.
apply sym_equal; rewrite <- fold_aux; auto with zarith.
apply sym_equal; rewrite <- fold_aux; auto with zarith.
eq_tac; auto.
match goal with |- context[fold_left ?x  _ _] =>
  apply f_equal2 with (f := fold_left x); auto with zarith
end.
rewrite Zmod_mod; auto with zarith.
rewrite (Zmult_comm R); repeat rewrite <- Zmult_assoc;
 rewrite (Zmult_comm p1); rewrite Z_div_mult; auto with zarith.
repeat rewrite (Zmod_mult [|prod|]);auto with zmisc.
eq_tac; [idtac | eq_tac]; auto.
eq_tac; auto.
rewrite Zmod_mod; auto.
repeat rewrite (fun x => Zmod_minus x 1); auto with zarith.
eq_tac; auto; eq_tac; auto.
rewrite Zmult_comm; rewrite <- Zmod_Zpower; auto with zmisc. 
rewrite Zpower_mult; auto with zarith.
rewrite Zmod_mod; auto with zarith.
rewrite Zmod_def_small; auto.
rewrite(fun x y => m_op_spec.(mul_mod_spec) x y [|x|] [|y|]);
  auto with zarith.
match goal with |- context[(?X mod ?Y)%Z] =>
  case (Z_mod_lt X Y); auto with zarith
end.
rewrite(fun x => m_op_spec.(power_mod_spec) x [|x|]);
  auto with zarith.
apply trans_equal with ([|A|] ^ p1 mod [|b|])%Z; auto.
rewrite H2.
rewrite times_Zmult; rewrite Zpower_mult; auto with zarith.
rewrite <- Zmod_Zpower; auto with zarith.
rewrite Zmod_def_small; auto.
Qed.


Fixpoint pow_mod_pred (a:w) (l:dec_prime) {struct l} : w :=
  match l with
  | nil => a
  | (q, p)::l =>
    if (p ?= 1) then pow_mod_pred a l
    else 
      let a' := iter_pos (Ppred p) _ (fun x => pow x q) a in
      pow_mod_pred a' l
  end.

Lemma iter_pow_mod_spec : forall q p a, [|a|] = ([|a|] mod [|b|])%Z ->
  ([|iter_pos p _ (fun x => pow x q) a|] = [|a|]^q^p mod [|b|])%Z.
intros q1 p1; elim p1; simpl iter_pos; clear p1.
intros p1 Rec a Ha.
rewrite(fun x => m_op_spec.(power_mod_spec) x [|x|]);
  auto with zarith.
repeat rewrite Rec; auto with zarith.
match goal with |- (Zpower_pos ?X ?Y mod ?Z = _)%Z => 
  apply trans_equal with (X ^ Y mod Z)%Z; auto
end.
repeat rewrite <- Zmod_Zpower; auto with zmisc.
repeat rewrite <- Zpower_mult; auto with zmisc.
repeat rewrite <- Zmod_Zpower; auto with zmisc.
repeat rewrite <- Zpower_mult; auto with zarith zmisc.
eq_tac; auto.
eq_tac; auto.
rewrite Zpos_xI.
assert (tmp: forall x, (2 * x = x + x)%Z); auto with zarith; rewrite tmp;
  clear tmp.
repeat rewrite Zpower_exp; auto with zarith.
rewrite Zpower_exp_1; try ring; auto with misc.
rewrite Zmod_mod; auto with zarith.
rewrite Rec; auto with zmisc.
rewrite Zmod_mod; auto with zarith.
rewrite Rec; auto with zmisc.
rewrite Zmod_mod; auto with zarith.
intros p1 Rec a Ha.
repeat rewrite Rec; auto with zarith.
repeat rewrite <- Zmod_Zpower; auto with zmisc.
repeat rewrite <- Zpower_mult; auto with zmisc.
eq_tac; auto.
eq_tac; auto.
rewrite Zpos_xO.
assert (tmp: forall x, (2 * x = x + x)%Z); auto with zarith; rewrite tmp;
  clear tmp.
repeat rewrite Zpower_exp; auto with zarith.
rewrite Zmod_mod; auto with zarith.
intros a Ha; rewrite Zpower_exp_1; auto with zarith.
rewrite(fun x => m_op_spec.(power_mod_spec) x [|x|]);
  auto with zarith.
Qed.

Lemma pow_mod_pred_spec : forall l a,
  ([|a|] = [|a|] mod [|b|] ->
  [|pow_mod_pred a l|] = [|a|]^(mkProd_pred l) mod [|b|])%Z. 
intros l; elim l; simpl pow_mod_pred; simpl mkProd_pred; clear l.
intros; rewrite Zpower_exp_1; auto with zarith.
intros (p1,q1) l Rec a H; simpl snd; simpl fst.
case (q1 ?= 1)%P; auto with zarith.
rewrite Rec; auto.
rewrite iter_pow_mod_spec; auto with zarith.
rewrite times_Zmult; rewrite pow_Zpower.
rewrite <- Zmod_Zpower; auto with zarith.
rewrite Zpower_mult; auto with zarith.
rewrite Zmod_def_small; auto with zarith.
rewrite iter_pow_mod_spec; auto with zarith.
match goal with |- context[(?X mod ?Y)%Z] =>
  case (Z_mod_lt X Y); auto with zarith
end.
Qed.

End test.

Definition test_pock N a dec sqrt := 
  if (2 ?< N) then
    let Nm1 := Ppred N in
    let F1 := mkProd dec in
    match (Nm1 / F1)%P with
    | (Npos R1, N0) =>
      if is_odd R1 then
        if is_even F1 then
          if (1 ?< a) then
            let (s,r') := (R1 / (xO F1))%P in
            match r' with
            | Npos r =>
              if (a ?< N) then
              let op := cmk_op (nat_of_P (pheight (N + 1)) - 3) in
              let wN := znz_of_Z op (Zpos N) in
              let wa := znz_of_Z op (Zpos a) in
              let w1 := znz_of_Z op 1 in
              let mod_op := make_mod_op op wN in
              let pow := mod_op.(power_mod) in
              let ttimes := mod_op.(mul_mod) in 
              let pred:= mod_op.(pred_mod) in
              let gcd:= op.(znz_gcd) in
              let A := pow_mod_pred _ mod_op (pow wa R1) dec in
              match all_pow_mod _ mod_op w1 A dec with
              | (p, aNm1) =>
                match znz_to_Z op aNm1 with 
                  (Zpos xH) => 
                   match znz_to_Z op (gcd p wN) with 
                   (Zpos xH) => 
                    if check_s_r s r sqrt then 
		      (N ?< (times ((times ((xO F1)+r+1) F1) + r) F1) + 1)
                    else false
                   | _ => false
                   end
                 | _ => false
                end             
              end else false
            | _ => false
            end
	  else false
        else false 
      else false
    | _=> false
    end      
  else false.

Set Printing All.
Lemma test_pock_correct : forall N a dec sqrt,
   (forall k, In k dec -> prime (Zpos (fst k))) ->
   test_pock N a dec sqrt = true ->
   prime N.
unfold test_pock;intros N a dec sqrt H.
match goal with |- context[if ?x then _ else _] =>
  case_eq x; intros If1; auto
end.
2: intros; discriminate.
match goal with H: (?X ?< ?Y) = true |- _ =>
  generalize (is_lt_spec X Y); rewrite H; clear H; intros H
end.
generalize (div_eucl_spec (Ppred N) (mkProd dec));
 destruct ((Ppred N) / (mkProd dec))%P as (R1,n).
simpl fst; simpl snd; intros (H1, H2).
destruct R1 as [|R1].
intros; discriminate.
destruct n.
2: intros; discriminate.
match goal with |- context[if ?x then _ else _] =>
  case_eq x; intros If2; auto
end.
assert (If0: Zodd R1).
apply is_odd_Zodd; auto.
clear If2; rename If0 into If2.
2: intros; discriminate.
match goal with |- context[if ?x then _ else _] =>
  case_eq x; intros If3; auto
end.
assert (If0: Zeven (mkProd dec)).
apply is_even_Zeven; auto.
clear If3; rename If0 into If3.
2: intros; discriminate.
match goal with |- context[if ?x then _ else _] =>
  case_eq x; intros If4; auto
end.
match goal with H: (?X ?< ?Y) = true |- _ =>
  generalize (is_lt_spec X Y); rewrite H; clear H; intros H
end.
2: intros; discriminate.
generalize (div_eucl_spec R1 (xO (mkProd dec)));
 destruct ((R1 / xO (mkProd dec))%P) as (s,r'); simpl fst;
 simpl snd; intros (H3, H4).
destruct r' as [|r].
intros; discriminate.
match goal with |- context[if ?x then _ else _] =>
  case_eq x; intros If5; auto
end.
match goal with H: (?X ?< ?Y) = true |- _ =>
  generalize (is_lt_spec X Y); rewrite H; clear H; intros H
end.
2: intros; discriminate.
set (bb := (nat_of_P (pheight (N + 1)) - 3)%nat).
set (w_op := cmk_op bb).
assert (op_spec: znz_spec w_op).
unfold bb, w_op; apply cmk_spec; auto.
assert (F0: N < Basic_type.base (znz_digits w_op)).
unfold w_op, bb, Basic_type.base; rewrite cmk_op_digits; 
  auto with zarith.
apply Zlt_le_trans with (N + 1)%positive; auto with zarith.
rewrite Zpos_plus; auto with zarith.
apply Zle_trans with (1 := (pheight_correct (N + 1)%positive)).
apply Zpower_le_monotone; auto with zarith.
split; auto with zarith.
apply Zpower_le_monotone; auto with zarith.
split; auto with zarith.
case (le_or_lt 3 (nat_of_P (pheight (N + 1)))); intros A2.
rewrite inj_minus1; simpl; auto with arith zarith.
rewrite <- Zpos_eq_Z_of_nat_o_nat_of_P; auto with zarith.
rewrite inj_minus2; simpl; auto with zarith.
generalize (inj_le (nat_of_P (pheight (N + 1))) 3); simpl; auto with zarith.
rewrite <- Zpos_eq_Z_of_nat_o_nat_of_P; auto with zarith.
assert (F1: znz_to_Z w_op (znz_of_Z w_op N) = N).
rewrite znz_of_Z_correct; auto with zarith.
assert (F2: 1 < znz_to_Z w_op (znz_of_Z w_op N)).
rewrite F1; auto with zarith.
assert (F3: 0 < znz_to_Z w_op (znz_of_Z w_op N)); auto with zarith.
assert (F4: znz_to_Z w_op (znz_of_Z w_op a) = a).
rewrite znz_of_Z_correct; auto with zarith.
assert (F5: znz_to_Z w_op (znz_of_Z w_op 1) = 1).
rewrite znz_of_Z_correct; auto with zarith.
assert (F6: N - 1 = (R1 * mkProd_pred dec)%positive * mkProd' dec).
rewrite Zpos_mult.
rewrite <- Zmult_assoc; rewrite mkProd_pred_mkProd; auto with zarith.
simpl in H1; rewrite Zpos_mult in H1; rewrite <- H1; rewrite Ppred_Zminus;
  auto with zarith.
assert (m_spec: mod_spec w_op (znz_of_Z w_op N) 
                  (make_mod_op w_op (znz_of_Z w_op N))).
apply make_mod_spec; auto with zarith.
match goal with |- context[all_pow_mod ?x ?y ?z ?t ?u] =>
  generalize (fst_all_pow_mod x w_op op_spec _ F3 _ m_spec 
               u (znz_of_Z w_op a) (R1*mkProd_pred dec) z t);
  generalize (snd_all_pow_mod x w_op op_spec _ F3 _ m_spec u z t);
  fold bb w_op;
  case (all_pow_mod x y z t u); simpl fst; simpl snd 
end.
intros prod aNm1; intros H5 H6.
case_eq (znz_to_Z w_op aNm1).
intros; discriminate.
2: intros; discriminate.
intros p; case p; clear p.
intros; discriminate.
intros; discriminate.
intros If6.
case_eq (znz_to_Z w_op (znz_gcd w_op prod (znz_of_Z w_op N))).
intros; discriminate.
2: intros; discriminate.
intros p; case p; clear p.
intros; discriminate.
intros; discriminate.
intros If7.
match goal with |- context[if ?x then _ else _] =>
  case_eq x; intros If8; auto
end.
2: intros; discriminate.
intros If9.
match goal with H: (?X ?< ?Y) = true |- _ =>
  generalize (is_lt_spec X Y); rewrite H; clear H; intros H
end.
assert (U1: N - 1 = mkProd dec * R1).
rewrite <- Ppred_Zminus in H1; auto with zarith.
rewrite H1; simpl.
repeat rewrite Zpos_mult; auto with zarith.
assert (HH:Z_of_N s = R1 / (2 * mkProd dec) /\ Zpos r =  R1 mod (2 * mkProd dec)).
apply mod_unique with (2 * mkProd dec);auto with zarith.
apply Z_mod_lt; auto with zarith.
rewrite <- Z_div_mod_eq; auto with zarith.
rewrite H3.
simpl;ring.
case HH; clear HH; intros HH1 HH2.
apply PocklingtonExtra with (F1:=mkProd dec) (R1:=R1) (m:=1);
  auto with zmisc zarith.
case (Zle_lt_or_eq 1 (mkProd dec)); auto with zarith.
simpl in H2; auto with zarith.
intros HH; contradict If3; rewrite <- HH.
apply Zodd_not_Zeven; red; auto.
intros p; case p; clear p.
intros HH; contradict HH.
apply not_prime_0.
2: intros p (V1, _); contradict V1; apply Zle_not_lt; red; simpl; intros;
     discriminate.
intros p Hprime Hdec; exists (Zpos a);repeat split; auto with zarith.
apply trans_equal with (2 := If6).
rewrite H5.
rewrite pow_mod_pred_spec with (2 := m_spec); auto with zarith.
rewrite F1.
rewrite m_spec.(power_mod_spec) with (t := a); auto with zarith.
rewrite F1; rewrite F4.
rewrite <- Zmod_Zpower; auto with zarith.
rewrite <- Zpower_mult; auto with zarith.
rewrite mkProd_pred_mkProd; auto with zarith.
rewrite U1; rewrite Zmult_comm.
rewrite Zpower_mult; auto with zarith.
rewrite <- Zmod_Zpower; auto with zarith.
rewrite F1; rewrite F4; rewrite Zmod_def_small; auto with zarith.
rewrite Zmod_def_small; auto with zarith.
rewrite m_spec.(power_mod_spec) with (t := a); auto with zarith.
match goal with |- context[?X mod ?Y] =>
  case (Z_mod_lt X Y); auto with zarith
end.
rewrite F1; rewrite F4; rewrite Zmod_def_small; auto with zarith.
rewrite pow_mod_pred_spec with (2 := m_spec); auto with zarith.
match goal with |- context[?X mod ?Y] =>
  case (Z_mod_lt X Y); auto with zarith
end.
rewrite Zmod_def_small; auto with zarith.
rewrite m_spec.(power_mod_spec) with (t := a); auto with zarith.
match goal with |- context[?X mod ?Y] =>
  case (Z_mod_lt X Y); auto with zarith
end.
rewrite F1; rewrite F4; rewrite Zmod_def_small; auto with zarith.
match type of H6 with _ -> _ -> ?X =>
  assert (tmp: X); [apply H6 | clear H6; rename tmp into H6];
  auto with zarith
end.
rewrite F1.
rewrite F5; rewrite Zmod_def_small; auto with zarith.
rewrite pow_mod_pred_spec with (2 := m_spec); auto with zarith.
repeat (rewrite F1 || rewrite F4).
rewrite m_spec.(power_mod_spec) with (t := a); auto with zarith.
repeat (rewrite F1 || rewrite F4).
rewrite Zpos_mult; rewrite <- Zmod_Zpower; auto with zarith.
rewrite Zpower_mult; auto with zarith.
repeat (rewrite F1 || rewrite F4).
rewrite Zmod_def_small; auto with zarith.
rewrite Zmod_def_small; auto with zarith.
rewrite m_spec.(power_mod_spec) with (t := a); auto with zarith.
match goal with |- context[?X mod ?Y] =>
  case (Z_mod_lt X Y); auto with zarith
end.
repeat (rewrite F1 || rewrite F4).
rewrite Zmod_def_small; auto with zarith.
rewrite F5 in H6; rewrite F1 in H6; rewrite F4 in H6.
case in_mkProd_prime_div_in with (3 := Hdec); auto.
intros p1 Hp1.
rewrite <- F6 in H6.
apply Zis_gcd_gcd; auto with zarith.
change (rel_prime (a ^ ((N - 1) / p) - 1) N).
match type of H6 with _ = ?X mod _ =>
  apply rel_prime_div with (p := X); auto with zarith
end.
apply rel_prime_mod_rev; auto with zarith.
red.
pattern 1 at 4; rewrite <- If7; rewrite <- H6.
pattern N at 2; rewrite <- F1.
apply spec_gcd; auto with zarith.
assert (foldtmp: forall (A B: Set) (f: A -> B -> A) (P: A -> Prop) l a b,
  In b l -> (forall x, P (f x b)) ->
  (forall x y, P x -> P (f x y)) ->
  P (fold_left f l a)).
assert (foldtmp0: forall (A B: Set) (f: A -> B -> A) (P: A -> Prop) l a,
  P a ->
  (forall x y, P x -> P (f x y)) ->
  P (fold_left f l a)).
intros A B f P l; elim l; simpl; auto.
intros A B f P l; elim l; simpl; auto.
intros a1 b HH; case HH.
intros a1 l1 Rec a2 b [V|V] V1 V2; subst; auto.
apply foldtmp0; auto.
apply Rec with (b := b); auto with zarith.
match goal with |- context [fold_left ?f _ _] =>
 apply (foldtmp _ _ f (fun k => (a ^ ((N - 1) / p) - 1 | k))) 
   with (b := (p, p1)); auto with zarith
end.
rewrite <- HH2.
clear F0; match goal with H: ?X < ?Y |- ?X < ?Z =>
 replace Z with Y; auto
end.
repeat (rewrite Zpos_plus || rewrite Zpos_mult || rewrite times_Zmult).
rewrite Zpos_xO; ring.
rewrite <- HH1; rewrite <- HH2.
apply check_s_r_correct with sqrt; auto.
Qed.


Fixpoint test_Certif (lc : Certif) : bool :=
  match lc with
  | nil => true
  | (Proof_certif _ _) :: lc => test_Certif lc
  | (Lucas_certif n p) :: lc =>
     if test_Certif lc then
     if gt2 p then
       match p with 
         Zpos p1 => 
           match Mp p with
          | Zpos n' =>
             if (n ?= n')%P then 
               match lucas p1 with
               | Z0 => true
               | _ => false
               end
             else false
           | _ => false
           end
         | _ => false
       end
    else false 
    else false
  | (Pock_certif n a dec sqrt) :: lc =>
    if test_pock n a dec sqrt then 
     if all_in lc dec then test_Certif lc else false
    else false
  end.

Lemma test_Certif_In_Prime : 
  forall lc, test_Certif lc = true -> 
   forall c, In c lc -> prime (nprim c).
intros lc; elim lc; simpl; auto.
intros _ c H; case H.
intros a; case a; simpl; clear a lc.
intros N p l Rec H c [H1 | H1]; subst; auto with arith.
intros n p l; case (test_Certif l); auto with zarith.
2: intros; discriminate.
intros H H1 c [H2 | H2]; subst; auto with arith.
simpl nprim.
generalize H1; clear H1.
case_eq (gt2 p).
2: intros; discriminate.
case p; clear p; try (intros; discriminate; fail).
unfold gt2; intros p H1.
match goal with H: (?X ?< ?Y) = true |- _ =>
  generalize (is_lt_spec X Y); rewrite H; clear H; intros H
end.
unfold Mp; case_eq (2 ^ p  -1); try (intros; discriminate; fail).
intros p1 Hp1.
case_eq (n ?= p1)%P; try rewrite <- Hp1.
2: intros; discriminate.
intros H2.
match goal with H: (?X ?= ?Y)%P = true |- _ =>
  generalize (is_eq_eq _ _ H); clear H; intros H
end.
generalize (lucas_prime H1); rewrite Hp1; rewrite <- H2.
case (lucas p); try (intros; discriminate; fail); auto.
intros N a d p l H.
generalize (test_pock_correct N a d p).
case (test_pock N a d p); auto.
2: intros; discriminate.
generalize (all_in_In l d).
case (all_in l d).
2: intros; discriminate.
intros H1 H2 H3 c [H4 | H4]; subst; simpl; auto.
apply H2; auto.
intros k Hk.
case H1 with (2 := Hk); auto.
intros x (Hx1, Hx2); rewrite Hx2; auto.
Qed.
