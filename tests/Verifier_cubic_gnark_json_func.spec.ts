import { Verifier } from '../wrappers/Verifier_func';
import { getCubicPayload } from './groth16-payloads';
import { describeFuncOrTolkVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_cubic_gnark_json_func
describeFuncOrTolkVerifier({
    name: 'Verifier_cubic_gnark_json_func',
    Wrapper: Verifier,
    getPayload: getCubicPayload,
});
