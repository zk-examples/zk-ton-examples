
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
const vk_gamma_2: Slice = rawSlice("a2ffdae86d497b049ee4c17ba93dc5957f252cfa7b2e11058a51dc9fa74f73efe8c7c668f3a60d56c2ad953e29c9d7a300e4716b80d23281d18ed453b7551d2c87bbab43e4511e3a2892e425d4d955ab31752dd7a008cc0f74fcb63b89322291");
const vk_delta_2: Slice = rawSlice("a8c7dfdda8fef20c85ce4bad723dd62f1ca9dfc8a68641b7d1f0ece234ffda8414a2161cd59e065333dd3fbccdebb8e6017ab9cbc7ce62ef5aae9cceed22f3b958a5075c13296357a767bd5a5a1e8caff3b7ab98bbbcc244523a679e3de92621");
const vk_alpha_1: Slice = rawSlice("b2a83fae55265eb7ba6658358403964f2d1350124f8c98f7aa46aa778b1717d4771cfa7d604749c365ede5e1e0623eac");
const vk_beta_2 : Slice = rawSlice("a1d83705c11c616064d949ec32ba39f08bda31fbb4677c373e1879f6a2a92edc0579911ea0f1d9b8fca20c26d3817a1715bba73bd4f1b93a3dfacb3b732dceecc11a705452e37abfb936dc77f0a92e03cfc201cc3c1ffd726a88f71ed54e9875");

// IC constants (IC0 is the constant term)
const IC0: Slice = rawSlice("abe88e4f0eab5b56d68f07f11794f689c9990151fc51024934b6f6abf8902e50f27e95998a30ef74c676d0948725cae9");
const IC1: Slice = rawSlice("a481b836766f5956e2fa03f9709fde22cdd026e4733aebebd81087689d019af92b6a4f4cf171c0d7643ed7eb7907ee03");

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
