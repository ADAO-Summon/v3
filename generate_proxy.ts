import { AssetId, Address, AssetName, CborSet, Credential, ConstrPlutusData, PlutusList, PlutusMap, NativeScript, Ed25519KeyHashHex, PlutusData, PlutusV2Script, PolicyId, Value, Transaction, TransactionId, toHex, fromHex, addressFromValidator } from "@blaze-cardano/core";
import {
    Blockfrost,
    // Value,
    Blaze,
    HotWallet,
    Data,
    Core,
} from "@blaze-cardano/sdk";

// We will use a basic native script for our NFT.

const onMainnet = false;

/**
   * This method submits a transaction to the chain.
   * @param tx - The Transaction
   * @returns A Promise that resolves to a TransactionId type
   */
const postTransactionToChain = async (url, project, tx: Transaction): Promise<string> => {
    const query = "/tx/submit";
    console.log(tx.toCbor());
    const response = await fetch(`${url}${query}`, {
        method: "POST",
        headers: {
            "Content-Type": "application/cbor",
            Accept: "application/json",
            project_id: project,
        },
        body: fromHex(tx.toCbor()),
    });

    if (!response.ok) {
        const error = await response.text();
        throw new Error(
            `postTransactionToChain: failed to submit transaction to Blockfrost endpoint.\nError ${error}`,
        );
    }

    const txId = await response.text();
    return txId;
}

const projectId = "preprodIjLYQeC1WBN9oLyk88Q40FUrBO8BePXn" // Your Blockfrost project ID
if (!projectId) {
    throw new Error("Missing blockfrost key");
}

const provider = new Blockfrost({
    network: onMainnet ? "cardano-mainnet" : "cardano-preprod",
    projectId,
});

let mnemonic = "usual situate jungle enable reduce pattern sentence adapt help indoor iron bird" // Your seed phrase.
const entropy = Core.mnemonicToEntropy(mnemonic, Core.wordlist);
const masterkey = Core.Bip32PrivateKey.fromBip39Entropy(Buffer.from(entropy), "");

const wallet = await HotWallet.fromMasterkey(masterkey.hex(), provider);
const blaze = await Blaze.from(provider, wallet);

const address = wallet.address;
const cred = address.getProps().paymentPart;
console.log(address.toBech32());

// TODO - Create the NativeScript here.

const policy = NativeScript
const policyId = "" // policy.hash()
const name = "control"

const tokenMap = new Map<AssetId, bigint>();
const rtokenMap = new Map<AssetId, bigint>();
const encoder = new TextEncoder();
const uint8name = encoder.encode(name);
const assetId: AssetId = AssetId(policyId.toString() + toHex(uint8name))
const refAssetId: AssetId = AssetId(policyId.toString() + toHex(uint8name))
rtokenMap.set(refAssetId, 1n)
const mintMap = new Map<AssetName, bigint>();
mintMap.set(AssetName(toHex(uint8name)), 1n);

const lockerAddress = addressFromValidator(onMainnet ? 1 : 0, policy);
console.log(lockerAddress.toBech32());

// Assumes that the wallet contains at least 5 ADA + tx fees.
const tx = await blaze
    .newTransaction()
    .lockAssets(lockerAddress, new Value(5_000_000n, rtokenMap), PlutusData.newConstrPlutusData(new ConstrPlutusData(0n, new PlutusList()))) // Fix
    .payAssets(address, new Value(5_000_000n, tokenMap))
    .addMint(PolicyId(policyId), mintMap, Data.to("Minting", {})) // TODO fix 
    .addRequiredSigner(Ed25519KeyHashHex(cred!.hash))
    .provideScript(policy)
    .complete();

console.log("Balanced and unwitnessed transaction CBOR:");
console.log(tx.toCbor() + "\n");

const signed = await blaze.signTransaction(tx);

console.log("Signed transaction CBOR:");
console.log(signed.toCbor() + "\n");
console.log(Core.fromHex(signed.toCbor()));

const txId = await postTransactionToChain(blaze.provider.url, blaze.provider.headers().project_id, signed);

console.log(
    `Transaction with ID ${txId} has been successfully submitted to the blockchain.`,
);