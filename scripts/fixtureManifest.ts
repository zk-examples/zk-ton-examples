import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

import * as snarkjs from 'snarkjs';

export type ProofFixtureSpec = {
    id: string;
    verificationKeyPath: string;
    proofPath: string;
    publicSignalsPath?: string;
    embeddedPublicSignals?: 'publicSignals' | 'public_signals';
};

type ArtifactHash = { path: string; sha256: string };
type FixtureManifest = {
    schema: 1;
    snarkjs: string;
    artifacts: ArtifactHash[];
};

export const proofFixtureSpecs: ProofFixtureSpec[] = [
    {
        id: 'multiplier-snarkjs',
        verificationKeyPath: 'circuits/Multiplier/verification_key.json',
        proofPath: 'circuits/Multiplier/proof.json',
        publicSignalsPath: 'circuits/Multiplier/public.json',
    },
    {
        id: 'multiplier-snarkjs-alternate',
        verificationKeyPath: 'circuits/Multiplier/verification_key.json',
        proofPath: 'circuits/Multiplier/proof-alternate.json',
        publicSignalsPath: 'circuits/Multiplier/public-alternate.json',
    },
    {
        id: 'sudoku-snarkjs',
        verificationKeyPath: 'circuits/Sudoku/verification_key.json',
        proofPath: 'circuits/Sudoku/proof.json',
        publicSignalsPath: 'circuits/Sudoku/public.json',
    },
    {
        id: 'cubic-gnark-snarkjs',
        verificationKeyPath: 'circuits/cubic-gnark/artifacts/verification_key.json',
        proofPath: 'circuits/cubic-gnark/artifacts/proof.json',
        publicSignalsPath: 'circuits/cubic-gnark/artifacts/public.json',
    },
    {
        id: 'arkworks-mul-native',
        verificationKeyPath: 'circuits/Arkworks/MulCircuit/json/verification_key.json',
        proofPath: 'circuits/Arkworks/MulCircuit/json/proof.json',
        embeddedPublicSignals: 'publicSignals',
    },
    {
        id: 'arkworks-mimc-bn254',
        verificationKeyPath: 'circuits/Arkworks/json/mimc/Bn254/verification_key.json',
        proofPath: 'circuits/Arkworks/json/mimc/Bn254/proof.json',
        embeddedPublicSignals: 'publicSignals',
    },
    {
        id: 'arkworks-mimc-bls12-381',
        verificationKeyPath: 'circuits/Arkworks/json/mimc/Bls12-381/verification_key.json',
        proofPath: 'circuits/Arkworks/json/mimc/Bls12-381/proof.json',
        embeddedPublicSignals: 'publicSignals',
    },
    {
        id: 'arkworks-mul-bn254',
        verificationKeyPath: 'circuits/Arkworks/json/mul/Bn254/verification_key.json',
        proofPath: 'circuits/Arkworks/json/mul/Bn254/proof.json',
        embeddedPublicSignals: 'publicSignals',
    },
    {
        id: 'arkworks-mul-bls12-381',
        verificationKeyPath: 'circuits/Arkworks/json/mul/Bls12-381/verification_key.json',
        proofPath: 'circuits/Arkworks/json/mul/Bls12-381/proof.json',
        embeddedPublicSignals: 'publicSignals',
    },
    {
        id: 'arkworks-mulbn254',
        verificationKeyPath: 'circuits/Arkworks/json/mulbn254/verification_key.json',
        proofPath: 'circuits/Arkworks/json/mulbn254/proof.json',
        embeddedPublicSignals: 'publicSignals',
    },
];

const trackedArtifactPaths = [
    'package.json',
    'package-lock.json',
    'scripts/compileMultiplier.ps1',
    'scripts/installNoname.ps1',
    'scripts/rebuildSnarkjsFixtures.ts',
    'scripts/rebuildNativeFixtures.ts',
    'scripts/fixtureManifest.ts',
    'circuits/bls12-381-pot14-final.ptau',
    'circuits/Multiplier/Multiplier.circom',
    'circuits/Multiplier/Multiplier.r1cs',
    'circuits/Multiplier/Multiplier.sym',
    'circuits/Multiplier/Multiplier_js/Multiplier.wasm',
    'circuits/Multiplier/Multiplier_final.zkey',
    'circuits/Multiplier/verification_key.json',
    'circuits/Multiplier/input.json',
    'circuits/Multiplier/input-alternate.json',
    'circuits/Multiplier/proof.json',
    'circuits/Multiplier/public.json',
    'circuits/Multiplier/proof-alternate.json',
    'circuits/Multiplier/public-alternate.json',
    'circuits/Sudoku/Noname.toml',
    'circuits/Sudoku/src/main.no',
    'circuits/Sudoku/Sudoku.r1cs',
    'circuits/Sudoku/Sudoku_final.zkey',
    'circuits/Sudoku/verification_key.json',
    'circuits/Sudoku/private-input.json',
    'circuits/Sudoku/public-input.json',
    'circuits/Sudoku/proof.json',
    'circuits/Sudoku/public.json',
    'circuits/cubic-gnark/main.go',
    'circuits/cubic-gnark/go.mod',
    'circuits/cubic-gnark/go.sum',
    'circuits/cubic-gnark/artifacts/proof_gnark.json',
    'circuits/cubic-gnark/artifacts/proof.bin',
    'circuits/cubic-gnark/artifacts/proof.json',
    'circuits/cubic-gnark/artifacts/public.json',
    'circuits/cubic-gnark/artifacts/verification_key_gnark.json',
    'circuits/cubic-gnark/artifacts/verification_key.bin',
    'circuits/cubic-gnark/artifacts/verification_key.json',
    'circuits/Arkworks/MulCircuit/Cargo.toml',
    'circuits/Arkworks/MulCircuit/Cargo.lock',
    'circuits/Arkworks/MulCircuit/rust-toolchain.toml',
    'circuits/Arkworks/MulCircuit/src/main.rs',
    'circuits/Arkworks/MulCircuit/json/groth16_artifacts.json',
    'circuits/Arkworks/MulCircuit/json/proof.json',
    'circuits/Arkworks/MulCircuit/json/verification_key.json',
    ...proofFixtureSpecs
        .slice(5)
        .flatMap((fixture) => [fixture.verificationKeyPath, fixture.proofPath]),
];

const repoRoot = path.resolve(__dirname, '..');
const manifestPath = path.join(repoRoot, 'circuits', 'fixtures-manifest.json');
const normalizedTextExtensions = new Set([
    '.circom',
    '.go',
    '.json',
    '.lock',
    '.mod',
    '.no',
    '.nvmrc',
    '.ps1',
    '.rs',
    '.sum',
    '.sym',
    '.toml',
    '.ts',
]);

function resolve(relativePath: string): string {
    return path.join(repoRoot, ...relativePath.split('/'));
}

function sha256(relativePath: string): string {
    const contents = fs.readFileSync(resolve(relativePath));
    const extension = path.extname(relativePath).toLowerCase();
    const isText = path.basename(relativePath) === '.nvmrc' || normalizedTextExtensions.has(extension);
    const canonicalContents = isText
        ? Buffer.from(contents.toString('utf8').replace(/\r\n?/g, '\n'), 'utf8')
        : contents;
    return crypto.createHash('sha256').update(canonicalContents).digest('hex');
}

function packageVersion(packageName: string): string {
    return JSON.parse(fs.readFileSync(path.join(repoRoot, 'node_modules', packageName, 'package.json'), 'utf8')).version;
}

function artifactHashes(): ArtifactHash[] {
    return [...new Set(trackedArtifactPaths)].map((artifactPath) => ({
        path: artifactPath,
        sha256: sha256(artifactPath),
    }));
}

function assertEqual(label: string, actual: unknown, expected: unknown): void {
    if (JSON.stringify(actual) !== JSON.stringify(expected)) {
        throw new Error(`${label} mismatch.\nExpected: ${JSON.stringify(expected)}\nActual:   ${JSON.stringify(actual)}`);
    }
}

function publicSignals(spec: ProofFixtureSpec, proof: Record<string, unknown>): string[] {
    if (spec.publicSignalsPath) {
        return JSON.parse(fs.readFileSync(resolve(spec.publicSignalsPath), 'utf8')) as string[];
    }
    const embedded = spec.embeddedPublicSignals && proof[spec.embeddedPublicSignals];
    if (!Array.isArray(embedded)) {
        throw new Error(`${spec.id} does not contain embedded public signals.`);
    }
    return embedded.map(String);
}

async function verifyProofFixtures(): Promise<void> {
    for (const spec of proofFixtureSpecs) {
        const verificationKey = JSON.parse(fs.readFileSync(resolve(spec.verificationKeyPath), 'utf8'));
        const proof = JSON.parse(fs.readFileSync(resolve(spec.proofPath), 'utf8')) as snarkjs.Groth16Proof &
            Record<string, unknown>;
        if (!(await snarkjs.groth16.verify(verificationKey, publicSignals(spec, proof), proof))) {
            throw new Error(`snarkjs rejected tracked proof fixture ${spec.id}.`);
        }
    }
}

export async function recordFixtureManifest(): Promise<void> {
    await verifyProofFixtures();
    const manifest: FixtureManifest = {
        schema: 1,
        snarkjs: packageVersion('snarkjs'),
        artifacts: artifactHashes(),
    };
    fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
    console.log('Recorded circuits/fixtures-manifest.json.');
}

export async function verifyFixtureManifest(): Promise<void> {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8')) as FixtureManifest;
    assertEqual('fixture manifest schema', manifest.schema, 1);
    assertEqual('fixture manifest snarkjs version', manifest.snarkjs, packageVersion('snarkjs'));
    assertEqual('fixture artifact hashes', artifactHashes(), manifest.artifacts);
    await verifyProofFixtures();
}

async function main(): Promise<void> {
    if (process.argv[2] === '--record') {
        await recordFixtureManifest();
        return;
    }
    if (process.argv[2] === '--verify') {
        await verifyFixtureManifest();
        console.log('Tracked proof fixtures verified.');
        return;
    }
    throw new Error('Use --record or --verify.');
}

if (require.main === module) {
    void main().then(
        () => process.exit(0),
        (error: unknown) => {
            console.error(error instanceof Error ? error.message : error);
            process.exit(1);
        },
    );
}
