
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
const vk_delta_2: Slice = rawSlice("86c7fd514b7801c3f3c272305fa294f6cce20e31fef57720a523c917baad6a524e19c3c3f7ad4dfeed890d5b7e2366d00c29c28c6d0647f9e4510dc5239b5222223d7910ebd60b89cfe8ddf078353d6d1496c9498d0036be7ca7e97607b47c55");
const vk_alpha_1: Slice = rawSlice("8be4fc24dcc420432f0d3d85457acaa7e7015fcb7b37b0742b7397694672a6a7b6cc64531a8ff08c91b8f297aa016a37");
const vk_beta_2 : Slice = rawSlice("85ad47cf25222ba7131730347722d8b7be38e8bbf49a7fd9e496541d4356dd51c71d0b80ac9f14f4e594f046776fd7790d7cfdcb8c702635290b0cb42fd4f0f40ae4ca23881df3f89a61c9f7b188efbcb89769c4f133a5a75b2f141ba38e22e2");

// IC constants (IC0 is the constant term)
const IC0: Slice = rawSlice("894d7645fd007da208d0d53b971f3fc21ea4296738081f39fef400b73d66b8daa2fe39ac057f4c4e86a58b350235a74d");

// Error codes
const ERR_PUBLIC_NOT_PRESENT: Int = 257;
const ERR_TOO_MANY_PUBLICS: Int = 258;
const ERR_WRONG_PROOF: Int = 260;

// IC selection helper by index: 1 -> IC1, 2 -> IC2, ...
fun ic(idx: Int): Slice {
  if (idx == 1) { return rawSlice("a4f9108f8a40b5c3f2e327f8f1d98470781de904e3d406796508bfb612bfe6e4b9e6fe5a51cd5d9d85b29069bbfd1341"); }
  if (idx == 2) { return rawSlice("8e4449514f7dcca5b34afb82ee82d6c3b6d1616ad1779dab8d7037d1f98b25a8252716116d6043b2686dffb927048d5e"); }
  if (idx == 3) { return rawSlice("8c684040e5b0df404c6efa3b3491ee94b4cd267f48db610bf36c0ea65e6554054fa3e26364051ce2c27639503c4cd7da"); }
  if (idx == 4) { return rawSlice("83e49acdb4bb0e97a104952aa8558aa998d50e14de4bc4b5fefb17730f0fb9109b7a7158c8a994cdd0529a2ee1325ce9"); }
  if (idx == 5) { return rawSlice("8516cf5a333650d7c1ba70da6cb0d7b800b7182e36c3627b554b6fdbe5c1ff585aa32c96ed6e6ee173d9875799e36de0"); }
  if (idx == 6) { return rawSlice("a50cb11340a27f70fad19e9d8a231a077e1b83e92bd6ba621c731b66981279b24381551b337ed838062c1eef3ddff669"); }
  if (idx == 7) { return rawSlice("b98e89508cc89d2fbd120854ab97132c1278648a4645b8a72a53abede6c046e1e7f6c61b58c83c228832a01a48a3ba2d"); }
  if (idx == 8) { return rawSlice("b638b02a418031511e22593878a87b85a86d01be35860f8279f2420441adb7423f650985ccc8aee56733f2f256efccf1"); }
  if (idx == 9) { return rawSlice("871318c45557be2d1344c3dfc7a4f9c803bc9df5411a2c5c4b7e72fb38739fc6877da605ea462d39f5ba10076e63cb03"); }
  if (idx == 10) { return rawSlice("aa1b88912eb893f7ee803d3b097a6dbce82e43ed5d56baaccca2808193b2baec2c78f13862e4aceaffd51622b3c0c52e"); }
  if (idx == 11) { return rawSlice("818a37f1f0911ac8dce3b91541dea55902936cd0dba9206d5d96ec4aa2d9e6d8b73f64c42bc24173ada6b3e4cc4c4c6a"); }
  if (idx == 12) { return rawSlice("b67017d7f360bbab5495f0630208fb0f03842942b3dba7c86de9469891a2176e8aa22d13568b4ece019032dd6e708236"); }
  if (idx == 13) { return rawSlice("977dbb599796ecd5357fe099b7cc43011bb26bcf14bc8e4216df00a51d163c2b7b1d15276ddaf0d97f8018268bd31431"); }
  if (idx == 14) { return rawSlice("b534b8ebfd7617289a623b60f73e16e9fff09b933cfb91c0728069949ee2df66ffb2e605b38b5b07e8cd1b0663ccd68a"); }
  if (idx == 15) { return rawSlice("b821262e1c6930890d893bfe040ed6b4102e67d41a49fcca072be0b55af109c86e25ed6aaeace4d327484e2cb16a27ab"); }
  if (idx == 16) { return rawSlice("9127cef9f1f94f312094b4f8a2bcd46f0ae490403d6b1bde9c870183fee6a9e9a897719f2319e1408303c62bd7bd34f1"); }
  if (idx == 17) { return rawSlice("8fe4a5c2815df11da0b92b9a666044f91a17a054fa1541ddf0b4b973b46c33e28ea1d2cd4e27a860280686edff7a82d8"); }
  if (idx == 18) { return rawSlice("b915e105d184036a6074e0068b7219077834ba2165566eee1c703894919d17d95db495f39a1ebd509c092b2ad928c9a3"); }
  if (idx == 19) { return rawSlice("a58d8fbbce4eca8f8b6117d5a0dcca1aff783cb742d447e882b6df2d73652254e3c1c3285904ef3376c92f1d523ea303"); }
  if (idx == 20) { return rawSlice("8d5685ac29e8755e106695e2073f34fdfda1d2242bac706b4f326554f59e1c2531511dff0ba60665b8153a4189299b0d"); }
  if (idx == 21) { return rawSlice("afcaa1d7e99d63301d31924c917cac23fee87d88fcf40489aebdf119ca926d81ad352524d5cff404086f1482720102fe"); }
  if (idx == 22) { return rawSlice("af63d6076bf7942fa9b2931d47af62e6d90a88467629df3442a05fce4fdad587a0b9f1ef6c1ae84098fa991601416595"); }
  if (idx == 23) { return rawSlice("8fda6afa4ad460a43585e95495a10fc1cf91855f8d4f4bb1390773db84a306de61f4befb2c357e2f066eea7ab6b15181"); }
  if (idx == 24) { return rawSlice("a5272adee1c15d7a0db186e653a0a4b9fbd56174551a6a9aa47cdae494b93d09357a13d60d998f2b04538b7e33467e69"); }
  if (idx == 25) { return rawSlice("a2d6b7ea23cda7f96c0433978d3c789a808fa22b8bf3330b25dc3fc9e3be03c5a7786362ca3c4191aab3c932e5ff9aa0"); }
  if (idx == 26) { return rawSlice("95013657c737e94813224331ed0bf6eb97624605b902d1ef7a45853a2c775408ee11a9355893f238f5b3569f177ba577"); }
  if (idx == 27) { return rawSlice("8a7329b282eaefc149035039ab82792a42b06d1f1926fe5e9b035eec036d88e994d90c149ed9d9c6e16e4b0c66c7ee66"); }
  if (idx == 28) { return rawSlice("ae1f51ed5a1b5d2acbd536a00ddd0f9cb524f4228b4050849cf2886f1b63b0d026be90496cfb2d19453eaccffa689a7d"); }
  if (idx == 29) { return rawSlice("b00007b3447ce35cb4fe3d15f6d0a910ea37ecdeace02182c1d2e80914fb4030aa0d155231d63adbe9256b332f06a88e"); }
  if (idx == 30) { return rawSlice("a821b41feacb16764dbb11b461957e1c49556122be81d73357570cb4116abd1ceda5d67110db5d6a266a129e139e5b6c"); }
  if (idx == 31) { return rawSlice("b244a0c962d09e920cee8c8b2dbe4c402e6d64d086c1f3cae52ed08c0071645534504bd2f40893f510ff504333e915cd"); }
  if (idx == 32) { return rawSlice("ad2aa112e61b587aad740196213add8487d3eb27ad5e80703f0f44e0a182ed6fba6a2f1be69eefe0f0c6371834fdc5d3"); }
  if (idx == 33) { return rawSlice("a9851389a21609810dd37a6c040b9644741b4ec308847a0b55c314e45b6c171c2419c981db51731c7098c1972885e696"); }
  if (idx == 34) { return rawSlice("97b5e832d94828a9bdd0aaef0bbb8e58c7f687f68c291faa169685bd1258d705bf585f68e52a290e1e3a3ed18485e7c3"); }
  if (idx == 35) { return rawSlice("af445ba3e4cfef7bb6f0bde0d5e18e3e8fcffb6223386ada2df1b40e45189be17617abb7685ca42c98b7509454fe5b65"); }
  if (idx == 36) { return rawSlice("a6a6e761d8ddf8b91987415240d43c4e52e5286c34a380799a3ec0b08fc4c231fc9e68fdc6d1c4430e068119f54127da"); }
  if (idx == 37) { return rawSlice("afcb54dca9cd71d283732e8681a3b4ae76e375f923d28d865abdb84c632188fa4e34bc525293e6e5a3318cc56c646943"); }
  if (idx == 38) { return rawSlice("a3a485bcdacdc33bda5bba30dff5d12550c645a9c28545f14b3341f3ce27def7d29bf5faa2b9a09c1c7dba438500389b"); }
  if (idx == 39) { return rawSlice("8225293735dfcacaaef1869afd3668256d31d93c1f8023fbaf1bab9268ce0f93ceda696bd47e02431ea36190221c9f0d"); }
  if (idx == 40) { return rawSlice("a8ffe69f2491076fd897c401b666e543057ea2446301dd0c70321e72b0c291b2824731f6b70a2509d7c621aa2209aca2"); }
  if (idx == 41) { return rawSlice("88de7af081a322f8a60b3a7f0ee2ae8e4fb1989585d2560069c64a522ce94d55bad26b56cd0c44b19e061c71290a763a"); }
  if (idx == 42) { return rawSlice("8c15e773af97f111c3d3c37ccdf6fedd3992434e166c78375723064b15f947b849a9e746bb7ec9a8bbfa7bce9e5507d3"); }
  if (idx == 43) { return rawSlice("8fa29c80f9419a5b8802b2590a897ac09e532f3f0beffcdbd1dff495d5d57e66c92ddeb876102cffc8bd2cd80635330e"); }
  if (idx == 44) { return rawSlice("aa2f9bf1ea958c3604f83fc30840d4f362b1bd06b9870fc8f4a53a874145d3f94bbc93b1146eeacddceacb809768e02c"); }
  if (idx == 45) { return rawSlice("82caa2707f2bed35c48fdbc99acbb024e55bd932edf2deae3b4c30a4b5b6f74e46164d9bc76b12c89422b1843886a05f"); }
  if (idx == 46) { return rawSlice("8ced875ee415c1b234670cb448b4eb1c47f5c399b30443eef815933b2a6ff7f20a682f1869fb229590a5c83b72fcdd74"); }
  if (idx == 47) { return rawSlice("b982acea01288963d268b2c883a26a9ffb36f92617595bbe51dbb1ff81b2bf5be36857c2f218647543427ccf4ef1532f"); }
  if (idx == 48) { return rawSlice("b992ac527ac505111f96af0492ab9755c3a9db7fff80dc127d4fb102eea8cb2060b4950e1b4086273df4e91990fe904a"); }
  if (idx == 49) { return rawSlice("962ae91615c7fba8c68b357ae8fb730f1ad972c6d3f00726593a4f30ebbbf922954d4a1264e69f097f6fc23ef8917d03"); }
  if (idx == 50) { return rawSlice("ac73449e2a7122c38ebc3855b02b07d5035af4f7f2a00fd6c4bc05063b80f05896c22ae4cb0bff55766d4641eca9d993"); }
  if (idx == 51) { return rawSlice("b7638625f127c20d520a2788b3d345266f123ada1eee03274e7adbbbdd2607a4baf3758ae18fcc3aa9ed22b681980da1"); }
  if (idx == 52) { return rawSlice("96e1a5564b8b58bcb79b24f41768927b81f5bc004e4e2e7eda7a33caae72c1419c4bd5b489d017092049038e0d7e7899"); }
  if (idx == 53) { return rawSlice("9315373c21676ed1c7ae91b32136535cfb54bc434990864403024195ea06fdab208f256056134d9186274267275874c5"); }
  if (idx == 54) { return rawSlice("b0ddc98c375a8032b9c1be27f3b84e80706bae4dc91e02e287a36e2c654c1ba44f6c8bef438f50555af426a03767f524"); }
  if (idx == 55) { return rawSlice("a13ae987ce0471a086227c4df91c78650e0f0823fc856bdd63afb61744a42f482a6365d6e8409bfbb8f29c6cdc5d8789"); }
  if (idx == 56) { return rawSlice("af700f3e1e62fa1fb7036d470d3928966f22306c49fc2c412c8670935220238a53e82be8e5a32a904f0a46840c99b3ad"); }
  if (idx == 57) { return rawSlice("b142c1338d496545aeb8e7d6ea195d27bacb572e4f805cfdbce63e1eff6e4bb2e53ff6fc9aeffa24f9fb3af2a0e6a4c6"); }
  if (idx == 58) { return rawSlice("a2ba87e792e67c0bf5573671aed550376604bb86cdb7621b2608c255142866df342257f2d99f840605e11cf3bd6debc0"); }
  if (idx == 59) { return rawSlice("93ffdfc1dace5408c13dc325d5198cf7b36b9072c7757408d46424216e9593069d5d1a662b0a64b48b7e212e4abe404e"); }
  if (idx == 60) { return rawSlice("8fd4e54e779a128fb09bc93f695afd481b64ab75831c23615ead787b56f653036989f44904ff7d4929972cd2ec7fcede"); }
  if (idx == 61) { return rawSlice("98daed5431d1f9e5cb078c850472176e72f85fab8f64041a0a62499b13d0acbc896e90fb1514f208a1ecdf9666b28514"); }
  if (idx == 62) { return rawSlice("b662a251ff9f12262773e175735b1349e12bbc6f198962a581a26fdcca3452dfd9be22f52b5c1edbe8fdcbe9258966fc"); }
  if (idx == 63) { return rawSlice("b85579303dc099b3adc637443785c397b7d3259fc274741718141bffe7e1c727f956e0e8adf2174918361530460aaeca"); }
  if (idx == 64) { return rawSlice("b63ae8e8c41a4de47a78b3e3c1790f607706612881759cdc47078d9bd5d728bcb6376e09973a102333db5a9943d3d335"); }
  if (idx == 65) { return rawSlice("85e4a2c68745278343582b1bb3630263d213990bb818bd2e4f66ea8121fffefc5b8f76d683607beaa299ab552c560101"); }
  if (idx == 66) { return rawSlice("97df2bec991a9e61bff1565b0e9997d8d140e080045f4ef86d65fc7e0c8c0108041a0e474450ad4bd74d10d317706e89"); }
  if (idx == 67) { return rawSlice("abb8877ae9dda232e68138977f09a57161cc252934face7639d85103d3e2e26afe60c6ef813ed90951fac3f0f231eb03"); }
  if (idx == 68) { return rawSlice("972ae8ccc158fda9df71a4bf40088f6d4dec7b8948752314c5d3c8d80125384ffab745625dcf497a7f8f1876d3f9e58e"); }
  if (idx == 69) { return rawSlice("99ea85b6a786b6319ccd031dccad0be84523a83a2d6b5f79baab6a1d8f6297b9947ddd41f7cbf788b011b5d3ff921f12"); }
  if (idx == 70) { return rawSlice("b38baad64f9346993c6ba16cefbb7d73a97087061e9c5608357a1d5d3cefccbe3045d5a756178ee82747c9e3f1466c45"); }
  if (idx == 71) { return rawSlice("91879cb7d347ff1838d27825623ccd91cba22957becfdced1e0e6335aa5bd1c90fa80cecee5b87381ef91ea53be2e0a2"); }
  if (idx == 72) { return rawSlice("8e08e3bd925275a5c98241bda4865168934e489d90571f74a9faa3213d8d6c3b4dfc1f13eb8893c5cfad89d2ddc917db"); }
  if (idx == 73) { return rawSlice("b3e4eff3b0ad80e900b1a0fd30b88b9381c86d12356d0ee55b9e7b32f08fd3d46b15f06fb7fd57ed73d78fb020679e5f"); }
  if (idx == 74) { return rawSlice("980fa4993aa930c6d3b42c70eae5d82e9cbd3484c885ddeaeb6e2b64f30876d1eda417d25d8b88a15134a122d15f4714"); }
  if (idx == 75) { return rawSlice("b5b621d6b83e320546ab427e99efd65ec6311faaf44fb0a7436b82a9e19fcf471af91807ed53624c834b60bd23d47ae2"); }
  if (idx == 76) { return rawSlice("a20593a54978bbabd0aeb8cf747f7fed1cba0d983da265586dba38a6047486206da5f4958a6361412281cd7705320e65"); }
  if (idx == 77) { return rawSlice("b79cb101d3a3f597ca25aaf029367b83a35b54f71f1fde315e1d2223102cabd170747dd8da9d06494b1888faf8fe4d63"); }
  if (idx == 78) { return rawSlice("80d328ae4fff50a89d2115aae8a7093997dfd37642719a448058e0441354fb8a3dd45aa43e101a39d636356abed9a4aa"); }
  if (idx == 79) { return rawSlice("97d60918d1d761ac2c3f4cb22c3aa00f37397cf61836f2065d56ac6c17759dd8a5b82d4071261d8654a4a3189e9fc622"); }
  if (idx == 80) { return rawSlice("91538b5d512d5e01a4c6c685a1b6fb84f295bb4764e23dadbe4ebf20a4429956533b28d5d4863886c6e4b2cd303b75cd"); }
  if (idx == 81) { return rawSlice("b3791f701360965877fc599be1e2fb09acc4af9f555958f65b4b675acc3c01ba56943c9ee259310e2ceff9a31ca7e8ba"); }
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
