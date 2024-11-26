use aiken/collection/dict
use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto.{VerificationKeyHash}
use aiken/fuzz
use aiken/interval
use cardano/address.{Credential, VerificationKey}
use cardano/assets.{Lovelace, PolicyId}
use cardano/gen_transaction
use cardano/transaction.{Datum, InlineDatum, Input, Transaction}

pub type ProxyDatum {
  credential: Credential,
  additional: Option<Data>,
}

// Check that either the staking pubkey signed or the staking script was executed.
pub fn staking_credential_approves(
  owner: Credential,
  withdrawals: Pairs<Credential, Int>,
  extra_signatories: List<VerificationKeyHash>,
) -> Bool {
  when owner is {
    VerificationKey(owner) -> list.has(extra_signatories, owner)
    svh -> pairs.has_key(withdrawals, svh)
  }
}

pub fn get_inline_data(datum: Datum) -> Data {
  when datum is {
    InlineDatum(d) -> d
    _ -> fail
  }
}

pub fn proxy_check(
  control_policy: PolicyId,
  reference_inputs: List<Input>,
  inputs: List<Input>,
  withdrawals: Pairs<Credential, Lovelace>,
) {
  let maybe_ref =
    list.find(
      reference_inputs,
      fn(i) {
        assets.quantity_of(i.output.value, control_policy, "control") == 1
      },
    )
  let control_input =
    when maybe_ref is {
      Some(ref_input) -> ref_input
      None -> {
        expect Some(input) =
          list.find(
            inputs,
            fn(i) {
              assets.quantity_of(i.output.value, control_policy, "control") == 1
            },
          )
        input
      }
    }
  expect proxy_datum: ProxyDatum = get_inline_data(control_input.output.datum)
  pairs.has_key(withdrawals, proxy_datum.credential)
}

// This should be upstreamed.
pub fn base_tx() -> Transaction {
  Transaction(
    [],
    [],
    [],
    0,
    assets.zero,
    [],
    [],
    interval.empty,
    [],
    [],
    dict.empty,
    #"",
    [],
    [],
    None,
    None,
  )
}

// Upstream this
pub fn any_generic_tx() -> Fuzzer<Transaction> {
  let tx = base_tx()
  let tx <-
    fuzz.and_then(
      gen_transaction.add_fuzz_inputs(
        tx,
        fuzz.list(gen_transaction.any_input()),
      ),
    )
  gen_transaction.add_fuzz_outputs(tx, fuzz.list(gen_transaction.any_output()))
}
