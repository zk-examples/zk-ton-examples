import { Verifier } from '../wrappers/Verifier_func';
import { getCubicPayload } from './groth16-payloads';
import { describeFuncOrTolkVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_cubic_gnark_bin_func
describeFuncOrTolkVerifier({
    name: 'Verifier_cubic_gnark_bin_func',
    Wrapper: Verifier,
    getPayload: getCubicPayload,
});
