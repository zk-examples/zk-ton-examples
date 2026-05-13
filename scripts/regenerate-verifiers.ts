import { spawn } from 'node:child_process';

import {
    buildVerifierGenerationInvocation,
    formatVerifierGenerationCommand,
    verifierGenerationTasks,
    type VerifierGenerationTask,
} from './verifier-generation';

const isDryRun = process.argv.includes('--dry-run');

async function runTask(task: VerifierGenerationTask, index: number, total: number) {
    console.log(`[${index}/${total}] ${task.name}`);
    console.log(`> ${formatVerifierGenerationCommand(task)}`);

    if (isDryRun) {
        return;
    }

    const invocation = buildVerifierGenerationInvocation(task);

    await new Promise<void>((resolve, reject) => {
        const child = spawn(invocation.command, invocation.args, {
            cwd: process.cwd(),
            stdio: 'inherit',
        });

        child.on('error', reject);
        child.on('exit', (code) => {
            if (code === 0) {
                resolve();
                return;
            }

            reject(new Error(`Task "${task.name}" failed with exit code ${code ?? 'unknown'}.`));
        });
    });
}

async function main() {
    const total = verifierGenerationTasks.length;

    for (const [index, task] of verifierGenerationTasks.entries()) {
        await runTask(task, index + 1, total);
    }

    console.log(isDryRun ? `Dry run complete: ${total} commands.` : `Verifier generation complete: ${total} commands.`);
}

void main().catch((error: unknown) => {
    const message = error instanceof Error ? error.message : String(error);
    console.error(message);
    process.exit(1);
});
