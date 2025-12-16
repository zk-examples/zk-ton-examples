import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { beginCell, toNano } from '@ton/core';
import '@ton/test-utils';

import * as snarkjs from 'snarkjs';
import path from 'path';

import { GasLogAndSave } from './gas-logger';
import { Verifier } from '../build/Verifier_sudoku_tact/Verifier_sudoku_tact_Verifier';

import { dictFromInputList, groth16CompressProof } from 'export-ton-verifier';

const wtnsPath = path.join(__dirname, '../circuits/Sudoku/', 'Sudoku.wtns');
const zkeyPath = path.join(__dirname, '../circuits/Sudoku/', 'Sudoku_final.zkey');
const verificationKey = require('../circuits/Sudoku/verification_key.json');

// npx blueprint test Verifier_sudoku_tact
describe('Verifier_sudoku_tact', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let verifier: SandboxContract<Verifier>;

    let GAS_LOG = new GasLogAndSave('Verifier_sudoku_tact');

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        verifier = blockchain.openContract(await Verifier.fromInit());

        deployer = await blockchain.treasury('deployer');

        GAS_LOG.rememberBocSize('Verifier_sudoku_tact', verifier.init?.code!);

        const deployResult = await verifier.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            null,
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: verifier.address,
            deploy: true,
            success: true,
        });

        GAS_LOG.rememberGas('Deploy', deployResult.transactions.slice(1));
    });

    afterAll(() => {
        GAS_LOG.saveCurrentRunAfterAll();
    });

    it('should verify', async () => {
        const input = {
            a: '435',
            b: '32',
        };
        const { proof, publicSignals } = await snarkjs.groth16.prove(zkeyPath, wtnsPath);

        const isVerify = await snarkjs.groth16.verify(verificationKey, publicSignals, proof);
        expect(isVerify).toBe(true);

        const { pi_a, pi_b, pi_c, pubInputs } = await groth16CompressProof(proof, publicSignals);

        expect(
            await verifier.getVerify(
                beginCell().storeBuffer(pi_a).endCell().asSlice(),
                beginCell().storeBuffer(pi_b).endCell().asSlice(),
                beginCell().storeBuffer(pi_c).endCell().asSlice(),
                dictFromInputList(pubInputs),
            ),
        ).toBe(true);

        const verifyResult = await verifier.send(
            deployer.getSender(),
            {
                value: toNano('0.4'),
            },
            {
                $$type: 'Verify',
                piA: beginCell().storeBuffer(pi_a).endCell().asSlice(),
                piB: beginCell().storeBuffer(pi_b).endCell().asSlice(),
                piC: beginCell().storeBuffer(pi_c).endCell().asSlice(),
                pubInputs: dictFromInputList(pubInputs),
            },
        );

        expect(verifyResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: verifier.address,
            success: true,
        });

        GAS_LOG.rememberGas('Verify', verifyResult.transactions.slice(1));
    });
});
