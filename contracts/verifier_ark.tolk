import "@stdlib/tvm-dicts"

// IC0 is the constant term
const IC0: slice = stringHexToSlice("afeed53d6eebfc2da813995f7f1a4a6c993b2847b32f7800a6b4fcbe0e397c6baf32aafb269e6e91b8049fde7d12d15f")
const IC1: slice = stringHexToSlice("81842285c4584281e58867185df524aad87efb05e4e4ed4d64829a7cb53d39530140909878bee84ac3b984b1824b79dd")

const VK_GAMMA_2: slice = stringHexToSlice("84a9b33c0d55a6b74581977e92e90e65ef96614ad6d64781961a15e3a0bbd2e5ec43ccec161baed79448308eebdbbbf408a3b3fe2f021d97f8f547eb88fedb088f1784405f3d45ed381087652d8a8cfe73a6a7a2869930d7f9143e1f2d970cc2")
const VK_DELTA_2: slice = stringHexToSlice("b868baac296b0cc569e60f6da8dd2a5a858349b611d19c6e90e3e63de61ae1db6af2a6aa451e48491600b007b6540d0a08ec0c943eef6422fdb96b643f7a661f92a10fbc9a78a0fae13612bfb829e58b0e904921dffbf6658bdbcd21a73227ee")
const VK_ALPHA_1: slice = stringHexToSlice("a1886dc3d23724f1688d467c3d1ba4e23b6d0f3ed54d0ee51a9d98aacb5548e9c6fd7fe6ebe530b522de7501e802633a")
const VK_BETA_2:  slice = stringHexToSlice("891f17239d628ccbaaf34baa187c189abd34d1da3ca795ec7c53a8e64c016a9045728e1dd9ca352c927afa5c251111431731f9d0430af7e1b207f3bbbd5bb97b29e12bac9cef1e4344e9319958152d3bcfd506170b3c36d817121780e4599a43")

const PUBLIC_KEY_LEN: int = 32
const N_PUBLIC: int = 1

const ERR_PUBLIC_NOT_PRESENT: int = 257
const ERR_TOO_MANY_PUBLICS:   int = 258
const ERR_INDEX_OUT_OF_RANGE: int = 259
const ERR_WRONG_PROOF:        int = 260

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
  x1: slice, y1: int
  , n: int
): slice asm "BLS_G1_MULTIEXP";

// IC selector for runtime index: 1 -> IC1, 2 -> IC2, ...
fun ic(idx: int): slice {
  if (idx == 1) { return IC1; }
  throw(ERR_INDEX_OUT_OF_RANGE);
}

fun groth16Verify(
  piA: slice,
  piB: slice,
  piC: slice,
  pubInputs: dict
): bool {

  // We compute: cpub = IC0 + Σ (public[i] * IC(i+1))
  var haveAcc: bool = false;
  var acc: slice = IC0; // placeholder until haveAcc == true

  // Single batch (no loops; non-destructive dict access)
  var (in0: slice?, ok0: bool) = pubInputs.uDictGet(PUBLIC_KEY_LEN, 0);
  if (!ok0) { throw(ERR_PUBLIC_NOT_PRESENT); }
  var v0: int = in0!.loadUint(256);

  acc = blsG1Multiexp_1(
    IC1, v0
    , 1
  );
  haveAcc = true;

  // Cheap "no extra keys" guard
  var (extra: slice?, extraOk: bool) = pubInputs.uDictGet(PUBLIC_KEY_LEN, N_PUBLIC);
  if (extraOk) { throw(ERR_TOO_MANY_PUBLICS); }


  // Final cpub = IC0 + acc (IC0 added exactly once)
  var cpub: slice;
  if (!haveAcc) {
    cpub = IC0;
  } else {
    cpub = blsG1Add(acc, IC0);
  }

  // pairing check
  var piANeg: slice = blsG1Neg(piA);
  var a: int = blsPairing(
    cpub,       VK_GAMMA_2,
    piANeg,     piB,
    piC,        VK_DELTA_2,
    VK_ALPHA_1, VK_BETA_2,
    4
  );

  return a != 0;
}

struct (0x3b3cca17) Verify {
  piA: cell
  piB: cell
  piC: cell
  pubInputs: dict
}

fun verifyProof(msg: Verify): bool {
  var piA: slice = msg.piA.beginParse();
  var piB: slice = msg.piB.beginParse();
  var piC: slice = msg.piC.beginParse();
  return groth16Verify(piA, piB, piC, msg.pubInputs);
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

get fun verify(piA: slice, piB: slice, piC: slice, pubInputs: slice): bool {
  return groth16Verify(piA, piB, piC, pubInputs.loadDict());
}
