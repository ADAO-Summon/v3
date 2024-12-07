use aiken/builtin
use aiken/fuzz.{and_then, bool, bytearray, constant, map, such_that}
use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/fuzz/address.{any_credential} as gen_address
use cardano/fuzz/assets.{any_policy_id} as gen_assets
use cardano/fuzz/script_context.{constrained_script_context} as gen_script_context
use cardano/fuzz/transaction.{
  add_fuzz_input, add_fuzz_output, add_fuzz_ref_input, add_fuzz_withdrawals,
  any_constrained_input, any_constrained_output,
} as gen_transaction
use cardano/script_context.{Minting, ScriptContext}
use cardano/transaction.{Datum, InlineDatum, Transaction}
use common/utils.{ProxyDatum, any_generic_tx}
use proxy

pub fn proxy_datum_fuzzer(c: Credential, b) -> Fuzzer<Datum> {
  fuzz.map3(
    bool(),
    bytearray(),
    such_that(gen_address.any_credential(), fn(c2) { c != c2 }),
    fn(coin_flip, potential_bytes, alt_cred) {
      let additional =
        if coin_flip {
          Some(builtin.b_data(potential_bytes))
        } else {
          None
        }
      let cred =
        if b {
          c
        } else {
          alt_cred
        }
      InlineDatum(ProxyDatum(cred, additional))
    },
  )
}

fn gen_passing_tx(policy) -> Fuzzer<Transaction> {
  let cred <- and_then(any_credential())
  let tx <- and_then(any_generic_tx())
  // Define constraints for our control input.
  let constraints = [Pair(policy, [Pair("control", Pair(1, 1))])]

  let tx <- and_then(add_fuzz_withdrawals(tx, constant([Pair(cred, 0)])))
  // Add withdrawal of credential
  let c_in = any_constrained_input(constraints, proxy_datum_fuzzer(cred, True))
  let ref_tx <- and_then(add_fuzz_ref_input(tx, c_in))
  let s_tx <- and_then(add_fuzz_input(tx, c_in))
  let f_tx <-
    and_then(
      add_fuzz_output(
        s_tx,
        any_constrained_output(constraints, proxy_datum_fuzzer(cred, True)),
      ),
    )
  map(
    bool(),
    fn(ref_control) {
      if ref_control {
        ref_tx
      } else {
        f_tx
      }
    },
  )
}

fn gen_passing_ctx() -> Fuzzer<(PolicyId, ScriptContext)> {
  let policy <- and_then(any_policy_id())
  map(
    constrained_script_context(
      gen_passing_tx(policy),
      constant(builtin.b_data(#"")),
      constant(Minting(policy)),
    ),
    fn(c) { (policy, c) },
  )
}

fn gen_failing_ctx() -> Fuzzer<(PolicyId, ScriptContext)> {
  let policy <- and_then(any_policy_id())
  map(
    constrained_script_context(
      any_generic_tx(),
      constant(builtin.b_data(#"")),
      constant(Minting(policy)),
    ),
    fn(c) { (policy, c) },
  )
}

test passing_test(ctx via gen_passing_ctx()) {
  let (p, c) = ctx
  proxy.proxy.else(p, c)
}

test failing_test(ctx via gen_failing_ctx()) fail {
  let (p, c) = ctx
  proxy.proxy.else(p, c)
}

fn gen_scaled_constant() -> ScaledFuzzer<Int> {
  let x: ScaledFuzzer<Int> = fuzz.scaled_constant(100)
  x
}

test scaled_test(ctx via gen_scaled_constant()) {
  True
}