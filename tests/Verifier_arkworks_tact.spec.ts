import { Verifier } from '../build/Verifier_arkworks_tact/Verifier_arkworks_tact_Verifier';
import { getArkworksPayload } from './groth16-payloads';
import { describeTactVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_arkworks_tact
describeTactVerifier({
    name: 'Verifier_arkworks_tact',
    Contract: Verifier,
    getPayload: getArkworksPayload,
});
