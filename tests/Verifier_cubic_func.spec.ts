import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { compile } from '@ton/blueprint';
import { Cell, toNano } from '@ton/core';
import '@ton/test-utils';

import * as snarkjs from 'snarkjs';

import { GasLogAndSave } from './gas-logger';
import { Verifier } from '../wrappers/Verifier';
import { groth16CompressProof } from 'export-ton-verifier';

const verificationKey = require('../circuits/cubic-gnark/verification_key.json');
const proofFile = require('../circuits/cubic-gnark/proof.json');

// npx blueprint test Verifier_cubic_func
describe('Verifier_cubic_func', () => {
    let code: Cell;
    let GAS_LOG = new GasLogAndSave('Verifier_cubic_func');

    beforeAll(async () => {
        code = await compile('Verifier_cubic_func');
        GAS_LOG.rememberBocSize('Verifier_cubic_func', code);
    });

    afterAll(() => {
        GAS_LOG.saveCurrentRunAfterAll();
    });

    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let verifier: SandboxContract<Verifier>;

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
        const publicSignals: snarkjs.PublicSignals = proofFile.publicSignals;

        const isVerify = await snarkjs.groth16.verify(verificationKey, publicSignals, proofFile);
        expect(isVerify).toBe(true);

        const { pi_a, pi_b, pi_c, pubInputs } = await groth16CompressProof(proofFile, publicSignals);

        expect(await verifier.getVerify({ pi_a, pi_b, pi_c, pubInputs })).toBe(true);

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
});
