import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { compile } from '@ton/blueprint';
import { Cell, toNano } from '@ton/core';
import '@ton/test-utils';

import * as snarkjs from 'snarkjs';
import path from 'path';

import { getExportTonVerifier } from './export-ton-verifier';
import { GasLogAndSave } from './gas-logger';
import { Verifier } from '../wrappers/Verifier_tolk';

const wasmPath = path.join(__dirname, '../circuits/Multiplier/Multiplier_js', 'Multiplier.wasm');
const zkeyPath = path.join(__dirname, '../circuits/Multiplier', 'Multiplier_final.zkey');
const verificationKey = require('../circuits/Multiplier/verification_key.json');
const input = {
    a: '435',
    b: '32',
};

// npx blueprint test Verifier_multiplier_tolk
describe('Verifier_multiplier_tolk', () => {
    let code: Cell;
    let GAS_LOG = new GasLogAndSave('Verifier_multiplier_tolk');

    beforeAll(async () => {
        code = await compile('Verifier_multiplier_tolk');
        GAS_LOG.rememberBocSize('Verifier_multiplier_tolk', code);
    });

    afterAll(() => {
        GAS_LOG.saveCurrentRunAfterAll();
    });

    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let verifier: SandboxContract<Verifier>;

    async function buildValidVerifyPayload(proofInput = input) {
        const { groth16CompressProof } = getExportTonVerifier();
        const { proof, publicSignals } = await snarkjs.groth16.fullProve(proofInput, wasmPath, zkeyPath);

        expect(await snarkjs.groth16.verify(verificationKey, publicSignals, proof)).toBe(true);

        return {
            ...(await groth16CompressProof(proof, publicSignals)),
            proof,
            publicSignals,
        };
    }

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        verifier = blockchain.openContract(Verifier.createFromConfig({}, code));

        deployer = await blockchain.treasury('deployer');

        const deployResult = await verifier.sendDeploy(deployer.getSender(), toNano('0.05'));

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: verifier.address,
            deploy: true,
            success: true,
        });

        GAS_LOG.rememberGas('Deploy', deployResult.transactions.slice(1));
    });

    it('should verify', async () => {
        const { pi_a, pi_b, pi_c, pubInputs } = await buildValidVerifyPayload();

        expect(await verifier.getVerifyMultiplierVerifier({ pi_a, pi_b, pi_c, pubInputs })).toBe(true);

        const verifyResult = await verifier.sendVerify(deployer.getSender(), {
            pi_a,
            pi_b,
            pi_c,
            pubInputs,
            value: toNano('0.15'),
        });

        expect(verifyResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: verifier.address,
            success: true,
        });

        GAS_LOG.rememberGas('Verify', verifyResult.transactions.slice(1));
    });

    it('should reject tampered proof', async () => {
        const validPayload = await buildValidVerifyPayload();
        const tamperedPayload = await buildValidVerifyPayload({
            a: '436',
            b: '32',
        });

        expect(await snarkjs.groth16.verify(verificationKey, validPayload.publicSignals, tamperedPayload.proof)).toBe(
            false,
        );

        expect(
            await verifier.getVerifyMultiplierVerifier({
                pi_a: tamperedPayload.pi_a,
                pi_b: tamperedPayload.pi_b,
                pi_c: tamperedPayload.pi_c,
                pubInputs: validPayload.pubInputs,
            }),
        ).toBe(false);

        const verifyResult = await verifier.sendVerify(deployer.getSender(), {
            pi_a: tamperedPayload.pi_a,
            pi_b: tamperedPayload.pi_b,
            pi_c: tamperedPayload.pi_c,
            pubInputs: validPayload.pubInputs,
            value: toNano('0.15'),
        });

        expect(verifyResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: verifier.address,
            success: false,
            exitCode: 260,
        });
    });

    it('should reject tampered public inputs', async () => {
        const { proof, publicSignals, pi_a, pi_b, pi_c } = await buildValidVerifyPayload();
        const tamperedPublicSignals = [...publicSignals];
        tamperedPublicSignals[0] = (BigInt(tamperedPublicSignals[0]) + 1n).toString();

        expect(await snarkjs.groth16.verify(verificationKey, tamperedPublicSignals, proof)).toBe(false);

        const { groth16CompressProof } = getExportTonVerifier();
        const { pubInputs: tamperedPubInputs } = await groth16CompressProof(proof, tamperedPublicSignals);

        expect(await verifier.getVerifyMultiplierVerifier({ pi_a, pi_b, pi_c, pubInputs: tamperedPubInputs })).toBe(
            false,
        );

        const verifyResult = await verifier.sendVerify(deployer.getSender(), {
            pi_a,
            pi_b,
            pi_c,
            pubInputs: tamperedPubInputs,
            value: toNano('0.15'),
        });

        expect(verifyResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: verifier.address,
            success: false,
            exitCode: 260,
        });
    });

    it('should reject invalid public input length', async () => {
        const { pi_a, pi_b, pi_c, pubInputs } = await buildValidVerifyPayload();
        const missingPubInputs: bigint[] = [];
        const extraPubInputs = [...pubInputs, 1n];

        await expect(
            verifier.getVerifyMultiplierVerifier({ pi_a, pi_b, pi_c, pubInputs: missingPubInputs }),
        ).rejects.toThrow();
        await expect(
            verifier.getVerifyMultiplierVerifier({ pi_a, pi_b, pi_c, pubInputs: extraPubInputs }),
        ).rejects.toThrow();

        const missingInputsResult = await verifier.sendVerify(deployer.getSender(), {
            pi_a,
            pi_b,
            pi_c,
            pubInputs: missingPubInputs,
            value: toNano('0.15'),
        });

        expect(missingInputsResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: verifier.address,
            success: false,
            exitCode: 258,
        });

        const extraInputsResult = await verifier.sendVerify(deployer.getSender(), {
            pi_a,
            pi_b,
            pi_c,
            pubInputs: extraPubInputs,
            value: toNano('0.15'),
        });

        expect(extraInputsResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: verifier.address,
            success: false,
            exitCode: 258,
        });
    });
});
