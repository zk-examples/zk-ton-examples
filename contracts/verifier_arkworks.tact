
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
const vk_gamma_2: Slice = rawSlice("b2ad8b14b088d8e733636ad283a33fa1d07f4bc68e2751ff7b41e602d222667a34705f308a9fb93d3807edc351b5bb9108c69616e984d8f00ab3a0f32789fb22f628ab866de12ff12b21eeb4f9b3774b23ac423cdb441cae7ce4e45bc419c2e4");
const vk_delta_2: Slice = rawSlice("a74849fdb33c6ffee0f2c16704c7be36715fa3d4b8b3479472d06f7364ca587b848e9371a0872746a1424bfa2743afb50245c703c1326e50be17478288ed35998d1ea96727dda5783d8d5024fd903ba33141f159c82f84ec72b81e841492bf96");
const vk_alpha_1: Slice = rawSlice("8e5b5c643d8a97c0f60669ce1c3d3f0fb38331b4fc30bb0ab616ff1ea1f33b7191e9033022a957e9f64d901948a4cb6e");
const vk_beta_2 : Slice = rawSlice("a3db20d891b38d287b576cfc1ade7260eedf7eb859dfabf641868f6edb6504778b03e3afbeb97bbe484ffd8dac4c3071068b64cd8b60485785e3533c59c52f84dd03cfd373254d2f737edb65ba583562db9379d9762bf4fb3cd7df3f8ea9a01b");

// IC constants (IC0 is the constant term)
const IC0: Slice = rawSlice("8ac5e8f7c6a6be828b6a9d61dfd39edeac1470de0d020f105879f0945400db0fa5dcff19aa07f94b1d205ae4e0aa2030");
const IC1: Slice = rawSlice("89c2a2c0be0166dbe04e987fba86692210ad61e6c55b43c0e95137f8e71197111c003f2c34278cd07f279c389309e294");

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
