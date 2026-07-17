
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
const vk_gamma_2: Slice = rawSlice("ad72d0ac89c1b44a46a41a9077a9507da193cbc2abcf574a6242ede7c47089d390efecd9f2b6cf331c52b2958c88c1700f892e10709cca8dd1b6b32f0a1b20d8f275797b6332983425a1854003a7a20e51f30725828f9b68002066da2ae6e95b");
const vk_delta_2: Slice = rawSlice("87e6d6b01f25ad6363303f24e964705526e57843bdf5acba6d0319b63d2d827c7beefa79a58ba606c6e004e71f17c249004901dbd826e742e4d9dd87478a7adbc5c7758b42303950b2633bb031fde6a76f2fc2ed4e8f53308eb16e13716c0808");
const vk_alpha_1: Slice = rawSlice("a24ba174055757ecc604d39bab36d2f33a6564519e3b7d004974b593ad14d988cae28e223876bf54f147bafbc9dbbf4f");
const vk_beta_2 : Slice = rawSlice("a1134ed31cf09f0520c5d817b4a319ab7af4bc3035c8b40d8d1fba10d898f7b12cb39717e968b8d1aece11a2094e19360bf0d34a6654223090f7ade6c0c38f7e4afd67ddb1f8b83d48d5ede8a57dd882a575245cc971b8d18709e948d9258909");

// IC constants (IC0 is the constant term)
const IC0: Slice = rawSlice("947371f0313152314b2c6c9643399f5a81927f526eecc67db2aed5f3d8c729e7d8749724703d129b761419a323ed0a94");
const IC1: Slice = rawSlice("b29d7a599d77e8432b32cb7b4c631afe64156ed598c213c5cc4ef2a0750ec1b3854aa157df72a7fa98ff1ebf41f09de3");

// Error codes
const ERR_PUBLIC_NOT_PRESENT: Int = 257;
const ERR_TOO_MANY_PUBLICS: Int = 258;
const ERR_SCALAR_NOT_IN_FIELD: Int = 259;
const ERR_WRONG_PROOF: Int = 260;
const ERR_NOT_ENOUGH_VALUE: Int = 261;
const MIN_VERIFY_VALUE: Int = 50000000;


asm fun blsR(): Int { BLS_PUSHR }

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
  let value = v!!;
  nativeThrowUnless(ERR_SCALAR_NOT_IN_FIELD, value >= 0 && value < blsR());
  return value;
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
    nativeThrowUnless(ERR_NOT_ENOUGH_VALUE, context().value >= MIN_VERIFY_VALUE);
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
