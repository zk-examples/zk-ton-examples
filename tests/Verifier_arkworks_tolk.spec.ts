import { Verifier } from '../wrappers/Verifier_tolk';
import { getArkworksPayload } from './groth16-payloads';
import { describeFuncOrTolkVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_arkworks_tolk
describeFuncOrTolkVerifier({
    name: 'Verifier_arkworks_tolk',
    Wrapper: Verifier,
    getPayload: getArkworksPayload,
});
