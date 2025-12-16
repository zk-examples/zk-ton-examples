// ASM intrinsics
asm fun blsG1Add(x: Slice, y: Slice): Slice { BLS_G1_ADD }
asm fun blsG1Neg(x: Slice): Slice { BLS_G1_NEG }
asm fun blsPairing(
    x1: Slice,
    y1: Slice,
    x2: Slice,
    y2: Slice,
    x3: Slice,
    y3: Slice,
    x4: Slice,
    y4: Slice,
    n: Int,
): Int { BLS_PAIRING }

asm fun blsG1Multiexp_1(
    x1: Slice,
    y1: Int,
    n: Int,
): Slice { BLS_G1_MULTIEXP }

// Verification key constants
const vk_gamma_2: Slice = rawSlice("84a9b33c0d55a6b74581977e92e90e65ef96614ad6d64781961a15e3a0bbd2e5ec43ccec161baed79448308eebdbbbf408a3b3fe2f021d97f8f547eb88fedb088f1784405f3d45ed381087652d8a8cfe73a6a7a2869930d7f9143e1f2d970cc2");
const vk_delta_2: Slice = rawSlice("b868baac296b0cc569e60f6da8dd2a5a858349b611d19c6e90e3e63de61ae1db6af2a6aa451e48491600b007b6540d0a08ec0c943eef6422fdb96b643f7a661f92a10fbc9a78a0fae13612bfb829e58b0e904921dffbf6658bdbcd21a73227ee");
const vk_alpha_1: Slice = rawSlice("a1886dc3d23724f1688d467c3d1ba4e23b6d0f3ed54d0ee51a9d98aacb5548e9c6fd7fe6ebe530b522de7501e802633a");
const vk_beta_2: Slice = rawSlice("891f17239d628ccbaaf34baa187c189abd34d1da3ca795ec7c53a8e64c016a9045728e1dd9ca352c927afa5c251111431731f9d0430af7e1b207f3bbbd5bb97b29e12bac9cef1e4344e9319958152d3bcfd506170b3c36d817121780e4599a43");

// IC constants (IC0 — constant term)
const IC0: Slice = rawSlice("afeed53d6eebfc2da813995f7f1a4a6c993b2847b32f7800a6b4fcbe0e397c6baf32aafb269e6e91b8049fde7d12d15f");
const IC1: Slice = rawSlice("81842285c4584281e58867185df524aad87efb05e4e4ed4d64829a7cb53d39530140909878bee84ac3b984b1824b79dd");

// Error codes
const ERR_PUBLIC_NOT_PRESENT: Int = 257;
const ERR_TOO_MANY_PUBLICS: Int = 258;
const ERR_INDEX_OUT_OF_RANGE: Int = 259;
const ERR_WRONG_PROOF: Int = 260;

// Safe getter for public inputs: throws ERR_PUBLIC_NOT_PRESENT
fun getPub(pubInputs: map<Int as uint32, Int>, k: Int): Int {
    let v = pubInputs.get(k);
    if (v == null) {
        nativeThrow(ERR_PUBLIC_NOT_PRESENT);
    }
    return v!!;
}

// Message definition
message(0x3b3cca17) Verify {
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
        pubInputs: map<Int as uint32, Int>,
    ): Bool {
        // --- acc = Σ(v_i * IC_{i+1}) (ONLY public-dependent part) ---
        let haveAcc: Bool = false;
        let acc: Slice = IC0; // placeholder until haveAcc=true

        // Single batch (no loop and no ic())
        acc = blsG1Multiexp_1(
            IC1,
            getPub(pubInputs, 0),
            1,
        );
        haveAcc = true;

        // Cheap guard: reject obvious extras
        nativeThrowIf(ERR_TOO_MANY_PUBLICS, pubInputs.exists(1));

        // --- cpub = IC0 + acc (IC0 is added exactly once) ---
        let cpub: Slice = haveAcc ? blsG1Add(acc, IC0) : IC0;

        // Pairing check
        let piANeg: Slice = blsG1Neg(piA);
        let ok: Int = blsPairing(
            cpub,
            vk_gamma_2,
            piANeg,
            piB,
            piC,
            vk_delta_2,
            vk_alpha_1,
            vk_beta_2,
            4,
        );

        return ok != 0;
    }

    get fun verify(
        piA: Slice,
        piB: Slice,
        piC: Slice,
        pubInputs: map<Int as uint32, Int>,
    ): Bool {
        return self.groth16Verify(piA, piB, piC, pubInputs);
    }
}
