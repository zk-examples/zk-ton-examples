import * as snarkjs from 'snarkjs';

import { ProofFile, publicSignalsFrom } from './groth16-payloads';

async function expectArkSnarkjsFixtureVerifies(verificationKeyPath: string, proofPath: string, proofName: string) {
    const verificationKey = require(verificationKeyPath);
    const proofFile = require(proofPath) as ProofFile;
    const publicSignals = publicSignalsFrom(proofFile, proofName);

    expect(verificationKey.nPublic).toBe(1);
    expect(verificationKey.IC).toHaveLength(2);
    expect(proofFile.publicSignals).toEqual(publicSignals);
    expect(await snarkjs.groth16.verify(verificationKey, publicSignals, proofFile)).toBe(true);

    const invalidSignals = [(BigInt(publicSignals[0]) + 1n).toString()];
    expect(await snarkjs.groth16.verify(verificationKey, invalidSignals, proofFile)).toBe(false);
}

describe('ark-snarkjs fixtures', () => {
    it.each([
        {
            name: 'mimc BN254',
            verificationKeyPath: '../circuits/Arkworks/json/mimc/Bn254/verification_key.json',
            proofPath: '../circuits/Arkworks/json/mimc/Bn254/proof.json',
        },
        {
            name: 'mimc Bls12-381',
            verificationKeyPath: '../circuits/Arkworks/json/mimc/Bls12-381/verification_key.json',
            proofPath: '../circuits/Arkworks/json/mimc/Bls12-381/proof.json',
        },
        {
            name: 'mul BN254',
            verificationKeyPath: '../circuits/Arkworks/json/mul/Bn254/verification_key.json',
            proofPath: '../circuits/Arkworks/json/mul/Bn254/proof.json',
        },
        {
            name: 'mul Bls12-381',
            verificationKeyPath: '../circuits/Arkworks/json/mul/Bls12-381/verification_key.json',
            proofPath: '../circuits/Arkworks/json/mul/Bls12-381/proof.json',
        },
        {
            name: 'mulbn254 BN254',
            verificationKeyPath: '../circuits/Arkworks/json/mulbn254/verification_key.json',
            proofPath: '../circuits/Arkworks/json/mulbn254/proof.json',
        },
    ])('$name verifies with snarkjs', async ({ name, verificationKeyPath, proofPath }) => {
        await expectArkSnarkjsFixtureVerifies(verificationKeyPath, proofPath, name);
    });
});
