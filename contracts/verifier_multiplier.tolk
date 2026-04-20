
// IC0 is the constant term
const IC0: slice = "b376d29165d9993a8d552cf15eb0e1171cec3be8510e78fc47beedea5c58bb03bf112338a81d24725f159afb0b46ff8a".hexToSlice()
const IC1: slice = "932b7a28b994b701aa1a4c06a4f3f369cbb0b4ddfc37c380679815504757708b5e63936b01f85b1368e7ae328671b499".hexToSlice()

const VK_GAMMA_2: slice = "93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8".hexToSlice()
const VK_DELTA_2: slice = "b1cd4f856100b2e044982b35efc1b2b8198563e364a3f8ad04042f1b2863f2390b4eec671127429b2c5e718acd9551cb133c975867cd365d64985736dad6c003628a909f7e5bbf6640152497313e057159086a69c687baca50953a71c7ab0d89".hexToSlice()
const VK_ALPHA_1: slice = "b1b83e55445b659621850963559851270e7f209be2ba8ec89529d0705991aa0e369d315ebb4aedb2b38232d29621789e".hexToSlice()
const VK_BETA_2:  slice = "90c699a329380ef521a9022f0abb0f06f072bf81efab4b8d15bc10186b558335f81f8588f0a43f751fda31f427f7f9cf0238b10a60115bd4e51fa1baaa4d6e1dd8797804f40baa93451fd46b04a2884b4e75cfdb584f457b51544e7fe687da9f".hexToSlice()

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
