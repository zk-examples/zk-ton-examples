import { Verifier } from '../wrappers/Verifier_tolk';
import { getSudokuPayload } from './groth16-payloads';
import { describeFuncOrTolkVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_sudoku_tolk
describeFuncOrTolkVerifier({
    name: 'Verifier_sudoku_tolk',
    Wrapper: Verifier,
    getPayload: getSudokuPayload,
    verifyValue: '0.4',
});
