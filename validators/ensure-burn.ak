use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction} as tx
use common/utils.{get_inline_data}

pub type Action {
  Using
  Updating
}

// This is the Proxy ControlDatum but we are able to use Additional however we like.
pub type ControlDatum {
  credential: Credential,
  additional: Option<Additional>,
}

type Additional =
  Data

validator ensure_burn_simple(policy_id: PolicyId) {
  withdraw(_r: Data, _c: Data, tx: Transaction) {
    let tokens = assets.tokens(tx.mint, policy_id)
    list.all(dict.values(tokens), fn(x) { x < 0 }) && !dict.is_empty(tokens)
  }

  else(_) {
    fail
  }
}

// In this example, the control_id is supposed to be the Policy used to control the proxy.
validator update_via_burn(control_id: PolicyId, burn_id: PolicyId) {
  withdraw(r: Action, _c: Data, tx: Transaction) {
    when r is {
      Using -> {
        expect Some(ref_input) =
          list.find(
            tx.reference_inputs,
            fn(i) {
              assets.quantity_of(i.output.value, control_id, "control") == 1
            },
          )
        expect x: ControlDatum = get_inline_data(ref_input.output.datum)
        // TODO - Put your protocol logic here.
        x != x
      }
      Updating -> {
        let tokens = assets.tokens(tx.mint, burn_id)
        expect Some(_input) =
          list.find(
            tx.inputs,
            fn(i) {
              assets.quantity_of(i.output.value, control_id, "control") == 1
            },
          )
        list.all(dict.values(tokens), fn(x) { x < 0 }) && !dict.is_empty(tokens)
      }
    }
  }

  else(_) {
    fail
  }
}
