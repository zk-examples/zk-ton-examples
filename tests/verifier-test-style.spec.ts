import * as fs from 'node:fs';
import * as path from 'node:path';

const VERIFIER_SPEC_RE = /^Verifier_.*\.spec\.ts$/;
const DIRECT_INFRA_IMPORT_RE =
    /from ['"](?:@ton\/sandbox|@ton\/blueprint|@ton\/core|snarkjs|\.\/export-ton-verifier)['"]/;

describe('verifier test style', () => {
    const verifierSpecs = fs.readdirSync(__dirname).filter((name) => VERIFIER_SPEC_RE.test(name)).sort();

    it('runs verifier contracts through the shared groth16 runner', () => {
        expect(verifierSpecs.length).toBeGreaterThan(0);

        for (const specName of verifierSpecs) {
            const source = fs.readFileSync(path.join(__dirname, specName), 'utf8');

            expect(source).toContain("from './groth16-verifier-runner'");
            expect(source).not.toMatch(DIRECT_INFRA_IMPORT_RE);
        }
    });
});
