
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
const vk_gamma_2: Slice = rawSlice("b1baec5a7d199c6bfc4f1b3b9237e647a6a621d374aa4a5161b5dc006b258409780c70a1eb94720564c473cd3782c8ee08ca528856827e1b3c4f494a251be420e784807886699e9ffe651d3a4412b9263843b1960730280edda7ee1faa713c16");
const vk_delta_2: Slice = rawSlice("887309cf944a9ad5375d3e685a22c76047f37e69727098c789e896a9fbd9f427bee9c64faff2750f471747e4304811bc10f923ae97e211ad4d5c2cbbf02e2d0279dddf2310c1f4150967378d55e596d54d83c9c49a2da5b76b2e3cd2dfd13f79");
const vk_alpha_1: Slice = rawSlice("b00f792e499d48b2edf4efbc44f4da86a245752ebf3ecbed56f671eca3a0a1be92e2db10da85fecaafc5a5d7bbbc9912");
const vk_beta_2 : Slice = rawSlice("9981e24ea58c97374990329c5b5bd4f4e9114188a6773cfd778db5c0b3ac0cec8c358da7fa431b639ba1f55edea8125504de3637f8f79190986db8c98fee864ef40e66a103fb28efe85af2711343001eb6a68ccfe190c58991eac8cb61985821");

// IC constants (IC0 is the constant term)
const IC0: Slice = rawSlice("97e66dfcfd558b182b20ca1da8a4087aaa617c5a2ce00c5b09e60cd1270df5abcba5b2183ace79afc5615a3f77851749");
const IC1: Slice = rawSlice("b66fc49d7e6b61d7f5cad2d08863d90f3e78680fb5b7b8e8b6b0e3dbf464475bbeb0b6127bb03a81acd411e6a52797ef");

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
