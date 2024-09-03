use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Credential, VerificationKey}
use cardano/assets.{Lovelace}
use cardano/transaction.{Transaction} as tx

pub type SignatureConfig {
  signers: List<Credential>,
  requiredSigners: Int,
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
  signature_datum: SignatureConfig,
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

validator multisig_withdraw(signatures: SignatureConfig) {
  withdraw(_r: Data, _c: Data, tx: Transaction) {
    enough_signatures(signatures, tx.withdrawals, tx.extra_signatories)
  }

  else(_) {
    fail
  }
}
