import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { compile } from '@ton/blueprint';
import { Cell, toNano } from '@ton/core';
import '@ton/test-utils';

import * as snarkjs from 'snarkjs';
import path from 'path';

import { getExportTonVerifier } from './export-ton-verifier';
import { GasLogAndSave } from './gas-logger';
import { Verifier } from '../wrappers/Verifier_tolk';

const wtnsPath = path.join(__dirname, '../circuits/Sudoku/', 'Sudoku.wtns');
const zkeyPath = path.join(__dirname, '../circuits/Sudoku/', 'Sudoku_final.zkey');
const verificationKey = require('../circuits/Sudoku/verification_key.json');

// npx blueprint test Verifier_sudoku_tolk
describe('Verifier_sudoku_tolk', () => {
    let code: Cell;
    let GAS_LOG = new GasLogAndSave('Verifier_sudoku_tolk');

    beforeAll(async () => {
        code = await compile('Verifier_sudoku_tolk');
        GAS_LOG.rememberBocSize('Verifier_sudoku_tolk', code);
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
        const { groth16CompressProof } = getExportTonVerifier();
        const input = {
            a: '342',
            b: '1245',
        };
        const { proof, publicSignals } = await snarkjs.groth16.prove(zkeyPath, wtnsPath);

        const isVerify = await snarkjs.groth16.verify(verificationKey, publicSignals, proof);
        expect(isVerify).toBe(true);

        const { pi_a, pi_b, pi_c, pubInputs } = await groth16CompressProof(proof, publicSignals);

        expect(await verifier.getVerify({ pi_a, pi_b, pi_c, pubInputs })).toBe(true);

        const verifyResult = await verifier.sendVerify(deployer.getSender(), {
            pi_a,
            pi_b,
            pi_c,
            pubInputs,
            value: toNano('0.4'),
        });

        expect(verifyResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: verifier.address,
            success: true,
        });

        GAS_LOG.rememberGas('Verify', verifyResult.transactions.slice(1));
    });
});
