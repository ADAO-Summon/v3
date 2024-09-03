use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto.{Blake2b_224, Hash, Script, VerificationKeyHash}
use cardano/address.{Address, Credential, Inline, VerificationKey}
use cardano/assets.{Lovelace, PolicyId}
use cardano/certificate
use cardano/governance.{ConstitutionalCommitteeMember, DelegateRepresentative}
use cardano/script_context.{
  Proposing, Publishing, ScriptContext, Voting, Withdrawing,
}
use cardano/transaction.{Datum, InlineDatum, OutputReference, Transaction} as tx

pub type SignatureDatum {
  signers: List<Credential>,
  requiredSigners: Int,
}

fn get_inline_data(datum: Datum) -> Data {
  when datum is {
    InlineDatum(d) -> d
    _ -> fail
  }
}

// Check that either the staking pubkey signed or the staking script was executed.
fn staking_credential_approves(
  staking_cred: Credential,
  withdrawals: Pairs<Credential, Int>,
  extra_signatories: List<VerificationKeyHash>,
) -> Bool {
  when staking_cred is {
    VerificationKey(skey) -> list.has(extra_signatories, skey)
    svh -> pairs.has_key(withdrawals, svh)
  }
}

fn enough_signatures(
  signature_datum: SignatureDatum,
  withdrawals: Pairs<Credential, Lovelace>,
  extra_signatories: List<VerificationKeyHash>,
) -> Bool {
  signature_datum.requiredSigners <= list.foldl(
    signature_datum.signers,
    0,
    fn(s, x) {
      if staking_credential_approves(s, withdrawals, extra_signatories) {
        x + 1
      } else {
        x
      }
    },
  )
}

fn our_policy(ctx: ScriptContext) -> PolicyId {
  when ctx.info is {
    Withdrawing(credential) ->
      when credential is {
        address.Script(addr_script_hash) -> addr_script_hash
        _ -> fail
      }
    Publishing(_at, certificate) ->
      when certificate is {
        certificate.RegisterCredential(credential, _) | certificate.UnregisterCredential(
          credential,
          _,
        ) | certificate.DelegateCredential(credential, _) | certificate.RegisterAndDelegateCredential(
          credential,
          _,
          _,
        ) | certificate.RegisterDelegateRepresentative(credential, _) | certificate.UpdateDelegateRepresentative(
          credential,
        ) | certificate.UnregisterDelegateRepresentative(credential, _) | certificate.AuthorizeConstitutionalCommitteeProxy(
          credential,
          _,
        ) | certificate.RetireFromConstitutionalCommittee(credential) ->
          when credential is {
            address.Script(addr_script_hash) -> addr_script_hash
            _ -> fail
          }

        certificate.RegisterStakePool(_, _) -> fail
        certificate.RetireStakePool(_, _) -> fail
      }
    Voting(voter) ->
      when voter is {
        ConstitutionalCommitteeMember(credential) | DelegateRepresentative(
          credential,
        ) ->
          when credential is {
            address.Script(addr_script_hash) -> addr_script_hash
            _ -> fail
          }
        _ -> fail
      }
    Proposing(_at, proposal_procedure) ->
      when proposal_procedure.return_address is {
        address.Script(addr_script_hash) -> addr_script_hash
        _ -> fail
      }
    _ -> fail
  }
}

fn our_address(script: Hash<Blake2b_224, Script>) -> Address {
  Address(address.Script(script), Some(Inline(address.Script(script))))
}

validator multisig(mint_ref: OutputReference) {
  // Minting should be a one-shot policy.
  // Name should be enforced.
  mint(_rdmr: Data, policy_id: PolicyId, tx: Transaction) {
    let Transaction { inputs, mint, outputs, .. } = tx
    // Ensure mint_ref is spent.
    expect Some(_) = list.find(inputs, fn(i) { i.output_reference == mint_ref })
    expect Some(control_output) =
      list.find(
        outputs,
        fn(o) { assets.quantity_of(o.value, policy_id, "control") == 1 },
      )
    // Ensure that Datum is properly formatted.
    expect _check_output_datum: SignatureDatum =
      get_inline_data(control_output.datum)
    // Ensure that control-NFT goes to our script and that the mint only contains the control-NFT.
    control_output.address == our_address(policy_id) && mint == assets.from_asset(
      policy_id,
      "control",
      1,
    )
  }

  // Spending requires that the signatures/withdrawals are present.
  // IN ADDITION TO: ensuring the control-NFT goes back to the contract.
  // Spending is not optimized with the consideration it will primarily be used
  //  to update the signatures required.
  spend(_d: Option<Data>, _r: Data, spent_ref: OutputReference, tx: Transaction) {
    let Transaction { inputs, outputs, withdrawals, extra_signatories, .. } = tx
    expect Some(spent_input) =
      list.find(inputs, fn(i) { i.output_reference == spent_ref })
    let policy_id =
      when spent_input.output.address.payment_credential is {
        address.Script(addr_script_hash) -> addr_script_hash
        VerificationKey(_) -> fail
      }
    expect Some(control_input) =
      list.find(
        inputs,
        fn(i) { assets.quantity_of(i.output.value, policy_id, "control") == 1 },
      )
    expect signature_datum: SignatureDatum =
      get_inline_data(control_input.output.datum)
    expect Some(control_output) =
      list.find(
        outputs,
        fn(o) { assets.quantity_of(o.value, policy_id, "control") == 1 },
      )
    expect _check_output_datum: SignatureDatum =
      get_inline_data(control_output.datum)
    control_input.output.address == control_output.address && enough_signatures(
      signature_datum,
      withdrawals,
      extra_signatories,
    )
  }

  else(ctx: ScriptContext) {
    // Get our policy_id.
    let policy_id: PolicyId = our_policy(ctx)
    let Transaction { reference_inputs, withdrawals, extra_signatories, .. } =
      ctx.transaction
    // Find the reference input with the control-NFT.
    expect Some(ref_input) =
      list.find(
        reference_inputs,
        fn(i) { assets.quantity_of(i.output.value, policy_id, "control") == 1 },
      )
    expect signature_datum: SignatureDatum =
      get_inline_data(ref_input.output.datum)
    // Ensure that we have enough signatures present.
    enough_signatures(signature_datum, withdrawals, extra_signatories)
  }
}
