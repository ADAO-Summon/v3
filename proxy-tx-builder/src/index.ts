import { CML, Lucid, Blockfrost, applyParamsToScript, Data, Constr, mintingPolicyToId, Script, paymentCredentialOf, validatorToRewardAddress, CertificateValidator, credentialToRewardAddress, applyDoubleCborEncoding, validatorToAddress, scriptHashToCredential, validatorToScriptHash } from '@lucid-evolution/lucid';

const lucid = await Lucid(
    new Blockfrost("https://cardano-mainnet.blockfrost.io/api/v0", "mainnetrUAUmHUUTKXvyyWl6ksq8lRjX1iJod9D"),
    "Mainnet"
);


lucid.selectWallet.fromSeed("nature sense pumpkin error unlock split skate hazard sting undo cave patch excuse awkward another oyster evil wave check deliver treat cement visa bounce")
console.log(await lucid.wallet().address())

const paymentCred = paymentCredentialOf(await lucid.wallet().address())

const initialUTxOs = await lucid.wallet().getUtxos()
console.log(initialUTxOs)


let paramUtxo = initialUTxOs[0]
const txHash: Data = paramUtxo.txHash
const out: Data = BigInt(paramUtxo.outputIndex)
const paramFromUtxo: Data = new Constr(0, [txHash, out])
console.log(Data.to(paramFromUtxo))

const mintingPolicy: Script = {
    type: "PlutusV3",
    script: applyParamsToScript(
        applyDoubleCborEncoding("5901ec01010032323232323232225333003323232323253330083370e900018049baa0011323232533300b3370e900018061baa32330010013758602200644a666020002298103d87a800013232533300f3375e602860226ea80080384cdd2a40006602600497ae01330040040013014002301200113375e6e98004dd32999805a5014bd6f7b6300991919800800a5eb7bdb180894ccc0440044cc048cdd81ba9006374c00697adef6c6013232323253330123372001400426602c66ec0dd48051ba6007005153330123371e01400426602c66ec0dd48051ba6007003133016337606ea4008dd3000998030030019bab3013003375c6022004602a0046026002646600200297adef6c60225333010001133011337609810847636f6e74726f6c004c010101004bd6f7b630099191919299980899b9048907636f6e74726f6c000021330153376098010847636f6e74726f6c004c01010100005153330113371e910107636f6e74726f6c000021330153376098010847636f6e74726f6c004c01010100003133015337606ea4008dd4000998030030019bad3012003375c6020004602800460240022c6eacc03cc040c040c040c040004c02cdd50029bae300d300a37540022c6018601a004601600260160046012002600a6ea8004526136565734aae7555cf2ab9f5740ae855d101"),
        [paramFromUtxo]
    ),
};
const policyId = "ac753df1f8942a680b324da3a61be3db45807e663d4af893d1feb90f" // mintingPolicyToId(mintingPolicy)
const proxyScript: Script = {
    type: "PlutusV3",
    script: applyParamsToScript(
        applyDoubleCborEncoding("5903150101003232323232323223225333004323232323232323233332323232322223232325333017300230183754002264646464a66603c604200426464a66603a601000226464a666044604a0042a0082c6eb8c08c004c07cdd50028a99980e980780089919299981118128010a8020b1bae3023001301f375400a2c603a6ea80104c8c94ccc074c0200044c8c94ccc088c0940085401058c08c004c07cdd50018a99980e98078008a999810180f9baa003150021616301d3754004264646600200201444a66604200229404c94ccc07ccdd7802181018120010a5113300300300130240013012301d375400a2c603e002603e004603a00260326ea800458c94ccc05ccdc3a400860306ea80044c070c064dd50008b180d980e180e180c1baa300630183754a66602c6002602e6ea80084c06cc060dd5001099299980b9801180c1baa0011301c301937540022c66012008460126660106eacc01cc064dd51803980c9baa001015488107636f6e74726f6c00370e900019803801918039998031bab300530173754600a602e6ea800404d22107636f6e74726f6c002301630170012223253330133005301437540022900009bad30183015375400264a666026600a60286ea8004530103d87a80001323300100137566032602c6ea8008894ccc060004530103d87a80001323232325333019337220100042a66603266e3c0200084c034cc074dd4000a5eb80530103d87a8000133006006003375a60340066eb8c060008c070008c068004c8cc004004010894ccc05c0045300103d87a80001323232325333018337220100042a66603066e3c0200084c030cc070dd3000a5eb80530103d87a8000133006006003375660320066eb8c05c008c06c008c064004dc3a400444646600200200644a6660280022980103d87a8000132325333013300500213007330170024bd70099802002000980c001180b0009ba548000dd618088009bac30110023756602260246024602460246024002602200260186ea8c004c030dd5003918078009806980700118060009806001180500098031baa00114984d958dd7000ab9a5573aaae7955cfaba05742ae881"),
        [policyId] // Parameters
    ),
};
const multisigScript: Script = {
    type: "PlutusV3",
    script: applyParamsToScript(
        applyDoubleCborEncoding("59012a010100323232323232225333003323232323253330083370e900218049baa0011323322337126eb4c03cc040c034dd5005191998008009bac3010300e375401690001112999808801080089998018019809801192999807a99980799b8748000c040dd5000899191980080080391299980a8008a5013253330133371e6eb8c05c008010528899801801800980b8009bae3013301137540022646600200200e44a66602800229404c94ccc048cdd78021809980b0010a5113300300300130160011337000049001080118090011bab300d300e300e300e300e300e300e300b375400a6eb0c034c038c038c038c038c038c038c038c038c02cdd5002980618051baa00116300b300c002300a001300a00230080013005375400229309b2b2b9a5573aaae7955cfaba15745"),
        [
            new Constr(0, [paymentCredentialOf("addr1q8utcf6x4tkvszqwkv46nqerpjc6d86e9xe7z59nnkfzzm5u267q5v8emt0ltmneqyfd3a82ucep6v5n08tky85pvarqq8emrr").hash]),
            new Constr(0, [paymentCredentialOf("addr1q8s5ajepekp5ez3w0q39utqj785e92yg62hkq7852cs2zgutfj7f328f3qcetchaws8ye4tltf44t5qkuplkq8gjxvyqnef20s").hash]),
            new Constr(0, [paymentCredentialOf("addr1qyezx0dd2hjqzjz5aqt42m25rxcg7nrazsr74e4efx965vqlz06cm8smncyg940wft8lna86pcmhp39080e24ykq8tnqynlzm2").hash]),
            new Constr(0, [paymentCredentialOf("addr1qyddj7raf590x5lhfrdk5qp5mvte8u3mtzrw360n4kd0tnmsr2gskfskqekznt6awshlppcax8fw894ng33m8ljh95kqx6ergc").hash]),
            new Constr(0, [paymentCredentialOf("addr1qyyuf3ua0e2sjas9egqjqvza6ut3jyn0kxr3e5l2upeuasgsfm9826q0pkhau2kf6nuj0065dgejfen0kk6t7cg0d9yqedh07y").hash]),
        ]
    )
}
const multisigCredential = scriptHashToCredential(validatorToScriptHash(multisigScript))
console.log("multisig credential", multisigCredential)
const proxyAddr = validatorToAddress("Mainnet", proxyScript, scriptHashToCredential(validatorToScriptHash(proxyScript)))
const assetName = "636f6e74726f6c"
const datumString = Data.to(new Constr(0, [new Constr(0, [paymentCred.hash]), new Constr(1, [])]))
console.log('proxyHash', validatorToScriptHash(proxyScript))

const collectSet = (await lucid.utxosAt(proxyAddr)).filter((e) => { return e.assets[policyId + assetName] != 1n })
const readSet = (await lucid.utxosAt(proxyAddr)).filter((e) => { return e.assets[policyId + assetName] == 1n })
console.log("proxy utxos with asset", readSet)
console.log("proxy utxos without asset", collectSet)

// Send a few ADA to the script.
// Then send it back to yourself, and at the same time update the datum on the control NFT
console.log(await (await (await lucid.newTx()
    .collectFrom(collectSet, Data.to(""))
    .readFrom(readSet)
    .attach.SpendingValidator(proxyScript)
    .withdraw(credentialToRewardAddress("Mainnet", paymentCred), 0n)
    .complete({ localUPLCEval: false })).sign.withWallet().complete()).submit())


// Here we need to make the first tx to mint the NFT named 'control'.
// const [mintTxWalletInputs, mintTxDerivedOutputs, tx] =
// await lucid.newTx()
// .collectFrom([paramUtxo])
// .addSigner(await lucid.wallet().address())
// .pay.ToAddressWithData(
// proxyAddr,
// {
// kind: "inline", value: datumString
// },
// { [policyId + assetName]: 1n })
// .mintAssets({ [policyId + assetName]: 1n }, Data.to(""))
// .attach.MintingPolicy(mintingPolicy)
// .chain()
// lucid.overrideUTxOs(mintTxWalletInputs)
// console.log('tx1', tx.toHash())
// console.log(await lucid.wallet().getUtxos())

// const tx2 =
// lucid.newTx()
// .collectFrom((await lucid.utxosAt(proxyAddr)).filter((e) => { return e.address == proxyAddr }), Data.to(""))
// .pay.ToAddressWithData(
// proxyAddr,
// {
// kind: "inline", value: datumString
// },
// { [policyId + assetName]: 1n })
// .attach.SpendingValidator(proxyScript)
// .withdraw(credentialToRewardAddress("Mainnet", paymentCred), 0n)
// // .addSigner(await lucid.wallet().address())
// const [spendWalletInputs, spendDos, spendTx] = await tx2.chain()
// lucid.overrideUTxOs(spendWalletInputs)
// console.log("tx2", spendTx.toHash())


// const regTx = await lucid.newTx()
// .register.DRep(validatorToRewardAddress("Mainnet", proxyScript as CertificateValidator), null, Data.to(""))
// .attach.CertificateValidator(proxyScript)
// .collectFrom(await lucid.wallet().getUtxos())
// .readFrom(await lucid.utxosAt(proxyAddr))
// .withdraw(credentialToRewardAddress("Mainnet", paymentCredentialOf(await lucid.wallet().address())), 0n)
// .complete()
// console.log(regTx.toCBOR())

// const signedTx = await regTx.sign.withWallet().complete();
// console.log(signedTx.toCBOR())
// console.log("submission", await signedTx.submit());