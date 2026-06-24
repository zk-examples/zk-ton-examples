import { Verifier } from '../build/Verifier_multiplier_tact/Verifier_multiplier_tact_Verifier';
import { getMultiplierPayload } from './groth16-payloads';
import { describeTactVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_multiplier_tact
describeTactVerifier({
    name: 'Verifier_multiplier_tact',
    Contract: Verifier,
    getPayload: getMultiplierPayload,
});
