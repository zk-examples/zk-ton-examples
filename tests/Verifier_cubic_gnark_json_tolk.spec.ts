import { Verifier } from '../wrappers/Verifier_tolk';
import { getCubicPayload } from './groth16-payloads';
import { describeFuncOrTolkVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_cubic_gnark_json_tolk
describeFuncOrTolkVerifier({
    name: 'Verifier_cubic_gnark_json_tolk',
    Wrapper: Verifier,
    getPayload: getCubicPayload,
});
