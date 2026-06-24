import { Verifier } from '../build/Verifier_sudoku_tact/Verifier_sudoku_tact_Verifier';
import { getSudokuPayload } from './groth16-payloads';
import { describeTactVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_sudoku_tact
describeTactVerifier({
    name: 'Verifier_sudoku_tact',
    Contract: Verifier,
    getPayload: getSudokuPayload,
    verifyValue: '0.4',
});
