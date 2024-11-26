use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Credential}
use cardano/assets.{Lovelace}
use cardano/transaction.{Transaction} as tx
use common/utils.{staking_credential_approves}

pub type SignatureConfig {
  signers: List<Credential>,
  required_signers: Int,
}

fn enough_signatures(
  signature_datum: SignatureConfig,
  withdrawals: Pairs<Credential, Lovelace>,
  extra_signatories: List<VerificationKeyHash>,
) -> Bool {
  signature_datum.required_signers <= list.foldl(
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
