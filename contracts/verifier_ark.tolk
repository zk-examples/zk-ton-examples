
// IC0 is the constant term
const IC0: slice = "afeed53d6eebfc2da813995f7f1a4a6c993b2847b32f7800a6b4fcbe0e397c6baf32aafb269e6e91b8049fde7d12d15f".hexToSlice()
const IC1: slice = "81842285c4584281e58867185df524aad87efb05e4e4ed4d64829a7cb53d39530140909878bee84ac3b984b1824b79dd".hexToSlice()

const VK_GAMMA_2: slice = "84a9b33c0d55a6b74581977e92e90e65ef96614ad6d64781961a15e3a0bbd2e5ec43ccec161baed79448308eebdbbbf408a3b3fe2f021d97f8f547eb88fedb088f1784405f3d45ed381087652d8a8cfe73a6a7a2869930d7f9143e1f2d970cc2".hexToSlice()
const VK_DELTA_2: slice = "b868baac296b0cc569e60f6da8dd2a5a858349b611d19c6e90e3e63de61ae1db6af2a6aa451e48491600b007b6540d0a08ec0c943eef6422fdb96b643f7a661f92a10fbc9a78a0fae13612bfb829e58b0e904921dffbf6658bdbcd21a73227ee".hexToSlice()
const VK_ALPHA_1: slice = "a1886dc3d23724f1688d467c3d1ba4e23b6d0f3ed54d0ee51a9d98aacb5548e9c6fd7fe6ebe530b522de7501e802633a".hexToSlice()
const VK_BETA_2:  slice = "891f17239d628ccbaaf34baa187c189abd34d1da3ca795ec7c53a8e64c016a9045728e1dd9ca352c927afa5c251111431731f9d0430af7e1b207f3bbbd5bb97b29e12bac9cef1e4344e9319958152d3bcfd506170b3c36d817121780e4599a43".hexToSlice()

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
