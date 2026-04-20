import type * as ExportTonVerifier from 'export-ton-verifier' with { 'resolution-mode': 'require' };

let exportTonVerifier: typeof ExportTonVerifier | undefined;

export function getExportTonVerifier() {
    exportTonVerifier ??= require('export-ton-verifier') as typeof ExportTonVerifier;
    return exportTonVerifier;
}
