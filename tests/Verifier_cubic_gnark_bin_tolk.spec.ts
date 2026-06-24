import { Verifier } from '../wrappers/Verifier_tolk';
import { getCubicPayload } from './groth16-payloads';
import { describeFuncOrTolkVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_cubic_gnark_bin_tolk
describeFuncOrTolkVerifier({
    name: 'Verifier_cubic_gnark_bin_tolk',
    Wrapper: Verifier,
    getPayload: getCubicPayload,
});
