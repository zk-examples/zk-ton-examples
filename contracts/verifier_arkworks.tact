
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
const vk_gamma_2: Slice = rawSlice("a0cbfce464b24b5cdb057a79d4003bb028f0e2f4a576f26a6fa5c3cf3dc7e5ba645c80f26d6fb09fd916ba3f55579412038515754b789d98275b3bfe45584bca0b0dc8481c95c14108d9367ad16e3ee1008f6b59b27681cc4e0fe2527f239b83");
const vk_delta_2: Slice = rawSlice("a85c6c016a8c0a770404ffaf380c81563118da21bdc3babac77091b12bb9a74cc68e4d389657113951e29b96fc0393ab0e54b83c40bc1dabe457e771f930ed7e2a9eed93da746bb1f4c504ac84bf0d2fe3c49dd3c8dda8a4f4cdfee1ef9d91c8");
const vk_alpha_1: Slice = rawSlice("abc1dc7f0269fbc6fab030257a4ab667aabc88d379e6955381cf07f2cc124fb7e56238fdd5929301d638306da75f3a2d");
const vk_beta_2 : Slice = rawSlice("91a4ba4b1e7e11ff2b3f4f648592899aecf86a8cfa04bf8113c6c2e2d57163339fec32395b4123c47a693cc59f85a1bf144a4db16079d935f9e7114088511fa58cb79772b6fb742201ba88dc2d75d5535e22e5a02abe2f10ed619cbf21c08979");

// IC constants (IC0 is the constant term)
const IC0: Slice = rawSlice("856e904180fbb90cb467e2672c5f7b30fb2cea30228d845e9f782d66e7bb08511f275f02a91d159bd4934f39632397c3");
const IC1: Slice = rawSlice("84382fb94adafd0ea40d79009ccd015acd4b9cc87c7dbfab7fa23bc3280d1d3988878e85dd890b64d19df082b5cc7251");

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
