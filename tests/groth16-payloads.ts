import * as snarkjs from 'snarkjs';
import { getExportTonVerifier } from './export-ton-verifier';

export type Groth16Payload = {
    pi_a: Buffer;
    pi_b: Buffer;
    pi_c: Buffer;
    pubInputs: bigint[];
};

export type ProofFile = snarkjs.Groth16Proof & Record<string, any>;

export type Groth16ProofPayload = Groth16Payload & {
    proof: ProofFile;
    publicSignals: snarkjs.PublicSignals;
};

let multiplierPayload: Promise<Groth16ProofPayload> | undefined;
let alternateMultiplierPayload: Promise<Groth16ProofPayload> | undefined;
let sudokuPayload: Promise<Groth16ProofPayload> | undefined;
let cubicPayload: Promise<Groth16ProofPayload> | undefined;
let arkworksPayload: Promise<Groth16ProofPayload> | undefined;

export function publicSignalsFrom(proofFile: ProofFile, proofName: string): snarkjs.PublicSignals {
    const publicSignals = (proofFile.publicSignals ?? proofFile.public_signals) as snarkjs.PublicSignals | undefined;
    if (!publicSignals) {
        throw new Error(`${proofName} proof fixture is missing publicSignals/public_signals.`);
    }
    return publicSignals;
}

export async function compressProof(proofFile: ProofFile, publicSignals: snarkjs.PublicSignals) {
    const { groth16CompressProof } = getExportTonVerifier();
    return (await groth16CompressProof(proofFile, publicSignals)) as Groth16Payload;
}

async function buildPayload(
    verificationKey: unknown,
    proofFile: ProofFile,
    publicSignals: snarkjs.PublicSignals,
): Promise<Groth16ProofPayload> {
    const isVerify = await snarkjs.groth16.verify(verificationKey, publicSignals, proofFile);
    if (!isVerify) {
        throw new Error('Proof fixture does not verify against its snarkjs-compatible verification key.');
    }

    return {
        ...(await compressProof(proofFile, publicSignals)),
        proof: proofFile,
        publicSignals,
    };
}

async function buildMultiplierPayload() {
    const verificationKey = require('../circuits/Multiplier/verification_key.json');
    const proof = require('../circuits/Multiplier/proof.json') as ProofFile;
    const publicSignals = require('../circuits/Multiplier/public.json') as snarkjs.PublicSignals;
    return buildPayload(verificationKey, proof, publicSignals);
}

export function getMultiplierPayload() {
    multiplierPayload ??= buildMultiplierPayload();
    return multiplierPayload;
}

export function getAlternateMultiplierPayload() {
    alternateMultiplierPayload ??= (async () => {
        const verificationKey = require('../circuits/Multiplier/verification_key.json');
        const proof = require('../circuits/Multiplier/proof-alternate.json') as ProofFile;
        const publicSignals = require('../circuits/Multiplier/public-alternate.json') as snarkjs.PublicSignals;
        return buildPayload(verificationKey, proof, publicSignals);
    })();
    return alternateMultiplierPayload;
}

export async function verifyMultiplierProof(proofFile: ProofFile, publicSignals: snarkjs.PublicSignals) {
    const verificationKey = require('../circuits/Multiplier/verification_key.json');
    return snarkjs.groth16.verify(verificationKey, publicSignals, proofFile);
}

export function getSudokuPayload() {
    sudokuPayload ??= (async () => {
        const verificationKey = require('../circuits/Sudoku/verification_key.json');
        const proof = require('../circuits/Sudoku/proof.json') as ProofFile;
        const publicSignals = require('../circuits/Sudoku/public.json') as snarkjs.PublicSignals;
        return buildPayload(verificationKey, proof, publicSignals);
    })();
    return sudokuPayload;
}

export function getCubicPayload() {
    cubicPayload ??= (async () => {
        const verificationKey = require('../circuits/cubic-gnark/artifacts/verification_key.json');
        const proofFile = require('../circuits/cubic-gnark/artifacts/proof.json') as ProofFile;
        const publicSignals = publicSignalsFrom(proofFile, 'Cubic');
        return buildPayload(verificationKey, proofFile, publicSignals);
    })();
    return cubicPayload;
}

export function getArkworksPayload() {
    arkworksPayload ??= (async () => {
        const verificationKey = require('../circuits/Arkworks/MulCircuit/json/verification_key.json');
        const proofFile = require('../circuits/Arkworks/MulCircuit/json/proof.json') as ProofFile;
        const publicSignals = publicSignalsFrom(proofFile, 'Arkworks');
        return buildPayload(verificationKey, proofFile, publicSignals);
    })();
    return arkworksPayload;
}
