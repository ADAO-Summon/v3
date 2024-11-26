use aiken/builtin
use aiken/collection/list
use aiken/collection/pairs
use aiken/fuzz.{and_then, bool, bytearray, constant, map, such_that}
use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/gen_address.{any_credential}
use cardano/gen_assets.{any_policy_id}
use cardano/gen_script_context.{constrained_script_context}
use cardano/gen_transaction.{
  add_fuzz_input, add_fuzz_output, add_fuzz_ref_input, add_fuzz_withdrawals,
  any_constrained_input, any_constrained_output, any_generic_tx,
}
use cardano/script_context.{Minting, ScriptContext}
use cardano/transaction.{Datum, InlineDatum, Input, Transaction} as tx

type ProxyDatum {
  credential: Credential,
  additional: Option<Data>,
}

fn get_inline_data(datum: Datum) -> Data {
  when datum is {
    InlineDatum(d) -> d
    _ -> fail
  }
}

validator proxy(nft_policy: PolicyId) {
  else(ctx: ScriptContext) {
    let Transaction { reference_inputs, inputs, withdrawals, .. } =
      ctx.transaction
    let maybe_ref =
      list.find(
        reference_inputs,
        fn(i) { assets.quantity_of(i.output.value, nft_policy, "control") == 1 },
      )
    let control_input =
      when maybe_ref is {
        Some(ref_input) -> ref_input
        None -> {
          expect Some(input) =
            list.find(
              inputs,
              fn(i) {
                assets.quantity_of(i.output.value, nft_policy, "control") == 1
              },
            )
          input
        }
      }
    expect proxy_datum: ProxyDatum = get_inline_data(control_input.output.datum)
    pairs.has_key(withdrawals, proxy_datum.credential)
  }
}

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
  proxy.else(p, c)
}

test failing_test(ctx via gen_failing_ctx()) fail {
  let (p, c) = ctx
  proxy.else(p, c)
}

type TargetState {
  nonce: ByteArray,
  miner: ByteArray,
  block_number: Int,
  current_hash: ByteArray,
  leading_zeros: Int,
  target_number: Int,
  epoch_time: Int,
}

fn p(t: TargetState) {
  let proxy_inputs =
    when
      filter_inputs_by_credential(ctx.transaction.inputs, proxy_credential)
    is {
      [] -> fail @"Insufficient Proxy Inputs"
      x -> x
    }
  proxy_inputs
}
