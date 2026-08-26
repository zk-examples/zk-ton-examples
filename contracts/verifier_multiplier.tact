
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

asm fun blsG1Multiexp_1(
  x1: Slice, y1: Int
  , n: Int
): Slice { BLS_G1_MULTIEXP }

// Verification key constants
const vk_gamma_2: Slice = rawSlice("93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8");
const vk_delta_2: Slice = rawSlice("a0263c5550a3c4b1303a61d7b4ce1ae720b456d2e2920ad200c684ac72026c66402a9a0a959b7c0c8cc7bfac923f0f03145ef5ad63fbb28adbf0b42285790f1c31a7aa799b8d9891123c9bd5c3779860806fa585a22015e6147511b7170d5d6c");
const vk_alpha_1: Slice = rawSlice("a293d5acec945b20b4aa6745cc504f4a728762fee3990798f82083eeec6c916bc42cc001363e33d5da4c14c6b09c7382");
const vk_beta_2 : Slice = rawSlice("8b707ad41a9b06144caccd29889a08ebcfe053789db7f86a66de993dbc8a1412b07d27ad1132a1c2f6ba8a794b5ca8f10522015e623816189232044cfdfe54847f959ea930994cc4f07e34c1e6071b915e0d4915c33ac4e6eae516566ea9ee36");

// IC constants (IC0 is the constant term)
const IC0: Slice = rawSlice("a058eb7bdb3b660d61da9dd8d00e40ab4c470306bee24b24cdcdbca83f285c901cdd45d2ea7b363e9a61d471880438f0");
const IC1: Slice = rawSlice("b5d1579d3571774958fe296fd03ea71a40ecca5fd9f3d111bbb83291edfc99caecc48911866bf0f23027db668442f83a");

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
