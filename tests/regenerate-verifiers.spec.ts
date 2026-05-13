import {
    buildVerifierGenerationCommand,
    buildVerifierGenerationInvocation,
    verifierGenerationTasks,
} from '../scripts/verifier-generation';

describe('verifier generation tasks', () => {
    it('covers every documented export-ton-verifier command', () => {
        expect(verifierGenerationTasks).toHaveLength(16);
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
