import {
    buildVerifierGenerationCommand,
    buildVerifierGenerationInvocation,
    verifierGenerationTasks,
} from '../scripts/verifier-generation';

describe('verifier generation tasks', () => {
    it('covers every documented export-ton-verifier command', () => {
        expect(verifierGenerationTasks).toHaveLength(25);
        expect(verifierGenerationTasks.find((item) => item.name === 'Groth16 Tolk wrapper')).toBeUndefined();
    });

    it('builds the default Multiplier tolk command', () => {
        const task = verifierGenerationTasks.find((item) => item.name === 'Multiplier tolk');

        expect(task).toBeDefined();
        expect(buildVerifierGenerationCommand(task!)).toEqual([
            'export-ton-verifier',
            './circuits/Multiplier/Multiplier_final.zkey',
            './contracts/verifier_multiplier.tolk',
        ]);
    });

    it('builds the custom contract-name command', () => {
        const task = verifierGenerationTasks.find((item) => item.name === 'Multiplier tolk named');

        expect(task).toBeDefined();
        expect(buildVerifierGenerationCommand(task!)).toEqual([
            'export-ton-verifier',
            './circuits/Multiplier/Multiplier_final.zkey',
            './contracts/verifier_multiplier.tolk',
            '--contract-name',
            'multiplierVerifier',
        ]);
    });

    it('builds the wrapper import command', () => {
        const task = verifierGenerationTasks.find((item) => item.name === 'Groth16 FunC wrapper');

        expect(task).toBeDefined();
        expect(buildVerifierGenerationCommand(task!)).toEqual([
            'export-ton-verifier',
            'import-wrapper',
            './wrappers/Verifier_func.ts',
            '--groth16',
            '--func',
            '--force',
        ]);
    });

    it('builds the native gnark JSON command', () => {
        const task = verifierGenerationTasks.find((item) => item.name === 'Cubic gnark JSON tact');

        expect(task).toBeDefined();
        expect(buildVerifierGenerationCommand(task!)).toEqual([
            'export-ton-verifier',
            './circuits/cubic-gnark/artifacts/verification_key_gnark.json',
            './contracts/verifier_cubic_gnark_json.tact',
            '--tact',
        ]);
    });

    it('builds the native gnark binary command', () => {
        const task = verifierGenerationTasks.find((item) => item.name === 'Cubic gnark binary func');

        expect(task).toBeDefined();
        expect(buildVerifierGenerationCommand(task!)).toEqual([
            'export-ton-verifier',
            './circuits/cubic-gnark/artifacts/verification_key.bin',
            './contracts/verifier_cubic_gnark_bin.fc',
            '--func',
        ]);
    });

    it('builds the native arkworks command', () => {
        const task = verifierGenerationTasks.find((item) => item.name === 'Arkworks native tolk');

        expect(task).toBeDefined();
        expect(buildVerifierGenerationCommand(task!)).toEqual([
            'export-ton-verifier',
            './circuits/Arkworks/MulCircuit/json/groth16_artifacts.json',
            './contracts/verifier_arkworks.tolk',
        ]);
    });

    it('invokes the local export-ton-verifier cli with node', () => {
        const task = verifierGenerationTasks.find((item) => item.name === 'Multiplier tolk');

        expect(task).toBeDefined();

        const invocation = buildVerifierGenerationInvocation(task!);

        expect(invocation.command).toBe(process.execPath);
        expect(invocation.args[0].replace(/\\/g, '/')).toMatch(/node_modules\/export-ton-verifier\/dist\/cli\.js$/);
        expect(invocation.args.slice(1)).toEqual([
            './circuits/Multiplier/Multiplier_final.zkey',
            './contracts/verifier_multiplier.tolk',
        ]);
    });
});
