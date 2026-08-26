import { Verifier } from '../wrappers/Verifier_tolk';
import { GasLogAndSave } from './gas-logger';
import {
    compressProof,
    getAlternateMultiplierPayload,
    getMultiplierPayload,
    verifyMultiplierProof,
} from './groth16-payloads';
import {
    callFuncOrTolkGetter,
    deployFuncOrTolkVerifier,
    payloadToFuncOrTolkArgs,
    runFuncOrTolkVerifierTest,
    sendFuncOrTolkVerify,
} from './groth16-verifier-runner';

const TEST_NAME = 'Verifier_multiplier_tolk';
const VERIFY_GETTER = 'getVerifyMultiplierVerifier';
const VERIFY_VALUE = '0.15';

function withPubInputs<T extends ReturnType<typeof payloadToFuncOrTolkArgs>>(payload: T, pubInputs: bigint[]) {
    return { ...payload, pubInputs };
}

// npx blueprint test Verifier_multiplier_tolk
describe(TEST_NAME, () => {
    const GAS_LOG = new GasLogAndSave(TEST_NAME);

    afterAll(() => {
        GAS_LOG.saveCurrentRunAfterAll();
    });

    async function deployVerifier() {
        return deployFuncOrTolkVerifier({
            compileName: TEST_NAME,
            gasName: TEST_NAME,
            Wrapper: Verifier,
            gasLog: GAS_LOG,
        });
    }

    it('should verify', async () => {
        await runFuncOrTolkVerifierTest({
            compileName: TEST_NAME,
            gasName: TEST_NAME,
            Wrapper: Verifier,
            gasLog: GAS_LOG,
            payload: await getMultiplierPayload(),
            getMethodName: VERIFY_GETTER,
            verifyValue: VERIFY_VALUE,
        });
    });

    it('should reject tampered proof', async () => {
        const deployed = await deployVerifier();
        const validPayload = await getMultiplierPayload();
        const alternatePayload = await getAlternateMultiplierPayload();

        expect(await verifyMultiplierProof(alternatePayload.proof, validPayload.publicSignals)).toBe(false);

        const payloadWithTamperedProof = {
            ...payloadToFuncOrTolkArgs({
                ...(await compressProof(alternatePayload.proof, validPayload.publicSignals)),
            }),
            pubInputs: validPayload.pubInputs,
        };
        expect(await callFuncOrTolkGetter(deployed.verifier, payloadWithTamperedProof, VERIFY_GETTER)).toBe(false);

        const verifyResult = await sendFuncOrTolkVerify(deployed, payloadWithTamperedProof, VERIFY_VALUE);
        expect(verifyResult.transactions).toHaveTransaction({
            from: deployed.deployer.address,
            to: deployed.verifier.address,
            success: false,
            exitCode: 260,
        });
    });

    it('should reject tampered public inputs', async () => {
        const deployed = await deployVerifier();
        const validPayload = await getMultiplierPayload();
        const tamperedPublicSignals = [...validPayload.publicSignals];
        tamperedPublicSignals[0] = (BigInt(tamperedPublicSignals[0]) + 1n).toString();

        expect(await verifyMultiplierProof(validPayload.proof, tamperedPublicSignals)).toBe(false);

        const tamperedPubInputs = (await compressProof(validPayload.proof, tamperedPublicSignals)).pubInputs;
        const payloadWithTamperedInputs = withPubInputs(payloadToFuncOrTolkArgs(validPayload), tamperedPubInputs);

        expect(await callFuncOrTolkGetter(deployed.verifier, payloadWithTamperedInputs, VERIFY_GETTER)).toBe(false);

        const verifyResult = await sendFuncOrTolkVerify(deployed, payloadWithTamperedInputs, VERIFY_VALUE);
        expect(verifyResult.transactions).toHaveTransaction({
            from: deployed.deployer.address,
            to: deployed.verifier.address,
            success: false,
            exitCode: 260,
        });
    });

    it('should reject invalid public input length', async () => {
        const deployed = await deployVerifier();
        const validPayload = await getMultiplierPayload();
        const validPayloadArgs = payloadToFuncOrTolkArgs(validPayload);
        const missingPubInputs: bigint[] = [];
        const extraPubInputs = [...validPayload.pubInputs, 1n];

        await expect(
            callFuncOrTolkGetter(deployed.verifier, withPubInputs(validPayloadArgs, missingPubInputs), VERIFY_GETTER),
        ).rejects.toThrow();
        await expect(
            callFuncOrTolkGetter(deployed.verifier, withPubInputs(validPayloadArgs, extraPubInputs), VERIFY_GETTER),
        ).rejects.toThrow();

        const missingInputsResult = await sendFuncOrTolkVerify(
            deployed,
            withPubInputs(validPayloadArgs, missingPubInputs),
            VERIFY_VALUE,
        );
        expect(missingInputsResult.transactions).toHaveTransaction({
            from: deployed.deployer.address,
            to: deployed.verifier.address,
            success: false,
            exitCode: 258,
        });

        const extraInputsResult = await sendFuncOrTolkVerify(
            deployed,
            withPubInputs(validPayloadArgs, extraPubInputs),
            VERIFY_VALUE,
        );
        expect(extraInputsResult.transactions).toHaveTransaction({
            from: deployed.deployer.address,
            to: deployed.verifier.address,
            success: false,
            exitCode: 258,
        });
    });
});
