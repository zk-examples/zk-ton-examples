
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
const vk_gamma_2: Slice = rawSlice("a965dc2407c59b9864c5fec965c01d8a52c876f36b1453d4582e4bc9f389e71000f818678335e5d7aee28aef35509b69041f8d4a7365f5f63b13ab91c089da9a4a68b3d4e8ca1b1f94e1c904b32bf40b54bea46bf5b5113f9dbed9311d247b93");
const vk_delta_2: Slice = rawSlice("ad9427d12ae0f06143a4c32bcc3ba593bf772f71cb3869167e747890b6d70e8f309ff84381f4f7ffabfa5e65f37656c318a3f833914b30200c9acdbd56978ce13cf82ba388a265a7c41a3a7bf383ebd5be741974198247ee28c4cadced55d463");
const vk_alpha_1: Slice = rawSlice("a95a9f38c34d3243a56b97fba33f3aa9ce75e5339905413379e46be07a389d748cbfb7828145a56e0a5128b1ee268eba");
const vk_beta_2 : Slice = rawSlice("867e8316f4f81faf76200279675780fd62c44e090ee8827b06eb81dcbef8d30eec83936696a06ee9d3f97704e5f86961101c5cc654dc8481b3049b0b57fd68bebf8b072429438431b2d7afa675123ec8ab8ac0fda964bf7867f20fc0398f7a53");

// IC constants (IC0 is the constant term)
const IC0: Slice = rawSlice("86d98a5741396bdd2071817c4ea85cd00ab25cf7f8d1f908bb2e37096473bbfadb67de89c8bf348cb97f819c7b3a73e1");
const IC1: Slice = rawSlice("a5d0c9c44f9aac1e83a33453894861aa76eb0496f82b8efdc2be8a69735d2af96cd642b5b718baa6eb323d4d92922353");

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
