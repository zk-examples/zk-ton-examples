import { Verifier } from '../wrappers/Verifier_func';
import { getArkworksPayload } from './groth16-payloads';
import { describeFuncOrTolkVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_arkworks_func
describeFuncOrTolkVerifier({
    name: 'Verifier_arkworks_func',
    Wrapper: Verifier,
    getPayload: getArkworksPayload,
});
