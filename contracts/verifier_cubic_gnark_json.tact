
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
const vk_gamma_2: Slice = rawSlice("b21dc4e3c36392a7d5fafb4177dd209416851bb1a008b196d18e6bd42581e9efe1944ef655ec6c87bb1b4520c347e37d0392b3a0eeef8f9c2c5893dab6acd5a91b3076655aa57581b2c417e9df36e7c183ecf2b450ddff3f7138699ff14a7d6f");
const vk_delta_2: Slice = rawSlice("a55004e96f07b7b0bef71dad062ae868093e1771d4b65e47c42dc0abf7365ef228d66d1bf1dea0cc32d6d86b96270d8f0b005fef4fecbe3de8699f33995e6a3d5184b29a568451110895d583d5fe142b634d9e651c735ab49459830d08c2d579");
const vk_alpha_1: Slice = rawSlice("a89bcc7dd74bd49ad2b36e6074d1cf55007fd2142b40b1e72c2047616e1ee1f1b6ad34700126626698f03e037edd60c9");
const vk_beta_2 : Slice = rawSlice("87d17b4de58e0fbccb52970e229a21b475ccc8db384b6dfa02ef4d1fdf98c08c0905f80e24b21c188ac23cd90624e1d80b1bfe1d2ce4541452a96e2b3108c8907605050151d966c5302364629c02708134dbc7ce8d7e587fd46cd5e8e58b77c7");

// IC constants (IC0 is the constant term)
const IC0: Slice = rawSlice("a6bae9f02dcf85c4a5caa934276b406d3029faab6b8281a870f3ffe4a5965991cdfc3fbb999f4e62ee4c16ffecca2cea");
const IC1: Slice = rawSlice("abefddb84f28bc8e7d5be1098d3850905f05b3b25bcbae082242ffc1bffacc465442187680358ddaebca88a2fdd8921b");

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
