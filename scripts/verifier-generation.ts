import path from 'node:path';

export type VerifierGenerationTask = {
    name: string;
    args: string[];
};

export const verifierGenerationTasks: VerifierGenerationTask[] = [
    {
        name: 'Multiplier tolk',
        args: ['./circuits/Multiplier/Multiplier_final.zkey', './contracts/verifier_multiplier.tolk'],
    },
    {
        name: 'Multiplier tolk named',
        args: [
            './circuits/Multiplier/Multiplier_final.zkey',
            './contracts/verifier_multiplier.tolk',
            '--contract-name',
            'multiplierVerifier',
        ],
    },
    {
        name: 'Multiplier func',
        args: ['./circuits/Multiplier/Multiplier_final.zkey', './contracts/verifier_multiplier.fc', '--func'],
    },
    {
        name: 'Multiplier tact',
        args: ['./circuits/Multiplier/Multiplier_final.zkey', './contracts/verifier_multiplier.tact', '--tact'],
    },
    {
        name: 'Groth16 FunC wrapper',
        args: ['import-wrapper', './wrappers/Verifier_func.ts', '--groth16', '--func', '--force'],
    },
    {
        name: 'Sudoku tolk',
        args: ['./circuits/Sudoku/Sudoku_final.zkey', './contracts/verifier_sudoku.tolk'],
    },
    {
        name: 'Sudoku func',
        args: ['./circuits/Sudoku/Sudoku_final.zkey', './contracts/verifier_sudoku.fc', '--func'],
    },
    {
        name: 'Sudoku tact',
        args: ['./circuits/Sudoku/Sudoku_final.zkey', './contracts/verifier_sudoku.tact', '--tact'],
    },
    {
        name: 'Cubic tolk',
        args: ['./circuits/cubic-gnark/verification_key.json', './contracts/verifier_cubic.tolk'],
    },
    {
        name: 'Cubic tolk named',
        args: [
            './circuits/cubic-gnark/verification_key.json',
            './contracts/verifier_cubic.tolk',
            '--contract-name',
            'Cubic',
        ],
    },
    {
        name: 'Cubic func',
        args: ['./circuits/cubic-gnark/verification_key.json', './contracts/verifier_cubic.fc', '--func'],
    },
    {
        name: 'Cubic tact',
        args: ['./circuits/cubic-gnark/verification_key.json', './contracts/verifier_cubic.tact', '--tact'],
    },
    {
        name: 'Arkworks tolk',
        args: ['./circuits/Arkworks/MulCircuit/json/verification_key.json', './contracts/verifier_ark.tolk'],
    },
    {
        name: 'Arkworks tolk named',
        args: [
            './circuits/Arkworks/MulCircuit/json/verification_key.json',
            './contracts/verifier_ark.tolk',
            '--contract-name',
            'arkVerifier',
        ],
    },
    {
        name: 'Arkworks func',
        args: ['./circuits/Arkworks/MulCircuit/json/verification_key.json', './contracts/verifier_ark.fc', '--func'],
    },
    {
        name: 'Arkworks tact',
        args: ['./circuits/Arkworks/MulCircuit/json/verification_key.json', './contracts/verifier_ark.tact', '--tact'],
    },
];

export function buildVerifierGenerationCommand(task: VerifierGenerationTask): string[] {
    return ['export-ton-verifier', ...task.args];
}

export function buildVerifierGenerationInvocation(task: VerifierGenerationTask): { command: string; args: string[] } {
    const cliPath = path.resolve(path.dirname(require.resolve('export-ton-verifier')), 'cli.js');
    return {
        command: process.execPath,
        args: [cliPath, ...task.args],
    };
}

export function formatVerifierGenerationCommand(task: VerifierGenerationTask): string {
    return `npx ${buildVerifierGenerationCommand(task).join(' ')}`;
}
