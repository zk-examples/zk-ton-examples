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
const vk_gamma_2: Slice = rawSlice("b2935b21a3430da5ea17f4028e3443a78ec188b6f43e11aeac4521ffdbdb5124d5c7dae9bf40314b0651bfa1bd2b08ce07a0efdd5a1b3570db9e31d5f580c89a4c92f3f46a232f33b88d7ba953c1997ea45e49ea8dab9d10770f3641dde38cf0");
const vk_delta_2: Slice = rawSlice("86208cafc8b4c214b2d728ca55a8f3a559d996d1bbf5acf9f42e650a8e21a5dda8095ccea6e796d5031058fbbf52b851170f57bcafd1461f9e1878907e73d779739b81a29b4028943d617f08297609e9b5e7909ccd1bf370a0fe2ede372fcdb2");
const vk_alpha_1: Slice = rawSlice("a865654d7629401a80edac497c4ecaaefc1226c536afac2435d98848c22e94afdbcb8a53e68f011eb2d5a17b4c75b213");
const vk_beta_2 : Slice = rawSlice("8bad7d089acdcccef70c4bcd1c837305179decca03c659afe3cd61c1a9a9d74e4427fc163dcd653648051c532a1a28f013589f9fee32a37d0b9cf4a1d3c14fa4880731e96f19f255d8ee7466de0995efbf412ed536cb0975554d6ef77e052123");

// IC constants (IC0 — constant term)
const IC0: Slice = rawSlice("8f7ec83e8c262030b5e3bf0635d08328ec1fd98025e72e36d78e47c03ab29186b7f0bb319795ae70531987752be074aa");
const IC1: Slice = rawSlice("8a83399e89cdfe9deb00acc467c2c3e7a07383d68def6bf5c3146795b0df11c8c6bf56585a068a1a50d3bd287549c5da");

// Error codes
const ERR_PUBLIC_NOT_PRESENT: Int = 257;
const ERR_TOO_MANY_PUBLICS: Int = 258;
const ERR_INDEX_OUT_OF_RANGE: Int = 259;
const ERR_WRONG_PROOF: Int = 260;


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

    // --- acc = Σ(v_i * IC_{i+1}) (ONLY public-dependent part) ---
    let haveAcc: Bool = false;
    let acc: Slice = IC0; // placeholder until haveAcc=true

    // Single batch (no loop and no ic())
    acc = blsG1Multiexp_1(
      IC1, getPub(pubInputs, 0)
      , 1
    );
    haveAcc = true;

    // Cheap guard: reject obvious extras
    nativeThrowIf(ERR_TOO_MANY_PUBLICS, pubInputs.exists(1));


    // --- cpub = IC0 + acc (IC0 is added exactly once) ---
    let cpub: Slice = haveAcc ? blsG1Add(acc, IC0) : IC0;

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
