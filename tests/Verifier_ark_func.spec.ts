import { Verifier } from '../wrappers/Verifier_func';
import { getArkworksPayload } from './groth16-payloads';
import { describeFuncOrTolkVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_ark_func
describeFuncOrTolkVerifier({
    name: 'Verifier_ark_func',
    Wrapper: Verifier,
    getPayload: getArkworksPayload,
    verifyValue: '0.15',
});
