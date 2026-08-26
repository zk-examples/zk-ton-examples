import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const repoRoot = path.resolve(__dirname, '..');
const circuitsRoot = path.join(repoRoot, 'circuits');
const ptauPath = path.join(circuitsRoot, 'bls12-381-pot14-final.ptau');
const snarkjsCli = path.join(repoRoot, 'node_modules', 'snarkjs', 'cli.js');

function run(command: string, args: string[], cwd: string, input?: string): void {
    const result = spawnSync(command, args, {
        cwd,
        input,
        stdio: input === undefined ? 'inherit' : ['pipe', 'inherit', 'inherit'],
    });
    if (result.error) {
        throw new Error(`Unable to run ${command}: ${result.error.message}`);
    }
    if (result.status !== 0) {
        throw new Error(`${path.basename(command)} ${args.join(' ')} failed with exit code ${result.status}.`);
    }
}

function snarkjs(args: string[], input?: string): void {
    run(process.execPath, [snarkjsCli, ...args], repoRoot, input);
}

function createDevelopmentPtau(): void {
    if (fs.existsSync(ptauPath)) {
        snarkjs(['powersoftau', 'verify', ptauPath]);
        return;
    }

    const temporaryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'zk-ton-examples-ptau-'));
    const initial = path.join(temporaryDirectory, 'pot14_0000.ptau');
    const contributed = path.join(temporaryDirectory, 'pot14_0001.ptau');
    const beaconed = path.join(temporaryDirectory, 'pot14_beacon.ptau');
    const prepared = path.join(temporaryDirectory, 'pot14_final.ptau');
    let contributionEntropy = crypto.randomBytes(64).toString('hex');
    let beaconEntropy = crypto.randomBytes(32).toString('hex');

    try {
        console.log('Creating a development BLS12-381 Powers of Tau transcript with 2^14 powers...');
        snarkjs(['powersoftau', 'new', 'bls12-381', '14', initial]);
        snarkjs(
            ['powersoftau', 'contribute', initial, contributed, '--name=zk-ton-examples local CSPRNG contribution'],
            `${contributionEntropy}\n`,
        );
        snarkjs([
            'powersoftau',
            'beacon',
            contributed,
            beaconed,
            beaconEntropy,
            '10',
            '--name=zk-ton-examples final CSPRNG beacon',
        ]);
        snarkjs(['powersoftau', 'prepare', 'phase2', beaconed, prepared]);
        snarkjs(['powersoftau', 'verify', prepared]);
        fs.copyFileSync(prepared, ptauPath);
    } finally {
        contributionEntropy = '';
        beaconEntropy = '';
        fs.rmSync(temporaryDirectory, { recursive: true, force: true });
    }
}

function buildZkey(
    label: string,
    r1csPath: string,
    zkeyPath: string,
    verificationKeyPath: string,
    temporaryDirectory: string,
): string {
    const initial = path.join(temporaryDirectory, `${label}_0000.zkey`);
    const final = path.join(temporaryDirectory, `${label}_final.zkey`);
    const verificationKey = path.join(temporaryDirectory, `${label}_verification_key.json`);
    let contributionEntropy = crypto.randomBytes(64).toString('hex');

    try {
        snarkjs(['groth16', 'setup', r1csPath, ptauPath, initial]);
        snarkjs(
            ['zkey', 'contribute', initial, final, `--name=${label} local CSPRNG contribution`],
            `${contributionEntropy}\n`,
        );
        snarkjs(['zkey', 'verify', r1csPath, ptauPath, final]);
        snarkjs(['zkey', 'export', 'verificationkey', final, verificationKey]);
        fs.copyFileSync(final, zkeyPath);
        fs.copyFileSync(verificationKey, verificationKeyPath);
        return final;
    } finally {
        contributionEntropy = '';
    }
}

function rebuildMultiplier(): void {
    const directory = path.join(circuitsRoot, 'Multiplier');
    const temporaryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'zk-ton-examples-multiplier-'));
    try {
        console.log('Rebuilding Multiplier Groth16 ZKey, VK, and proof...');
        const finalZkey = buildZkey(
            'Multiplier',
            path.join(directory, 'Multiplier.r1cs'),
            path.join(directory, 'Multiplier_final.zkey'),
            path.join(directory, 'verification_key.json'),
            temporaryDirectory,
        );
        for (const fixture of [
            { input: 'input.json', proof: 'proof.json', publicSignals: 'public.json' },
            {
                input: 'input-alternate.json',
                proof: 'proof-alternate.json',
                publicSignals: 'public-alternate.json',
            },
        ]) {
            const proof = path.join(temporaryDirectory, fixture.proof);
            const publicSignals = path.join(temporaryDirectory, fixture.publicSignals);
            snarkjs([
                'groth16',
                'fullprove',
                path.join(directory, fixture.input),
                path.join(directory, 'Multiplier_js', 'Multiplier.wasm'),
                finalZkey,
                proof,
                publicSignals,
            ]);
            snarkjs(['groth16', 'verify', path.join(directory, 'verification_key.json'), publicSignals, proof]);
            fs.copyFileSync(proof, path.join(directory, fixture.proof));
            fs.copyFileSync(publicSignals, path.join(directory, fixture.publicSignals));
        }
    } finally {
        fs.rmSync(temporaryDirectory, { recursive: true, force: true });
    }
}

function resolveNoname(): string {
    if (process.env.NONAME_BIN) {
        return path.resolve(process.env.NONAME_BIN);
    }
    return path.join(
        repoRoot,
        '.cache',
        'noname',
        '0e91c05b60b2c5a1b4ca9f7da71f61220531ed66',
        'bin',
        process.platform === 'win32' ? 'noname.exe' : 'noname',
    );
}

function rebuildSudoku(): void {
    const directory = path.join(circuitsRoot, 'Sudoku');
    const noname = resolveNoname();
    if (!fs.existsSync(noname)) {
        throw new Error(`Pinned Noname compiler is missing at ${noname}; run npm run noname:install.`);
    }

    const privateInputs = JSON.stringify(JSON.parse(fs.readFileSync(path.join(directory, 'private-input.json'), 'utf8')));
    const publicInputs = JSON.stringify(JSON.parse(fs.readFileSync(path.join(directory, 'public-input.json'), 'utf8')));
    const temporaryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'zk-ton-examples-sudoku-'));
    const generatedR1csPath = path.join(directory, 'output.r1cs');
    const witnessPath = path.join(directory, 'output.wtns');
    const trackedR1csPath = path.join(directory, 'Sudoku.r1cs');
    try {
        console.log('Compiling the Sudoku Noname circuit and witness...');
        run(noname, ['check'], directory);
        run(
            noname,
            ['run', '--backend', 'r1cs-bls12-381', '--private-inputs', privateInputs, '--public-inputs', publicInputs],
            directory,
        );
        snarkjs(['wtns', 'check', generatedR1csPath, witnessPath]);
        fs.copyFileSync(generatedR1csPath, trackedR1csPath);

        console.log('Rebuilding Sudoku Groth16 ZKey, VK, and proof...');
        const finalZkey = buildZkey(
            'Sudoku',
            trackedR1csPath,
            path.join(directory, 'Sudoku_final.zkey'),
            path.join(directory, 'verification_key.json'),
            temporaryDirectory,
        );
        const proof = path.join(temporaryDirectory, 'proof.json');
        const publicSignals = path.join(temporaryDirectory, 'public.json');
        snarkjs(['groth16', 'prove', finalZkey, witnessPath, proof, publicSignals]);
        snarkjs(['groth16', 'verify', path.join(directory, 'verification_key.json'), publicSignals, proof]);
        fs.copyFileSync(proof, path.join(directory, 'proof.json'));
        fs.copyFileSync(publicSignals, path.join(directory, 'public.json'));
    } finally {
        fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        fs.rmSync(witnessPath, { force: true });
        fs.rmSync(generatedR1csPath, { force: true });
    }
}

function main(): void {
    const mode = process.argv[2];
    if (mode !== '--multiplier' && mode !== '--all') {
        throw new Error('Use --multiplier or --all.');
    }
    createDevelopmentPtau();
    rebuildMultiplier();
    if (mode === '--all') {
        rebuildSudoku();
    }
}

try {
    main();
    process.exit(0);
} catch (error: unknown) {
    console.error(error instanceof Error ? error.message : error);
    process.exit(1);
}
