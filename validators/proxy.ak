use aiken/collection/list
use aiken/collection/pairs
use cardano/assets.{PolicyId}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Input, OutputReference, Transaction} as tx
use common/utils.{ProxyDatum}

validator one_shot(mint_ref: OutputReference) {
  mint(_r: Data, _p: PolicyId, tx: Transaction) {
    let Transaction { inputs, .. } = tx
    // Ensure mint_ref is spent.
    list.find(inputs, fn(i) { i.output_reference == mint_ref }) != None
  }

  else(_) {
    fail
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
    expect proxy_datum: ProxyDatum =
      utils.get_inline_data(control_input.output.datum)
    pairs.has_key(withdrawals, proxy_datum.credential)
  }
}
