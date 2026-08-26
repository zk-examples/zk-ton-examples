
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
const vk_gamma_2: Slice = rawSlice("a675327c829e5b91bda0c74ea5e2aab5deb8f7234b84d6749faf7aaf47f2696184cffbcb14db5264cccded472365042b12e95f7eaa3db2dff2aaef31e498cbc485edfcf3b9f99b98c96d1c478b57ec271f1fd9d1ae07f31ce01b9c1c0a627be7");
const vk_delta_2: Slice = rawSlice("b18316181b215d548c4d7b4ab46a54c50be8247a33ee083e3dab554e89f4bc148a8ea7b387a58b7cc3c4b038058bed15115da63608cffae9f3c28bac13248550d43b7c4073e97ef91fbf38bd688c4cf07211c90294411f6cf1ec38f9d0abfdfa");
const vk_alpha_1: Slice = rawSlice("a3ef176c29c30cf6559de423749545db6df6b46aa18ca13d6454ca86d0e65c50334724992069b0bff691858f893f5fe9");
const vk_beta_2 : Slice = rawSlice("af5ad5e38f26ae21399825f6a091b6a767f0af56a956b18de28163c93de845df64809447a6684965a771032922be7ff612e0876845107389f984f73b532129105cc8c011382c10a32a3b791f09b5cc8feb8bea3e558c1498b47db1ea4a409838");

// IC constants (IC0 is the constant term)
const IC0: Slice = rawSlice("875cf3146825ecae46d32006ffa975b5915c3dbf9e3599f57589c03df1cb800d79c198fea715083b10b9d193205eda37");
const IC1: Slice = rawSlice("87a5d132e933ab501536a91cbacb50635e1342d2f23b17f8cef7d9ee17d68b5049549534cbf2111e5ed11b9b80dc9b63");

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
