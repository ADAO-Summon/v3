use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Datum, InlineDatum, OutputReference, Transaction} as tx

fn get_inline_data(datum: Datum) -> Data {
  when datum is {
    InlineDatum(d) -> d
    _ -> fail
  }
}

validator one_shot(mint_ref: OutputReference) {
  mint(_r: Data, policy_id: PolicyId, tx: Transaction) {
    let Transaction { inputs, mint, .. } = tx
    // Ensure mint_ref is spent.
    expect Some(_) = list.find(inputs, fn(i) { i.output_reference == mint_ref })
    mint == assets.from_asset(policy_id, "control", 1)
  }

  else(_) {
    fail
  }
}

validator proxy(nft_policy: PolicyId) {
  else(ctx: ScriptContext) {
    let Transaction { reference_inputs, inputs, withdrawals, .. } =
      ctx.transaction
    // Find the reference input with the control-NFT.
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
    expect svh: Credential = get_inline_data(control_input.output.datum)
    pairs.has_key(withdrawals, svh)
  }
}
