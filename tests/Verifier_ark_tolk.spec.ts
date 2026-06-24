import { Verifier } from '../wrappers/Verifier_tolk';
import { getArkworksPayload } from './groth16-payloads';
import { describeFuncOrTolkVerifier } from './groth16-verifier-runner';

// npx blueprint test Verifier_ark_tolk
describeFuncOrTolkVerifier({
    name: 'Verifier_ark_tolk',
    Wrapper: Verifier,
    getPayload: getArkworksPayload,
    getMethodName: 'getVerifyArkVerifier',
    verifyValue: '0.15',
});
