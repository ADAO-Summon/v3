use cardano/assets.{PolicyId}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Transaction} as tx
use common/utils.{proxy_check}

validator proxy_mint(nft_policy: PolicyId) {
  mint(_r: Data, _p: Data, ctx: ScriptContext) {
    let Transaction { reference_inputs, inputs, withdrawals, .. } =
      ctx.transaction
    proxy_check(nft_policy, reference_inputs, inputs, withdrawals)
  }

  else(_) {
    fail
  }
}
