
// ASM intrinsics
asm fun blsG1Add(x: Slice, y: Slice): Slice { BLS_G1_ADD }
asm fun blsG1Neg(x: Slice): Slice { BLS_G1_NEG }
asm fun blsPairing(
  x1: Slice, y1: Slice,
  x2: Slice, y2: Slice,
  x3: Slice, y3: Slice,
  x4: Slice, y4: Slice,
  n: Int
): Int { BLS_PAIRING }

asm fun blsG1Multiexp_1(
  x1: Slice, y1: Int
  , n: Int
): Slice { BLS_G1_MULTIEXP }

// Verification key constants
const vk_gamma_2: Slice = rawSlice("93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8");
const vk_delta_2: Slice = rawSlice("8ec8a84efab48998c416ef7e4cf28b8136a3f219dd18763ab27a29db2503bc197b0f11c3dcc82099d4fd8a6ddc9f19300d4d84956a911aed06f20a5431a55b73582f7af7e4f6c6d26b42f7aaf6e2be169b99dff7163063bfb8b804422ec94476");
const vk_alpha_1: Slice = rawSlice("8d325ba518c4f97a8700ea10140dc3741daca0e6b70db20cf6adf7931368e5e956ced77ac320cb309ee94ebb7ce3c334");
const vk_beta_2 : Slice = rawSlice("8e3331393f06b4dddaf04488539cfb8f898c75d862a7aa49b431f9d3c6e6042be329a4c9f9e37a2e66e8713a14cd79f916e8bb551244bb87ba6f159ce9a94928053fb78c258095ab99e6e98bfabe71d76a1b02095fe34ac6cb0bf4e1bf66e181");

// IC constants (IC0 is the constant term)
const IC0: Slice = rawSlice("b57ec367fc21b7d48c985ebce3eb7109e3a323a5d469b24a3ccb9e2c116a46f019837b643a561596ccb2afef897f09bf");
const IC1: Slice = rawSlice("b0df00b22ea036a778acd638efec8ab745744116397195f784ab060a793090b57213705f0f7808d554a3fd49a2ef5303");

// Error codes
const ERR_PUBLIC_NOT_PRESENT: Int = 257;
const ERR_TOO_MANY_PUBLICS: Int = 258;
const ERR_WRONG_PROOF: Int = 260;


fun assertNoExtraPubInputs(pubInputs: map<Int as uint32, Int>) {
  foreach (key, _ in pubInputs) {
    nativeThrowUnless(ERR_TOO_MANY_PUBLICS, key < 1);
  }
}

// Safe getter for public inputs: throws ERR_PUBLIC_NOT_PRESENT
fun getPub(pubInputs: map<Int as uint32, Int>, k: Int): Int {
  let v = pubInputs.get(k);
  if (v == null) {
    nativeThrow(ERR_PUBLIC_NOT_PRESENT);
  }
  return v!!;
}

// Message definition
message (0x3b3cca17) Verify {
  piA: Slice;
  piB: Slice;
  piC: Slice;
  pubInputs: map<Int as uint32, Int>;
}

contract Verifier {

  receive(msg: Verify) {
    let res = self.groth16Verify(msg.piA, msg.piB, msg.piC, msg.pubInputs);
    nativeThrowUnless(ERR_WRONG_PROOF, res);
  }

  receive() {}

  fun groth16Verify(
    piA: Slice,
    piB: Slice,
    piC: Slice,
    pubInputs: map<Int as uint32, Int>
  ): Bool {

    assertNoExtraPubInputs(pubInputs);

    // Single batch (no loop and no ic())
    let acc: Slice = blsG1Multiexp_1(
      IC1, getPub(pubInputs, 0)
      , 1
    );

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
