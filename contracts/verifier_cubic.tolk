import "@stdlib/tvm-dicts"

// IC0 is the constant term
const IC0: slice = stringHexToSlice("8f7ec83e8c262030b5e3bf0635d08328ec1fd98025e72e36d78e47c03ab29186b7f0bb319795ae70531987752be074aa")
const IC1: slice = stringHexToSlice("8a83399e89cdfe9deb00acc467c2c3e7a07383d68def6bf5c3146795b0df11c8c6bf56585a068a1a50d3bd287549c5da")

const VK_GAMMA_2: slice = stringHexToSlice("b2935b21a3430da5ea17f4028e3443a78ec188b6f43e11aeac4521ffdbdb5124d5c7dae9bf40314b0651bfa1bd2b08ce07a0efdd5a1b3570db9e31d5f580c89a4c92f3f46a232f33b88d7ba953c1997ea45e49ea8dab9d10770f3641dde38cf0")
const VK_DELTA_2: slice = stringHexToSlice("86208cafc8b4c214b2d728ca55a8f3a559d996d1bbf5acf9f42e650a8e21a5dda8095ccea6e796d5031058fbbf52b851170f57bcafd1461f9e1878907e73d779739b81a29b4028943d617f08297609e9b5e7909ccd1bf370a0fe2ede372fcdb2")
const VK_ALPHA_1: slice = stringHexToSlice("a865654d7629401a80edac497c4ecaaefc1226c536afac2435d98848c22e94afdbcb8a53e68f011eb2d5a17b4c75b213")
const VK_BETA_2:  slice = stringHexToSlice("8bad7d089acdcccef70c4bcd1c837305179decca03c659afe3cd61c1a9a9d74e4427fc163dcd653648051c532a1a28f013589f9fee32a37d0b9cf4a1d3c14fa4880731e96f19f255d8ee7466de0995efbf412ed536cb0975554d6ef77e052123")

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
