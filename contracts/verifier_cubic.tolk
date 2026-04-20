
// IC0 is the constant term
const IC0: slice = "8f7ec83e8c262030b5e3bf0635d08328ec1fd98025e72e36d78e47c03ab29186b7f0bb319795ae70531987752be074aa".hexToSlice()
const IC1: slice = "8a83399e89cdfe9deb00acc467c2c3e7a07383d68def6bf5c3146795b0df11c8c6bf56585a068a1a50d3bd287549c5da".hexToSlice()

const VK_GAMMA_2: slice = "b2935b21a3430da5ea17f4028e3443a78ec188b6f43e11aeac4521ffdbdb5124d5c7dae9bf40314b0651bfa1bd2b08ce07a0efdd5a1b3570db9e31d5f580c89a4c92f3f46a232f33b88d7ba953c1997ea45e49ea8dab9d10770f3641dde38cf0".hexToSlice()
const VK_DELTA_2: slice = "86208cafc8b4c214b2d728ca55a8f3a559d996d1bbf5acf9f42e650a8e21a5dda8095ccea6e796d5031058fbbf52b851170f57bcafd1461f9e1878907e73d779739b81a29b4028943d617f08297609e9b5e7909ccd1bf370a0fe2ede372fcdb2".hexToSlice()
const VK_ALPHA_1: slice = "a865654d7629401a80edac497c4ecaaefc1226c536afac2435d98848c22e94afdbcb8a53e68f011eb2d5a17b4c75b213".hexToSlice()
const VK_BETA_2:  slice = "8bad7d089acdcccef70c4bcd1c837305179decca03c659afe3cd61c1a9a9d74e4427fc163dcd653648051c532a1a28f013589f9fee32a37d0b9cf4a1d3c14fa4880731e96f19f255d8ee7466de0995efbf412ed536cb0975554d6ef77e052123".hexToSlice()

const N_PUBLIC: int = 1

const ERR_INVALID_INPUTS: int = 258
const ERR_WRONG_PROOF: int = 260

@pure fun blsG1Add(x: slice, y: slice): slice asm "BLS_G1_ADD";
@pure fun blsG1Neg(x: slice): slice       asm "BLS_G1_NEG";
@pure fun blsPairing(
  x1: slice, y1: slice,
  x2: slice, y2: slice,
  x3: slice, y3: slice,
  x4: slice, y4: slice,
  n: int
): int asm "BLS_PAIRING";

@pure
fun blsG1Multiexp_1(
  x1: slice, y1: int,
  n: int
): slice asm "BLS_G1_MULTIEXP";


// Internal messages carry public inputs as a custom payload:
// uint8 length, then int257 values chained through refs as needed.
fun loadNextPubInput(mutate payload: slice): int {
  if (payload.remainingBitsCount() < 257) {
    if (payload.remainingBitsCount() != 0 || payload.remainingRefsCount() == 0) {
      throw(ERR_INVALID_INPUTS);
    }
    payload = payload.loadRef().beginParse();
  }
  return payload.loadInt(257);
}

fun finishGroth16(
  piA: slice,
  piB: slice,
  piC: slice,
  acc: slice,
  haveAcc: bool
): bool {
  // Final cpub = IC0 + acc (IC0 is always added exactly once)
  var cpub: slice;
  if (!haveAcc) {
    cpub = IC0;
  } else {
    cpub = blsG1Add(acc, IC0);
  }

  // Pairing check: e(cpub, gamma) * e(-piA, piB) * e(piC, delta) * e(alpha, beta) == 1
  var piANeg: slice = blsG1Neg(piA);
  var ok: int = blsPairing(
    cpub,       VK_GAMMA_2,
    piANeg,     piB,
    piC,        VK_DELTA_2,
    VK_ALPHA_1, VK_BETA_2,
    4
  );

  return ok != 0;
}

fun groth16VerifyPayload(
  piA: slice,
  piB: slice,
  piC: slice,
  mutate payload: slice
): bool {
  // Compute: cpub = IC0 + sum(pubInputs[i] * IC(i+1))
  var haveAcc: bool = false;
  var acc: slice = IC0; // placeholder until haveAcc == true

  var y1: int = loadNextPubInput(mutate payload);
  acc = blsG1Multiexp_1(
    IC1, y1
    , 1
  );
  haveAcc = true;

  if (payload.remainingBitsCount() != 0 || payload.remainingRefsCount() != 0) {
    throw(ERR_INVALID_INPUTS);
  }

  return finishGroth16(piA, piB, piC, acc, haveAcc);
}

fun groth16VerifyArray(
  piA: slice,
  piB: slice,
  piC: slice,
  pubInputs: array<int>
): bool {
  if (pubInputs.size() != N_PUBLIC) { throw(ERR_INVALID_INPUTS); }

  // Compute: cpub = IC0 + sum(pubInputs[i] * IC(i+1))
  var haveAcc: bool = false;
  var acc: slice = IC0; // placeholder until haveAcc == true

  acc = blsG1Multiexp_1(
    IC1, pubInputs.get(0)
    , 1
  );
  haveAcc = true;

  return finishGroth16(piA, piB, piC, acc, haveAcc);
}

struct (0x3b3cca17) Verify {
  piA: cell
  piB: cell
  piC: cell
  pubInputs: RemainingBitsAndRefs
}

fun verifyProof(msg: Verify): bool {
  var piA: slice = msg.piA.beginParse();
  var piB: slice = msg.piB.beginParse();
  var piC: slice = msg.piC.beginParse();
  var payload: slice = msg.pubInputs;

  if (payload.loadUint(8) != N_PUBLIC) { throw(ERR_INVALID_INPUTS); }

  return groth16VerifyPayload(piA, piB, piC, mutate payload);
}

fun onInternalMessage(inMsg: InMessage) {
  val msg = lazy Verify.fromSlice(inMsg.body);

  match (msg) {
    Verify => {
      assert(verifyProof(msg), ERR_WRONG_PROOF);
    }
    else => {}
  }
}

get fun verify(piA: slice, piB: slice, piC: slice, pubInputs: array<int>): bool {
  return groth16VerifyArray(piA, piB, piC, pubInputs);
}
