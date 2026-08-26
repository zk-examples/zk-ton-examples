import path from 'node:path';
import { spawnSync } from 'node:child_process';

import { proofFixtureSpecs } from '../scripts/fixtureManifest';

describe('tracked proof fixtures', () => {
    it('hash-checks and cryptographically verifies every supported proof snapshot', () => {
        expect(proofFixtureSpecs.map((fixture) => fixture.id)).toEqual([
            'multiplier-snarkjs',
            'multiplier-snarkjs-alternate',
            'sudoku-snarkjs',
            'cubic-gnark-snarkjs',
            'arkworks-mul-native',
            'arkworks-mimc-bn254',
            'arkworks-mimc-bls12-381',
            'arkworks-mul-bn254',
            'arkworks-mul-bls12-381',
            'arkworks-mulbn254',
        ]);

        const result = spawnSync(
            process.execPath,
            [path.join(__dirname, '../node_modules/ts-node/dist/bin.js'), 'scripts/fixtureManifest.ts', '--verify'],
            { cwd: path.join(__dirname, '..'), encoding: 'utf8' },
        );

        expect(result.status).toBe(0);
        expect(result.stdout).toContain('Tracked proof fixtures verified.');
        expect(result.stderr).toBe('');
    });
});
