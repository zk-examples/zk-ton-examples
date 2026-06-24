import * as snarkjs from 'snarkjs';
import * as path from 'node:path';

import { getExportTonVerifier } from './export-ton-verifier';

const multiplierWasmPath = path.join(__dirname, '../circuits/Multiplier/Multiplier_js', 'Multiplier.wasm');
const multiplierZkeyPath = path.join(__dirname, '../circuits/Multiplier', 'Multiplier_final.zkey');
const sudokuWtnsPath = path.join(__dirname, '../circuits/Sudoku', 'Sudoku.wtns');
const sudokuZkeyPath = path.join(__dirname, '../circuits/Sudoku', 'Sudoku_final.zkey');

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

export type MultiplierInput = {
    a: string;
    b: string;
};

export const DEFAULT_MULTIPLIER_INPUT: MultiplierInput = {
    a: '435',
    b: '32',
};

let multiplierPayload: Promise<Groth16ProofPayload> | undefined;
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

export async function buildMultiplierPayload(input: MultiplierInput = DEFAULT_MULTIPLIER_INPUT) {
    const verificationKey = require('../circuits/Multiplier/verification_key.json');
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(input, multiplierWasmPath, multiplierZkeyPath);
    return buildPayload(verificationKey, proof as ProofFile, publicSignals);
}

export function getMultiplierPayload() {
    multiplierPayload ??= buildMultiplierPayload();
    return multiplierPayload;
}

export async function verifyMultiplierProof(proofFile: ProofFile, publicSignals: snarkjs.PublicSignals) {
    const verificationKey = require('../circuits/Multiplier/verification_key.json');
    return snarkjs.groth16.verify(verificationKey, publicSignals, proofFile);
}

export function getSudokuPayload() {
    sudokuPayload ??= (async () => {
        const verificationKey = require('../circuits/Sudoku/verification_key.json');
        const { proof, publicSignals } = await snarkjs.groth16.prove(sudokuZkeyPath, sudokuWtnsPath);
        return buildPayload(verificationKey, proof as ProofFile, publicSignals);
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
