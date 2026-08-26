const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const repositoryRoot = path.resolve(__dirname, '..');
const expected = {
    'circuits/Multiplier/Multiplier.circom': 'b5593cb4ee3d75bcfbd47490680c1a1143843e3bd69490d9e4caaccc0182aef7',
    'circuits/Multiplier/Multiplier_js/Multiplier.wasm':
        '091863c47764a6607d66938711ecadd8003508715a7878ab65ed962425cdcc2a',
};

for (const [relativePath, expectedHash] of Object.entries(expected)) {
    const filePath = path.join(repositoryRoot, relativePath);
    const actualHash = crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex');
    if (actualHash !== expectedHash) {
        throw new Error(`${relativePath} SHA-256 mismatch: expected ${expectedHash}, got ${actualHash}`);
    }
}

console.log('Multiplier source and WASM hashes verified.');
