import { Verifier } from '../wrappers/Verifier_func';
import { getSudokuPayload } from './groth16-payloads';
import { describeFuncOrTolkVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_sudoku_func
describeFuncOrTolkVerifier({
    name: 'Verifier_sudoku_func',
    Wrapper: Verifier,
    getPayload: getSudokuPayload,
    verifyValue: '0.3',
});
