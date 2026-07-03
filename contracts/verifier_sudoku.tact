
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

asm fun blsG1Multiexp_7(
  x1: Slice, y1: Int,
  x2: Slice, y2: Int,
  x3: Slice, y3: Int,
  x4: Slice, y4: Int,
  x5: Slice, y5: Int,
  x6: Slice, y6: Int,
  x7: Slice, y7: Int
  , n: Int
): Slice { BLS_G1_MULTIEXP }

asm fun blsG1Multiexp_4(
  x1: Slice, y1: Int,
  x2: Slice, y2: Int,
  x3: Slice, y3: Int,
  x4: Slice, y4: Int
  , n: Int
): Slice { BLS_G1_MULTIEXP }

// Verification key constants
const vk_gamma_2: Slice = rawSlice("93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8");
const vk_delta_2: Slice = rawSlice("b4bfd639d8f5a96305cf207bb94632173db2b57350a05e8128968865e577f19a5f41646a1cb6fa6b04a0006c707b78e215513f32bc5a88d5115104db9f930495b6a485c80286f9ce53e3391d07932b57ea1dd7b0569992861426625a94014565");
const vk_alpha_1: Slice = rawSlice("898fa827d4b477572bb5da333fc4a55abeec587f89a709b03d661b24c930c65b83786d3e8e346803108b469db6c173b6");
const vk_beta_2 : Slice = rawSlice("b1ca50a8f15114069787390fc54a4da790aea5755a4ec885bae0e057e2d236247b293027fffb5d4f9e5da95f768e229911cbe751d28889675e6ae6f2ecf61bb2342680c5933ee4973fda8e341d3ad9c33a80db3f719f6475bace7778997115ff");

// IC constants (IC0 is the constant term)
const IC0: Slice = rawSlice("a3ea51dde407a9129d0c19410e134cdd9858a0659a58a0b82a244dda789e87db938fd2a9051c60847bac19c1cd8c1374");

// Error codes
const ERR_PUBLIC_NOT_PRESENT: Int = 257;
const ERR_TOO_MANY_PUBLICS: Int = 258;
const ERR_WRONG_PROOF: Int = 260;

// IC selection helper by index: 1 -> IC1, 2 -> IC2, ...
fun ic(idx: Int): Slice {
  if (idx == 1) { return rawSlice("ab62a6fb9aa01ebd454c04f9a201d36cb8361d86c609e398391d012dc55113c511780acf91faa9dacb2dbb1c3d3688aa"); }
  if (idx == 2) { return rawSlice("a2dd6c28cc06a27c1098777faff31dd08afcc30ffc0288b0a508a2b0854cf7d442910c74145741ab3d0ca6cedaf178dc"); }
  if (idx == 3) { return rawSlice("95a263416220992ceeea9eaf113fe03fe72dd8420fbbe07bf8b535da21b4028d3e6ebcb46e14209eb880fd03840ccb0e"); }
  if (idx == 4) { return rawSlice("8fa8760e4b0befc067379680db3e679e4af4a00ee9dc0a21885310524b9fbfc44de482a69f4ea99711bd3a4f22a1a383"); }
  if (idx == 5) { return rawSlice("8e341cc5c63f41bdb765d9e5f980b0078c5de2236b6722cff0b70cfe5c49230bc7fc73470a95794c7a8a5115acd925ec"); }
  if (idx == 6) { return rawSlice("ab74fceda6dc673d3689ec26c5ddc224c2172e975d009cf7e7cc61a0fbb4c0448f882d672d6d95c7457ca476fed4af21"); }
  if (idx == 7) { return rawSlice("8bea0ecf543600ae53d7f4efe1ce8c5ad70ec49b6cc794d5c5255c54cf03e2f1617cf32b0471b5e4515bbbc84246cf06"); }
  if (idx == 8) { return rawSlice("8a422e533b06400f423da1cc4ef32ada9eb43a1d9ded29a8021b80212c68702b947784339ff0ca929457795bfd90ae7f"); }
  if (idx == 9) { return rawSlice("af0dfac94af98500900c7dea600974fe9fdafe749fd48cbbdb3096a307883e727a2557a4ca01210e8f2e09585a77cc40"); }
  if (idx == 10) { return rawSlice("980cd7ca174c1042c291ef4c2e8719a893ae191a24c80fdd35a9fac6db5c710d953da4c42ffe19c3a0905a7e5c0b683e"); }
  if (idx == 11) { return rawSlice("80c0955b49d057c503dda290e92662b00b0d362ef6a5b04efadb58ce09e29a1f33fdac1e81f16d18e65ea9aa270d619c"); }
  if (idx == 12) { return rawSlice("afc0c2d32dde46c798fa429190d469d66deabbb0dbd11e0524862d639ed837be799bd1fd29559d1497f51334212af4bc"); }
  if (idx == 13) { return rawSlice("83210b942e41a606b2d580c802fe668d0827b326b4bd552073f16f8f36e4424116e59782dc5916f028d3d3e3cd6bb392"); }
  if (idx == 14) { return rawSlice("aaca8dfc2f3f0658b93096b4a20174a00f4ddc651cd222e7c37b8f00d2163b4da4dbf793a42ab0dfbaa1bd02ec05b1fb"); }
  if (idx == 15) { return rawSlice("8cca5d93b295f3728da7608239689b0584002c369ac2fa954344205cf22752c5f23521fc38f66e085ffbac768be38d32"); }
  if (idx == 16) { return rawSlice("99083aaf45ffd1858d080701cb42d08d2e4a3d57980712c398047f7d8838e88b81e615e85420c268cdea7ff49450351a"); }
  if (idx == 17) { return rawSlice("b70ba625fcd5e4bb0c9cddea50bf1855fa6df270c6ac9938a1f3170633eab13781f6a96dea750b0414881e8214ccacf2"); }
  if (idx == 18) { return rawSlice("b350ee10a6a50140148d3b93946e9896c646be6a6efcc1c0be83f60bb569c1d962d79ce995ec90a7c5d127964e78e950"); }
  if (idx == 19) { return rawSlice("897ad115a2e3ef79c41456d48c94be03a85103349184f5d93ec407c1b0f0fb9d54905fd537534a2e6550ef7c7f502376"); }
  if (idx == 20) { return rawSlice("9208c9b999f50b4013ec049cfe4033fd86d7206eddeec866b9bbbf3ca00d3c04da6af44592ed78d29460d2f19711cc76"); }
  if (idx == 21) { return rawSlice("99bf6c0822bc974229a544d4e7c4170a444d4b220f838e915bb719e585af61a031ecece19c339068756f6872936d54b3"); }
  if (idx == 22) { return rawSlice("930f9959d647f0f4c7e26c0e8ac5dc7255e294153b3072f783c38a7ee641860cd8ff3296551787eab8683868a25329fd"); }
  if (idx == 23) { return rawSlice("89a8b03e79571798507b360203467d5e3731fa12371c18e52f9ce477378235f9be88df2ec09b02f0647b08b3669981f7"); }
  if (idx == 24) { return rawSlice("962ee1ba546c30e999650c6f3a98323e608bf53ee115b2cc362c6edfd2429b2e2717c4621a36620f0198c60bf5540201"); }
  if (idx == 25) { return rawSlice("9893d7480fc6329d9024cf4c757bc3cd5b658b1dba1a1ceae6ac033cc2f36336bdc04dc6d0558a5eace0610694cd1629"); }
  if (idx == 26) { return rawSlice("92948bae97bbfaf61e7c77c52d24a33bbadd39f91a0b3de0a00240018255c84af479fb26028f9880e29e671513cee8b5"); }
  if (idx == 27) { return rawSlice("8f8e016d528663ee75f14ad7d9026509afa7ac127a68c0d7fdb537479070e7f7a40c267d31016ebc9ac61e33f7daf76c"); }
  if (idx == 28) { return rawSlice("93c6907e90925ad035f19d68e9c06b313f7efe5eb508ca91d54390d9a13cee483490a29db84a55512b4464985105c564"); }
  if (idx == 29) { return rawSlice("a45c219bdca3631fda2281c9c1d5eb9cd6818c48beee3d5e5bd3f976dcdd21e5257764c68a06cbcfc76038e1e936b14c"); }
  if (idx == 30) { return rawSlice("af6c30d61e8bb834e1fdee1803cf2ce38ae36924b39ff469e1167dd8132a319134abc956c79c61d8e698e96ce4ef4b98"); }
  if (idx == 31) { return rawSlice("909ac9d0b81a3fddeb1c51a75f9b38dc3a206bf5612e2621899e15d17c90cdd58561f1283248202f2028d7df15103f31"); }
  if (idx == 32) { return rawSlice("ace43589a63a4fc873cfa1f115665d666ddc6faad6b8be7fc95019489509b148587e7ae01ad0c3a8dfe13fb83d72c923"); }
  if (idx == 33) { return rawSlice("8a0318d3abf0301bb929e0067813439a25e29a9c8cb08383459271b65af0f6a018703c8fc8b76b99d83b27d90ef56860"); }
  if (idx == 34) { return rawSlice("8ff81600f4b9f06b84e5c0f2c9f957faaa92b10272274a5515dc12bcb31f693f8109ce16633d43239812cb330a339468"); }
  if (idx == 35) { return rawSlice("893dbc51dcea08e97df04f143ad00fb769c49dac7fab86285de5fd03334c1d4d0102c9df4c8aeeb4e4220b4b722b57c0"); }
  if (idx == 36) { return rawSlice("9966db395def8244f06b1a56d0940ef9854e159d8f0f64a9d414014a3c01276e196ed7770f8b55f95a491ceb859904f7"); }
  if (idx == 37) { return rawSlice("954a06fc7cfa7f15be830969202631b4634e2ffef309672b95e8fc3c74cb3528d08d617d53f7b03497e7595f62563d86"); }
  if (idx == 38) { return rawSlice("8dd4d7ac59e7fcd8feaf647a118d0ce7cac51e34ebc8e759cfb92c19ac7ce03839c326ae2235381b069e24d5229b91c1"); }
  if (idx == 39) { return rawSlice("87d3f232af69141f38fe21d48f97643200966206932abcf3e8e5714e0f6bb1091420357390db70aa0505562e97327b57"); }
  if (idx == 40) { return rawSlice("a449796945998cfade568bb0af35b5a82a39d0a085672e26a81d6c91829eba2e91990aaf0ab62d3ba0fa2d60b8a083c3"); }
  if (idx == 41) { return rawSlice("ab95da45dfcf3dd4bc8ac64d2f8f7c50676128d11ffde8f3420a6e7501039d7ef1e0806f7565c8f59c6a2b022484dadd"); }
  if (idx == 42) { return rawSlice("82f9194937c386d8a269c4cfeeba2eb1f31dede26aaed706b4dd82a39027a34e9e810e5c61f680d87c205dc4c0aa0f84"); }
  if (idx == 43) { return rawSlice("b0695fe04b9f10745fa8798d28a540c72f5e697ebde972e91e8950c059db938b1a1401197c3cfe3990a54ac553f0858b"); }
  if (idx == 44) { return rawSlice("a3e4b1fc2c87a8c8f3831a80a3cf05af769f2238ff10b31d1d256fa4b43bd3945f0c42e6a649954d60358b866dc1af6b"); }
  if (idx == 45) { return rawSlice("b6f6eb9a1ac60a4fd0c86cec4b733d8f483111cf29fbce12fb3dc5c07d2f574128ef4872b4df50fa5cce76395ade29a4"); }
  if (idx == 46) { return rawSlice("9214e2a37f6e92007976e2e30207ef2ec99743290a20836d48a115f7ae08aa77a644b7c78797896edc7bb06accc65a11"); }
  if (idx == 47) { return rawSlice("929cd64feac0fa169d234490b78b24d0c07323d23be28488f480020a91ef0563829c48f8ab8d21e2d5e57bff2f3029cf"); }
  if (idx == 48) { return rawSlice("b97624e8b2a7da5a3637426141e85135c5e5417e788a61ca5bbd23baa93b4387021b8788d6134161a5b74d0a49105dc3"); }
  if (idx == 49) { return rawSlice("b93d5a5323061c3281b91fe0ead06881bb695b4d962b55c14429b0204c132f527fcd2c04fbe58571ef5f2953b781a3ba"); }
  if (idx == 50) { return rawSlice("a6a75c931c8f7333a834e3ccfbf8e73cd12630d22d3829fc23f7978c9e44ec8055c1a968c5e0f9dbb286b66f8d2212ce"); }
  if (idx == 51) { return rawSlice("afa6e80bd1cdc4bbdacfcc156231b6f3e9244745dac0f58809a7afbed30e8d61e299e95c7fd0547707b2c4d810546cf0"); }
  if (idx == 52) { return rawSlice("93e6510a3f218de078c199d03886bac73a752d2cde4967490a70229431eb5ffe485c9559c4d06ae1d81c9351f0c4f852"); }
  if (idx == 53) { return rawSlice("918f42852f5f2d66e56bec62ff411705ddb7ac4a0352b8e52ca5ec8a7c7cf6bddae2855bab9150e81778a5861ee76a54"); }
  if (idx == 54) { return rawSlice("8d6be9e0ff3d2c1a8bade55aea1c26ef2f5caabbbc9659ade730685ab1751ffe509bec5fd69b8fc637daa015db14d46d"); }
  if (idx == 55) { return rawSlice("9319a0caab436999a1034fbe1e40996e0146c37265f7e62daaa1a1ceae26ab1528bcd703aa9c97956e6e24caf904bffe"); }
  if (idx == 56) { return rawSlice("ae809be47708ceec37ee6dbfeb1a3e391f57957b1de52c2b91b3f81eeff4f04f8b7759646b4e13293c3503477d8a6f83"); }
  if (idx == 57) { return rawSlice("b3af6bfe7bd9b31c34e39b726f9afab182a822900eb0e19703f559965ca3feda4b23a457c4a6841fa9f3ccabd6de586d"); }
  if (idx == 58) { return rawSlice("953b5737f1ae4f02b56e3d43ea1490eb607a038f6cc23a030114543bfa2e973f2585436c116aa5b84f3e029352e31884"); }
  if (idx == 59) { return rawSlice("a7334e5ae444518ac9f8a927e11b04646a50a1789fd04049d30849ca597fcf5455e14a72ebbf8ab0444015f88c5568f7"); }
  if (idx == 60) { return rawSlice("952929f855a9c31572e162d9b1cc5e996d70845376c1a71187afa9bdfe1c064904e10303e68b2ecaa61d65c795e7bea0"); }
  if (idx == 61) { return rawSlice("856feca583574015bb02bcb4e0c8dde99edfee518cef892dc262e627ab59299466f02fc82a8ab006a5a6ea57dace0460"); }
  if (idx == 62) { return rawSlice("ae26ea2f6e016f464593f0cc36960d16057208f58e9ba4039c7bfb4a606170760465700eea440079633c765427781b26"); }
  if (idx == 63) { return rawSlice("a9aa873eaed82a7825af515f8aef62f974b7569ed37c1323c4b632e7776af707bd504ff33b91861712f435d0acfc4f57"); }
  if (idx == 64) { return rawSlice("8707a4d42c098491768148ded272259d2689c00e98a43c798ddf125c4db56decce556446de1acccb1e05aa85f382e825"); }
  if (idx == 65) { return rawSlice("b27530a8740e220f86bd3eedffacd0b39a0b6cafa8a468e0fd782bdba90331a9f05085a55f385db8b6797646ae97d96a"); }
  if (idx == 66) { return rawSlice("8f721d1463c3139aa60ecf2ed309f76e1428e580ce0e1b969bb4071fac84482e3c4fe2419d63639554fcb159cfc12d78"); }
  if (idx == 67) { return rawSlice("97a4cf60aeff279bfdbb24c6384fde68f9892d9f46d72fcfe248ffb7bc0755fe94842e2ee68747758a3d02c071d1a4bd"); }
  if (idx == 68) { return rawSlice("a4d666725b058d4632ce3226819195c0760b13a0932dbc163c216416e5465ad95aeeffcde437d677039a05fa3224b6a0"); }
  if (idx == 69) { return rawSlice("b0f96ec60ca6e42a47ce9169887e77b060c7ab5fb0402702a9614cd461273f9690dd6af99ec2b6fad46d493612dc5119"); }
  if (idx == 70) { return rawSlice("a8fbe926379bfa0e3ce98e146c67f7bc2c019b4226dd38e4b0a7aa0a5cbba8bbf6a36a524a4da71178cde590f51a80d0"); }
  if (idx == 71) { return rawSlice("93a6cbb4623aacc594cc8e9e506c1e49c92e2a4b45f9233e07244d64af9f344bc223e9ef83de3d7d31710e10d0cb7c1b"); }
  if (idx == 72) { return rawSlice("a137048f69d6236035b6243095c16f793c0bbfa12936ff872b182d9ebff5b8c210dd2e31b45c3085f2dcdbdd277c7955"); }
  if (idx == 73) { return rawSlice("8f61b8e542c6821b8fff7423af73217229e71098769cdd6da16228729ac6626d5dec225b383bcd63840c0906678f417a"); }
  if (idx == 74) { return rawSlice("99fce44c02c4492b973b7e4d3d0a468f535e4baee2cb1dff3d521107f0613417024bd668e6183564facbb6d229acc8fa"); }
  if (idx == 75) { return rawSlice("aed563162af2940e651ab7dad17706b10c8098710284e04b6aef97237a96ebc52a6c65405a813167a7e1289f3dfc04b6"); }
  if (idx == 76) { return rawSlice("8b2452babd9a4c87ff1de3d96d5be6e4ea158252ee93eb8454963afa54119bc650fd3eac96d712a7e4909d870ab9ec1f"); }
  if (idx == 77) { return rawSlice("90e8f841be5b0c3d343196bf5be61e60be5d20fed691774f41cc4c9334e951119203d62cd01bcfe8af16f4d2308c4c04"); }
  if (idx == 78) { return rawSlice("b8a832d8c36d81f5b55c95692364ba4fddc44b0d511c3fce46cfd158e131fc1a3be82b07fcae45d1439d61647e18cd77"); }
  if (idx == 79) { return rawSlice("aaf56c38b47ef2b3ef2f8fbf57958e49c749d61c6da4fbe914e54fee7b9499fb6ab0e6c6e25d4cc13a07ae99905636a1"); }
  if (idx == 80) { return rawSlice("8dbaa11bb85d6467c4f5e5df8631c5dc29a78ee0a099d151dc50cd43bea538a92c89cb8e7e601c1f92118a992a971e20"); }
  if (idx == 81) { return rawSlice("a63d2d553158a16f8cbb75dfeabcf2b26a3051b145ae1e8aff6fc80285578e4c5edb693e1905b35a21557e75ef36364d"); }
  return IC0; // Unreachable for generated batches
}

fun assertNoExtraPubInputs(pubInputs: map<Int as uint32, Int>) {
  foreach (key, _ in pubInputs) {
    nativeThrowUnless(ERR_TOO_MANY_PUBLICS, key < 81);
  }
}

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

    assertNoExtraPubInputs(pubInputs);

    // First full batch of 7
    let done: Int = 0;
    let batchesLeft: Int = 11;
    let acc: Slice = blsG1Multiexp_7(
        ic(done + 1), getPub(pubInputs, done + 0),
        ic(done + 2), getPub(pubInputs, done + 1),
        ic(done + 3), getPub(pubInputs, done + 2),
        ic(done + 4), getPub(pubInputs, done + 3),
        ic(done + 5), getPub(pubInputs, done + 4),
        ic(done + 6), getPub(pubInputs, done + 5),
        ic(done + 7), getPub(pubInputs, done + 6)
        , 7
    );

    done += 7;
    batchesLeft -= 1;

    // Remaining full batches of 7
    while (batchesLeft > 0) {
      let tmp: Slice = blsG1Multiexp_7(
        ic(done + 1), getPub(pubInputs, done + 0),
        ic(done + 2), getPub(pubInputs, done + 1),
        ic(done + 3), getPub(pubInputs, done + 2),
        ic(done + 4), getPub(pubInputs, done + 3),
        ic(done + 5), getPub(pubInputs, done + 4),
        ic(done + 6), getPub(pubInputs, done + 5),
        ic(done + 7), getPub(pubInputs, done + 6)
        , 7
      );

      acc = blsG1Add(acc, tmp);

      done += 7;
      batchesLeft -= 1;
    }

    // Tail batch for remaining 4
    let tail: Slice = blsG1Multiexp_4(
      ic(done + 1), getPub(pubInputs, done + 0),
      ic(done + 2), getPub(pubInputs, done + 1),
      ic(done + 3), getPub(pubInputs, done + 2),
      ic(done + 4), getPub(pubInputs, done + 3)
      , 4
    );

    acc = blsG1Add(acc, tail);

    done += 4;

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
