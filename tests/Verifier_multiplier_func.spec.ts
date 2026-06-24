import { Verifier } from '../wrappers/Verifier_func';
import { getMultiplierPayload } from './groth16-payloads';
import { describeFuncOrTolkVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_multiplier_func
describeFuncOrTolkVerifier({
    name: 'Verifier_multiplier_func',
    Wrapper: Verifier,
    getPayload: getMultiplierPayload,
    verifyValue: '0.15',
});
