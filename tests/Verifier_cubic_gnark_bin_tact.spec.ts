import { Verifier } from '../build/Verifier_cubic_gnark_bin_tact/Verifier_cubic_gnark_bin_tact_Verifier';
import { getCubicPayload } from './groth16-payloads';
import { describeTactVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_cubic_gnark_bin_tact
describeTactVerifier({
    name: 'Verifier_cubic_gnark_bin_tact',
    Contract: Verifier,
    getPayload: getCubicPayload,
});
