// ### THIS DOESN'T WORK AS BLAZE ISN'T UPDATED FOR PLUTUSV3 YET

// import { AssetId, Address, AssetName, CborSet, Credential, ConstrPlutusData, PlutusList, PlutusMap, NativeScript, Ed25519KeyHashHex, PlutusData, PlutusV2Script, PolicyId, Value, Transaction, TransactionId, toHex, fromHex, addressFromValidator } from "@blaze-cardano/core";
// import {
// Blockfrost,
// // Value,
// Blaze,
// HotWallet,
// Data,
// Core,
// } from "@blaze-cardano/sdk";
// // import { crc8 } from "./crc8.ts";

// import { MultisigDrepMultisig } from "./plutus.ts"

// const onMainnet = true;

// /**
// * This method submits a transaction to the chain.
// * @param tx - The Transaction
// * @returns A Promise that resolves to a TransactionId type
// */
// const postTransactionToChain = async (url, project, tx: Transaction): Promise<string> => {
// const query = "/tx/submit";
// console.log(tx.toCbor());
// const response = await fetch(`${url}${query}`, {
// method: "POST",
// headers: {
// "Content-Type": "application/cbor",
// Accept: "application/json",
// project_id: project,
// },
// body: fromHex(tx.toCbor()),
// });

// if (!response.ok) {
// const error = await response.text();
// throw new Error(
// `postTransactionToChain: failed to submit transaction to Blockfrost endpoint.\nError ${error}`,
// );
// }

// const txId = await response.text();
// return txId;
// }

// // const projectId = "preprodIjLYQeC1WBN9oLyk88Q40FUrBO8BePXn" // Your Blockfrost project ID
// const projectId = "mainnetrUAUmHUUTKXvyyWl6ksq8lRjX1iJod9D"
// if (!projectId) {
// throw new Error("Missing blockfrost key");
// }

// console.log(onMainnet)

// const provider = new Blockfrost({
// network: onMainnet ? "cardano-mainnet" : "cardano-preprod",
// projectId,
// });

// console.log(provider.url)

// let mnemonic = "usual situate jungle enable reduce pattern sentence adapt help indoor iron bird" // Your seed phrase.
// const entropy = Core.mnemonicToEntropy(mnemonic, Core.wordlist);
// const masterkey = Core.Bip32PrivateKey.fromBip39Entropy(Buffer.from(entropy), "");

// const wallet = await HotWallet.fromMasterkey(masterkey.hex(), provider, onMainnet ? 1 : 0);
// const blaze = await Blaze.from(provider, wallet);

// const address = wallet.address;
// const cred = address.getProps().paymentPart;
// console.log(address.toBech32());

// const utxo = (await wallet.getUnspentOutputs())[0]

// const policy = new MultisigDrepMultisig({ transactionId: utxo.input().transactionId(), outputIndex: utxo.input().index() })
// const policyId = policy.hash()

// // const tokenMap = new Map<AssetId, bigint>();
// const rtokenMap = new Map<AssetId, bigint>();
// const encoder = new TextEncoder();
// const uint8name = encoder.encode("control");
// const refAssetId: AssetId = AssetId(policyId.toString() + toHex(uint8name))
// rtokenMap.set(refAssetId, 1n)
// const mintMap = new Map<AssetName, bigint>();
// mintMap.set(AssetName(toHex(uint8name)), 1n);

// const multisigAddress = addressFromValidator(onMainnet ? 1 : 0, policy);
// console.log(multisigAddress.toBech32());

// const signatory: ({ VerificationKey: [string]; } | { Script: [string]; })[] = [address.toBech32()].map((e) => {
// return ({ VerificationKey: [Address.fromBech32(e).getProps().delegationPart!.hash.toString()] })
// })

// // Assumes that the wallet contains at least 5 ADA + tx fees.
// const txU = blaze
// .newTransaction()
// .addInput(utxo)
// .lockAssets(
// multisigAddress,
// new Value(5_000_000n, rtokenMap),
// Data.to({
// signers: signatory,
// requiredsigners: 1n
// },
// MultisigDrepMultisig.datu))
// .addMint(PolicyId(policyId), mintMap, Data.Void())
// .provideScript(policy)

// console.log("About to complete..")

// const tx = await txU.complete();

// console.log("Balanced and unwitnessed transaction CBOR:");
// console.log(tx.toCbor() + "\n");

// const signed = await blaze.signTransaction(tx);

// console.log("Signed transaction CBOR:");
// console.log(signed.toCbor() + "\n");
// console.log(Core.fromHex(signed.toCbor()));

// const txId = await postTransactionToChain(blaze.provider.url, blaze.provider.headers().project_id, signed);

// console.log(
// `Transaction with ID ${txId} has been successfully submitted to the blockchain.`,
// );

// const addressList = [
// "addr1q8utcf6x4tkvszqwkv46nqerpjc6d86e9xe7z59nnkfzzm5u267q5v8emt0ltmneqyfd3a82ucep6v5n08tky85pvarqq8emrr",
// "addr1q8s5ajepekp5ez3w0q39utqj785e92yg62hkq7852cs2zgutfj7f328f3qcetchaws8ye4tltf44t5qkuplkq8gjxvyqnef20s",
// "addr1qyezx0dd2hjqzjz5aqt42m25rxcg7nrazsr74e4efx965vqlz06cm8smncyg940wft8lna86pcmhp39080e24ykq8tnqynlzm2",
// "addr1qyddj7raf590x5lhfrdk5qp5mvte8u3mtzrw360n4kd0tnmsr2gskfskqekznt6awshlppcax8fw894ng33m8ljh95kqx6ergc",
// "addr1qyyuf3ua0e2sjas9egqjqvza6ut3jyn0kxr3e5l2upeuasgsfm9826q0pkhau2kf6nuj0065dgejfen0kk6t7cg0d9yqedh07y"
// ]

// console.log('addressList', addressList)

// const signatories: ({ VerificationKey: [string]; } | { Script: [string]; })[] = addressList.map((e) => {
// return ({ VerificationKey: [Address.fromBech32(e).getProps().delegationPart!.hash.toString()] })
// })

// console.log('signatories', signatories)

// const refUtxo = provider.getUnspentOutputsWithAsset(multisigAddress, AssetId(PolicyId(policyId) + uint8name))

// const txRegister = blaze
// .newTransaction()
// .addReferenceInput(refUtxo[0])
// .
// .provideScript(policy)