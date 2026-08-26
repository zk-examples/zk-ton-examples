import path from 'node:path';
import { spawnSync } from 'node:child_process';

const repoRoot = path.resolve(__dirname, '..');

function run(command: string, args: string[], cwd: string): void {
    const result = spawnSync(command, args, { cwd, stdio: 'inherit', shell: process.platform === 'win32' });
    if (result.error) {
        throw new Error(`Unable to run ${command}: ${result.error.message}`);
    }
    if (result.status !== 0) {
        throw new Error(`${command} ${args.join(' ')} failed with exit code ${result.status}.`);
    }
}

function main(): void {
    const gnarkDirectory = path.join(repoRoot, 'circuits', 'cubic-gnark');
    const arkworksDirectory = path.join(repoRoot, 'circuits', 'Arkworks', 'MulCircuit');

    run('go', ['mod', 'verify'], gnarkDirectory);
    run('go', ['test', '-count=1', './...'], gnarkDirectory);
    run('go', ['run', '.'], gnarkDirectory);

    run('cargo', ['fmt', '--check'], arkworksDirectory);
    run('cargo', ['test', '--locked'], arkworksDirectory);
    run('cargo', ['run', '--locked'], arkworksDirectory);
}

try {
    main();
    process.exit(0);
} catch (error: unknown) {
    console.error(error instanceof Error ? error.message : error);
    process.exit(1);
}
