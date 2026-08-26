
// ASM intrinsics
asm fun blsG1Add(x: Slice, y: Slice): Slice { BLS_G1_ADD }
asm fun blsG1Neg(x: Slice): Slice { BLS_G1_NEG }
asm fun blsG1InGroup(x: Slice): Int { BLS_G1_INGROUP }
asm fun blsG2InGroup(x: Slice): Int { BLS_G2_INGROUP }
asm fun blsG1IsZero(x: Slice): Int { BLS_G1_ISZERO }
asm fun blsG2IsZero(x: Slice): Int { BLS_G2_ISZERO }
asm fun cellIsExotic(x: Cell): Int { XCTOS NIP }
asm fun cellToRawSlice(x: Cell): Slice { XCTOS DROP }
asm fun blsPairing(
  x1: Slice, y1: Slice,
  x2: Slice, y2: Slice,
  x3: Slice, y3: Slice,
  x4: Slice, y4: Slice,
  n: Int
): Int { BLS_PAIRING }

asm fun blsG1Multiexp_7(
  x1: Slice, y1: Int,
  x2: Slice, y2: Int,
  x3: Slice, y3: Int,
  x4: Slice, y4: Int,
  x5: Slice, y5: Int,
  x6: Slice, y6: Int,
  x7: Slice, y7: Int
  , n: Int
): Slice { BLS_G1_MULTIEXP }

asm fun blsG1Multiexp_4(
  x1: Slice, y1: Int,
  x2: Slice, y2: Int,
  x3: Slice, y3: Int,
  x4: Slice, y4: Int
  , n: Int
): Slice { BLS_G1_MULTIEXP }

// Verification key constants
const vk_gamma_2: Slice = rawSlice("93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8");
const vk_delta_2: Slice = rawSlice("b95e8245cb70c184b89d1001906a8b9046f5d06e12e2ff506eeb9ec033760663b57850f1d7d23f166155d92fb58c7978005f972210cb22fe19109ced897eacc29492095c29e92ea75f359229eefd4209f9c909ac96256554213b8eafd337eb7d");
const vk_alpha_1: Slice = rawSlice("a293d5acec945b20b4aa6745cc504f4a728762fee3990798f82083eeec6c916bc42cc001363e33d5da4c14c6b09c7382");
const vk_beta_2 : Slice = rawSlice("8b707ad41a9b06144caccd29889a08ebcfe053789db7f86a66de993dbc8a1412b07d27ad1132a1c2f6ba8a794b5ca8f10522015e623816189232044cfdfe54847f959ea930994cc4f07e34c1e6071b915e0d4915c33ac4e6eae516566ea9ee36");

// IC constants (IC0 is the constant term)
const IC0: Slice = rawSlice("a76b7115a7d1f40da860125782231756e6d619909c3444b8cff1ae70343f0d40428cacdcf8067c51e2f9c1abe265fccd");

// Error codes
const ERR_PUBLIC_NOT_PRESENT: Int = 257;
const ERR_TOO_MANY_PUBLICS: Int = 258;
const ERR_SCALAR_NOT_IN_FIELD: Int = 259;
const ERR_WRONG_PROOF: Int = 260;
const ERR_NOT_ENOUGH_VALUE: Int = 261;
const ERR_INVALID_INPUTS: Int = 262;
const MIN_VERIFY_VALUE: Int = 50000000;

fun checkProofPoints(piA: Slice, piB: Slice, piC: Slice) {
  nativeThrowUnless(
    ERR_INVALID_INPUTS,
    piA.bits() == 384 && piA.refs() == 0 &&
    piB.bits() == 768 && piB.refs() == 0 &&
    piC.bits() == 384 && piC.refs() == 0
  );
  nativeThrowUnless(
    ERR_INVALID_INPUTS,
    blsG1InGroup(piA) != 0 && blsG2InGroup(piB) != 0 && blsG1InGroup(piC) != 0
  );
  nativeThrowUnless(
    ERR_INVALID_INPUTS,
    blsG1IsZero(piA) == 0 && blsG2IsZero(piB) == 0 && blsG1IsZero(piC) == 0
  );
}

fun loadCheckedG1(point: Cell): Slice {
  let pointSlice = cellToRawSlice(point);
  nativeThrowUnless(
    ERR_INVALID_INPUTS,
    cellIsExotic(point) == 0 && pointSlice.bits() == 384 && pointSlice.refs() == 0
  );
  return pointSlice;
}

fun loadCheckedG2(point: Cell): Slice {
  let pointSlice = cellToRawSlice(point);
  nativeThrowUnless(
    ERR_INVALID_INPUTS,
    cellIsExotic(point) == 0 && pointSlice.bits() == 768 && pointSlice.refs() == 0
  );
  return pointSlice;
}

// IC selection helper by index: 1 -> IC1, 2 -> IC2, ...
fun ic(idx: Int): Slice {
  if (idx == 1) { return rawSlice("aa4d678192d1836e7e785924b7c73535e5e29e509e6ad14e2474d73d2db2d58195d1f1d93e4fc8b049f4a3c7c3ede576"); }
  if (idx == 2) { return rawSlice("b7651e58d92e78f8f49a5a0df3d8532f708ddd352d32ad1f361fa473d307ade61bc82e924a50a1771cccbe2d4d840e2f"); }
  if (idx == 3) { return rawSlice("a16aea5cdc3c1b97b5e4940bccde4040aa87de6cb52df8c20f585d9d9b0edda6ebff5e291e5d125e5ea781872a2b7e1b"); }
  if (idx == 4) { return rawSlice("9240f1a0b4817a1baf00e3bf036dfaba06d5bf738cd1e76d32f79094ef3cb555b036b7a72dfb9f9c237d3a77be825475"); }
  if (idx == 5) { return rawSlice("b44d5ab01fe5769b62228c6a7a9d9abb1274f2d4a300465c08c5fa0f2b95be29d5ba25abde3dcf24824efda078537f8c"); }
  if (idx == 6) { return rawSlice("813201ea20ef692d95de58a26838fbfea35b571c30765c7786c445775852359f8abf3dbf4a43e4c7d94324e19c923b06"); }
  if (idx == 7) { return rawSlice("ac86440e0b68690c84e00a31ec5820d0dc781484b0c6692b62d5fb99f66037e1a20117f194183334550bf44a444e0b8b"); }
  if (idx == 8) { return rawSlice("8f15929b35cc07abd30d55d8ce64e63eba67f1e8792d44c54b8be7df61b4f2b8a00cf366d613233b0f57fb8e3119cbb5"); }
  if (idx == 9) { return rawSlice("8a5e362945afebf254a7afee29d375d729e0ef74d748e0419ccf6ed2f9c8d5ebfc226c1c9041ab6f47b6f5d818f65411"); }
  if (idx == 10) { return rawSlice("b82dbc62438e496a4b88b7ab5df93495eeaf6c99cfe1ae863d7c90c3413e4ac55ec343d7a800997cc4a3d201fefaec47"); }
  if (idx == 11) { return rawSlice("a0b01fdd7f4b336a76eb24c4b4a11e7c21a39293abd467724f8813a1d6600a5d8c2b947c5d701326bf341d0a9abe3a67"); }
  if (idx == 12) { return rawSlice("a0df335f7fff2a33f63ae08d37d79a1a23f31273bdbdaa18f4be7602051f73b86d2507c95b38c2fba26f56bb7c7343f3"); }
  if (idx == 13) { return rawSlice("b762239c5e29fcfc6ec2040a9c0eb184ffbd9a7b55e28c2f246f9ba898d52668099623ba5c3a1d0e2a44cc75041b11a1"); }
  if (idx == 14) { return rawSlice("b9e8f2675884840efbff4f1ede7758a4d0f843d28b7d30d41ac9058786a5247752001bb2f59195eb546a9a47c890ebc0"); }
  if (idx == 15) { return rawSlice("ae4868b43af83a279647396b14a71b0a6eef43e1a17ccb55fe638f15494ac83563fa01f730adf554e0c16014a9e08fb4"); }
  if (idx == 16) { return rawSlice("8620bae138912b6a1cc1ac81d5fdd6650ea3b9865aed60a1744793aeeb5555ed58d596fda1005c340cc136464f5eade3"); }
  if (idx == 17) { return rawSlice("b01f674781495b43e73dfc3760ef20afe0e7272f1af1592704398dce2f2679a9607e1ceb13c9ced370894e1d87134b86"); }
  if (idx == 18) { return rawSlice("843991fc4701cfb064c160df30e2940725b3fea36b385a2d7ff276de7b298663ea6ceb33da60a8467c99376840886a36"); }
  if (idx == 19) { return rawSlice("a95648e176677dbc9658274650054a59469e2f56a6787399e610555d1e50dd67e51ab8826bc49484f46a63114213be3c"); }
  if (idx == 20) { return rawSlice("a1f61786ac2c1d5f2c866ccc85b3e9721bf67e721252265aab8bc8f69c42a017f57cb02d2c8e21230802e449afbde288"); }
  if (idx == 21) { return rawSlice("a15fb228c7b1f671b5f3a9a49cbc202c07f281aa9220032c6bb4645c533a45ad96c18c45923bce005b9b45443246f7ee"); }
  if (idx == 22) { return rawSlice("ab71d530278880fc9d6c73df045c04913c00029c99e1f34e1cc94d83b032cacc7fb9c5dc86566c38223c6bbbd1247a2f"); }
  if (idx == 23) { return rawSlice("99da9f2a7a2b994a7e720e9f28ee956c7cdbeab3f565aa587f8e4b48d4b002183d441726ad08d0584e472e4b9736f89b"); }
  if (idx == 24) { return rawSlice("a52447f12a9a93ca8f9f7f3bd7b3ff602565df9149dae8be8a9ea34b165d2253880b468aab398d94208ef6c5da6ab05a"); }
  if (idx == 25) { return rawSlice("821f1522ddde8135d673146481caaa5f74b3812df42d10d80db42b438b52f83cb5295ffa7b417c2f8b8139c1e8bfc323"); }
  if (idx == 26) { return rawSlice("b02eadc60bf2affc3e0020dbc73984bb970ae5689f46fad23326a1813666f1c12a04af61a3abe71e75d94153dbddf4b4"); }
  if (idx == 27) { return rawSlice("b279394cc1a8548ad9a5a9b9d25648d1e67fdbc4fb4725c3f718ef43a18416bdad79dff4e145c1ad6f0f1bb7db738332"); }
  if (idx == 28) { return rawSlice("a8994a3efa53a0a7c5c747ae4783563718f5c3eff2a05068118af01b1dc37426ede5af3590cb05e915509109fc2197da"); }
  if (idx == 29) { return rawSlice("b1e3762aa805720126acc4e6a4b9a938ca7769783d5a55d14891781e1282f9903ecc1b86eedc7d8fecae890e43dbf842"); }
  if (idx == 30) { return rawSlice("889c5a8a3272c574637f67af16fa90e8322afaaee933174f0d0112c94f6a3b3428b373bd07825b4eaeb810977ebfe53f"); }
  if (idx == 31) { return rawSlice("83e8e345992222fee425f2ea2970c561660aca2269c95adddd8f957e385c822982b2be3e14a5e7a8d25976242b2145a1"); }
  if (idx == 32) { return rawSlice("9342032d64ee476baecbe03f96210f3cadd9fbfe9e579285037bb36cb43372f919047c663243bb737ffda4eb2ae6317a"); }
  if (idx == 33) { return rawSlice("ad8a189cf2458bd3b109fb86b4779e1cf4140858c1866b451dd322e89260e0811243b01d76b90212a36bc5fb5ef83805"); }
  if (idx == 34) { return rawSlice("860e07d4a6bd55aa067ac6f9fe43bcc2c4048655b54d84865665a1e7654b3a227e1122f154d07bd020de608a2ab68abc"); }
  if (idx == 35) { return rawSlice("a5ff39abab25a5e569b9362082a7b8dabf474fbfce3cdd43871ca51dbbcb2dda4f08bd4bcb488c0017f422be3968a7ae"); }
  if (idx == 36) { return rawSlice("992c8696f8f4886c14b9790d33a1d98f1c62e410387cd6b75b2fc9619ec2d80fd34c4ed991ac6093c13024c00db5a66c"); }
  if (idx == 37) { return rawSlice("b8cd958591817f189c78feccf63ec37ca9bfdc8391791a0c7862f3c142a037302013dac3c933c1cccfa4f3fcdb7a3725"); }
  if (idx == 38) { return rawSlice("a49c3f92c67b643c636fc721ff947530d213caa349f389551719fdb2b2accae008762411e904abb5da0ea0d5460345e4"); }
  if (idx == 39) { return rawSlice("afad3697fb60cc153f05e56155165a2ce91e35bb8cb7257804dc01e94e6a8f366ae0dec4e2bcf1597a4dde7551f2bb92"); }
  if (idx == 40) { return rawSlice("b9672aaf598fde62a881fa3978787751a925e8974ef81ed275fc676c505ccfc528ce0c612191d9f97703cf69a3946e9a"); }
  if (idx == 41) { return rawSlice("864199dec419960f31cbc5aa21264d1b36119efaa782b1061524182b7bf5513a4a431952017cbdbe473caca969dca018"); }
  if (idx == 42) { return rawSlice("abc728806d485052dbf4b6f156ee9f5b561fb5bb7654306285d1ff0fbb9bbf359a122a9676dddd7082f8102a6d2f66d3"); }
  if (idx == 43) { return rawSlice("b7432c8b03d1172763e09e9a2f07b8039027158fc57c87e36d91eeec98f78264704c7a95f94cff0050f49710dbe16b94"); }
  if (idx == 44) { return rawSlice("b68c6d15954c3bae09103df9416e112e1e858fcf946bdd360c0be750ba9121dfbacfa7c343d3a706294c28f2ae7efa2c"); }
  if (idx == 45) { return rawSlice("849d42d1076462040acc2ad89ae7ea27be821d6b419e377d1a690be578f1e72b65ec5604b399756c3218fc98c7b90fd7"); }
  if (idx == 46) { return rawSlice("ac99a64af1de40e4eb12269e68ef77e33ab450ace44e60758bcb3fbc5615502be6375cf394381555017c90b5f0bc7456"); }
  if (idx == 47) { return rawSlice("8be762e64ed6df8131f374b26451ee736f5d930cd14370b61f44b558e816d87fa8306d04b85a3f6778e1a83c763ca460"); }
  if (idx == 48) { return rawSlice("8998ecae1eed45bf872b748d3d2c8fdb6958e20e19a69aed19d5ce3053c38b58304a4b3bec2deab95d33a0c40a80aed7"); }
  if (idx == 49) { return rawSlice("807025a245e3e9958a242095799f51790c91d6e8b8c60686af77324b68adbdefa01b7d0383b04a1bdf46b827e0d8197e"); }
  if (idx == 50) { return rawSlice("8c9e4f9988b80ac92d1fd9fe378c907ba4000dde4ef3d46148d428d1cd07e2b624765da479755fe064ddb4ad3d651510"); }
  if (idx == 51) { return rawSlice("8e9fcebc0ba96fdb74f55de18d96202a24307b54aae9ba4077f39939b228ecd45d61b462ba9c078e10348ee174704166"); }
  if (idx == 52) { return rawSlice("86bade386a0a05dd0b1b9b32a1ce6eb72cbc4a84a742b024efd179ea8880227ca24110c664b4242dc6df351b7fbe9421"); }
  if (idx == 53) { return rawSlice("ae59940c550ee869e337c3298f3d444705bd422b3b784ef590980d26fff4b181de1898ab4adf64cdfca5f7a009eb247d"); }
  if (idx == 54) { return rawSlice("85f8e2ed56913262944ff7155405a43f08ce16ba70c8216e96ca7704e6d5a13590c5f3e30eeffaf29d37803794b54a43"); }
  if (idx == 55) { return rawSlice("a494ad99838a85097250f8e9801f84d90453f734cf10f6065eddac24f8d13bda4dcdb474dfad8ae33d5d092f67b74a29"); }
  if (idx == 56) { return rawSlice("b0f0ed88a921697c7f4f2951f391451bdacb15092260ae5b36adc4479d1f0af4b0ff1f88e47d1994d4f4f3a600889a70"); }
  if (idx == 57) { return rawSlice("8744089ccad35d37bb26f1dfbbdb905c00dfc53a4651cfe46ffe8f4c8889a75108cff3466b835587c2c1d7c5c2724e7a"); }
  if (idx == 58) { return rawSlice("99f2cbad37aadd796f0a0f73bedc57db63a3c45149bf90f4f01730f2ba2cc1ffda8afb36a752c1dd46f26c9af1539842"); }
  if (idx == 59) { return rawSlice("816d8618934f543d8d2929db16a719b3902b15dd98bae079a957a5cd52041e6be90854622ba12fe1bb0aeb62e8516335"); }
  if (idx == 60) { return rawSlice("8cd686b6b65b5951d9c921036cb3098eb5c7ba9274ed5ab5443b8091a5531613f9588c990859b3f281c8a4dda1ea585e"); }
  if (idx == 61) { return rawSlice("950f1eb802b5ad2d89573fac07ffa5e1bf5e98cd840b4a56dadeb19f76055caa813b441be61f2fb37b0cccbed9b5b4aa"); }
  if (idx == 62) { return rawSlice("ad225479cc7e42d6124f365e9ebe0750da24bc82afb27c3ff90319c343c1e9b254d73a94856a3fc45e2308b409f3a645"); }
  if (idx == 63) { return rawSlice("9353f3c12e4008d7c880b5873b765ab2ba43e11e00a4bc20dfb543536795b44ae6c4a43ce58b3110a8804f688b87fa45"); }
  if (idx == 64) { return rawSlice("85d70af23caaeeeb99b5e86bac38fde9a3904fd0601f17f9618338d001aad8342bc12d3730cec6cd04852841a6cf29d1"); }
  if (idx == 65) { return rawSlice("a2a3b4c0dc7fd7d76618fbafc26c76776a6d85f863dbf231baf96cfa15ee1204021e8ecf0555af917b480c8e6c180390"); }
  if (idx == 66) { return rawSlice("800fab675ca44e5b11c874c6ce86ed45dc8e7c0e000c97459657d5d1489681dd5140e74fd677a6df11ebe1117af6a668"); }
  if (idx == 67) { return rawSlice("92179d7f7be00d17426d11489a39924dcd678320a9f1730e62194ca928be4265a3631ea111bb15c89e7d1ec23a5e5e8f"); }
  if (idx == 68) { return rawSlice("8ddc15df65f89b94e99944d32fe3d9a2b57d9208241a221f6481bb63adf0895e607e1f8fef9df0566ea3e09a2fad1c49"); }
  if (idx == 69) { return rawSlice("877001ee177fa4f9c79beb58c1a99df5e77a41030e85ba17fac323215baddcf12479e18e213307c921bb817e253e4757"); }
  if (idx == 70) { return rawSlice("b2336d3d6e27f5df2ed8985944de62d9972043f962fc2257bdfad912356f7a29487784dda813b6642650e9d38e0f5578"); }
  if (idx == 71) { return rawSlice("806528daab0f9d92c9cad0cf24c16cfaad37c7922861215e468151e697c981dbc5be881235a0c0f28fe3e66f24f5e01b"); }
  if (idx == 72) { return rawSlice("a29341e8727db541ef8528f40dbe67cac2e37659acf4e1d22fddd38723fa01119e6353a56c7f7afe74926dfd08ded841"); }
  if (idx == 73) { return rawSlice("b84ca0937617fb7afb8211a0f0bfa0a6ac6d6bcc5bb97c58a90e9954e7d4144269c5d2983948384cbf03853e6589c7d8"); }
  if (idx == 74) { return rawSlice("84b39f03197e083de2d9121590c84492e653ae231e9720da71e6b549ae3b80ca021102932c447110bac9f9992ff31d1b"); }
  if (idx == 75) { return rawSlice("b72666909c4855f669070685db2f3ab2ac4c414c0f9a345941f0850ef00478350b3f82ec348b1e813bce5e2d59505020"); }
  if (idx == 76) { return rawSlice("a7d7bebd3d9ace84180e3175dda2c43b743566460d8e41ecbe20900aea59cb7801aba22d4fb6399681364727ae9155de"); }
  if (idx == 77) { return rawSlice("b36ea2ffba695c7827ac0c992de969b80bac137e9647b46ca2176259cfd5bc4f4144f28b4e2ec45dd83310f660f9f8a5"); }
  if (idx == 78) { return rawSlice("8d38b5a0ce728b968eb7d928ab2acbbfc760fbf413191ca6a3b1bfc66e450df4777c0ec56853745270ae33020b7583e0"); }
  if (idx == 79) { return rawSlice("8bfd1745e189a1450f423de26012423b34992a0e2fe34afbd4f33bd963f0bd7acd1463f36d9d092bea2d86ddad28e983"); }
  if (idx == 80) { return rawSlice("8f7dc9c515ad1981ee6eedf624dc42772bcd1dd3684bcc3c699488ed18ab2f5a843ccb830e78259275717de03d012fa1"); }
  if (idx == 81) { return rawSlice("b9dc71ecd3fa82ed0ba841e3d57d98881e1e2e1348bfa55ef8b1943b1dfbec2ebb9510f9215be4a71b1241f9d076adb7"); }
  return IC0; // Unreachable for generated batches
}

asm fun blsR(): Int { BLS_PUSHR }

fun assertNoExtraPubInputs(pubInputs: map<Int as uint32, Int>) {
  foreach (key, _ in pubInputs) {
    nativeThrowUnless(ERR_TOO_MANY_PUBLICS, key < 81);
  }
}

// Safe getter for public inputs: throws ERR_PUBLIC_NOT_PRESENT
fun getPub(pubInputs: map<Int as uint32, Int>, k: Int): Int {
  let v = pubInputs.get(k);
  if (v == null) {
    nativeThrow(ERR_PUBLIC_NOT_PRESENT);
  }
  let value = v!!;
  nativeThrowUnless(ERR_SCALAR_NOT_IN_FIELD, value >= 0 && value < blsR());
  return value;
}

// Message definition
message (0x3b3cca17) Verify {
  piA: Cell;
  piB: Cell;
  piC: Cell;
  pubInputs: map<Int as uint32, Int>;
}

// This verifier is stateless.
// It does not provide:
// - nullifier replay protection;
// - nonce or query-id protection;
// - known-root validation;
// - recipient binding;
// - chain-id or contract-address domain separation;
// - state-transition validation.
contract Verifier {

  receive(msg: Verify) {
    nativeThrowUnless(ERR_NOT_ENOUGH_VALUE, context().value >= MIN_VERIFY_VALUE);
    let res = self.groth16Verify(
      loadCheckedG1(msg.piA),
      loadCheckedG2(msg.piB),
      loadCheckedG1(msg.piC),
      msg.pubInputs
    );
    nativeThrowUnless(ERR_WRONG_PROOF, res);
  }

  receive() {}

  fun groth16Verify(
    piA: Slice,
    piB: Slice,
    piC: Slice,
    pubInputs: map<Int as uint32, Int>
  ): Bool {
    checkProofPoints(piA, piB, piC);

    assertNoExtraPubInputs(pubInputs);

    // First full batch of 7
    let done: Int = 0;
    let batchesLeft: Int = 11;
    let acc: Slice = blsG1Multiexp_7(
        ic(done + 1), getPub(pubInputs, done + 0),
        ic(done + 2), getPub(pubInputs, done + 1),
        ic(done + 3), getPub(pubInputs, done + 2),
        ic(done + 4), getPub(pubInputs, done + 3),
        ic(done + 5), getPub(pubInputs, done + 4),
        ic(done + 6), getPub(pubInputs, done + 5),
        ic(done + 7), getPub(pubInputs, done + 6)
        , 7
    );

    done += 7;
    batchesLeft -= 1;

    // Remaining full batches of 7
    while (batchesLeft > 0) {
      let tmp: Slice = blsG1Multiexp_7(
        ic(done + 1), getPub(pubInputs, done + 0),
        ic(done + 2), getPub(pubInputs, done + 1),
        ic(done + 3), getPub(pubInputs, done + 2),
        ic(done + 4), getPub(pubInputs, done + 3),
        ic(done + 5), getPub(pubInputs, done + 4),
        ic(done + 6), getPub(pubInputs, done + 5),
        ic(done + 7), getPub(pubInputs, done + 6)
        , 7
      );

      acc = blsG1Add(acc, tmp);

      done += 7;
      batchesLeft -= 1;
    }

    // Tail batch for remaining 4
    let tail: Slice = blsG1Multiexp_4(
      ic(done + 1), getPub(pubInputs, done + 0),
      ic(done + 2), getPub(pubInputs, done + 1),
      ic(done + 3), getPub(pubInputs, done + 2),
      ic(done + 4), getPub(pubInputs, done + 3)
      , 4
    );

    acc = blsG1Add(acc, tail);

    done += 4;

    let cpub: Slice = blsG1Add(acc, IC0);

    // Pairing check
    let piANeg: Slice = blsG1Neg(piA);
    let ok: Int = blsPairing(
      cpub,       vk_gamma_2,
      piANeg,     piB,
      piC,        vk_delta_2,
      vk_alpha_1, vk_beta_2,
      4
    );

    return ok != 0;
  }

  get fun verify(
    piA: Slice,
    piB: Slice,
    piC: Slice,
    pubInputs: map<Int as uint32, Int>
  ): Bool {
    return self.groth16Verify(piA, piB, piC, pubInputs);
  }
}
