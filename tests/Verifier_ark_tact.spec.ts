import { Verifier } from '../build/Verifier_ark_tact/Verifier_ark_tact_Verifier';
import { getArkworksPayload } from './groth16-payloads';
import { describeTactVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_ark_tact
describeTactVerifier({
    name: 'Verifier_ark_tact',
    Contract: Verifier,
    getPayload: getArkworksPayload,
});
