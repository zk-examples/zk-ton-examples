# zk-ton-example

This repository is currently under development and testing.
It demonstrates how to integrate zero-knowledge proofs from **Circom**, **Noname**, **Gnark** or **Arkworks** into the TON blockchain using smart contracts written in **FunC**, **Tolk** and **Tact**.
The current implementation uses the **Groth16** proving system for on-chain verification.

Gas cost tests have been performed, and the results are located in the `bench-snapshots` directory.

Example usage of verifiers in a TON project can be found at: [zk-examples/zkJetton (Tact)](https://github.com/zk-examples/zkJetton)

An experimental repository exploring PLONK-based verification on TON is also available: [zk-examples/zk-ton-plonk](https://github.com/zk-examples/zk-ton-plonk)

For more details, see the [TON documentation on zk-proofs](https://docs.ton.org/contract-dev/zero-knowledge).

## How to create

```sh
npm create ton@latest

npm install snarkjs @types/snarkjs
npm install export-ton-verifier@latest
```

## How to use

All required circuit artifacts and generated verifier sources are checked in. The normal setup is:

```sh
npm ci
npm run fixtures:verify
npx blueprint build --all
npm test
```

The generated verifier sources are checked in, so the normal workflow does not regenerate them. Run `npm run generate:verifiers` explicitly when validating or updating the generated contracts; it covers Circom/snarkjs, Noname/snarkjs, Gnark snarkjs JSON, Gnark native JSON, Gnark native binary, Arkworks snarkjs JSON and Arkworks native bundle inputs without rebuilding circuit artifacts.

Normal setup verifies `circuits/fixtures-manifest.json` and every real proof with snarkjs. It does not invoke Circom, Noname, Go, Rust, trusted setup, or proving. Node 24.16.0, npm 11.13.0, Rust 1.97.1 for Arkworks, and Rust 1.79.0 for the pinned Noname R1CS compiler are pinned by repository files and installer scripts.

## Rebuild every circuit, verification key, and proof

The complete workflow is scripted. It compiles the Circom and Noname circuits, creates a development BLS12-381 Powers of Tau transcript with fresh operating-system CSPRNG entropy when it is absent, rebuilds Groth16 keys and proofs, regenerates all Gnark and Arkworks formats, verifies every proof, and records SHA-256 hashes.

```sh
npm ci
npm run noname:install
npm run fixtures:build
npm run generate:verifiers
npx blueprint build --all
npm test
```

### Multiplier (circom)

```sh
mkdir circuits/Multiplier
cd circuits/Multiplier

# The full circuit/key/proof rebuild is `npm run fixtures:build` from the repository root.
cd ../..

# export Tolk contract
npx export-ton-verifier ./circuits/Multiplier/Multiplier_final.zkey ./contracts/verifier_multiplier.tolk
npx export-ton-verifier ./circuits/Multiplier/Multiplier_final.zkey ./contracts/verifier_multiplier.tolk --contract-name multiplierVerifier
# export FunC contract
npx export-ton-verifier ./circuits/Multiplier/Multiplier_final.zkey ./contracts/verifier_multiplier.fc --func
# export Tact contract
npx export-ton-verifier ./circuits/Multiplier/Multiplier_final.zkey ./contracts/verifier_multiplier.tact --tact

# Only copy the TypeScript wrapper
npx export-ton-verifier import-wrapper ./wrappers/Verifier_tolk.ts --groth16 --force
npx export-ton-verifier import-wrapper ./wrappers/Verifier_func.ts --groth16 --func --force
```

### Sudoku (noname)

- [Article about integration with SnarkJS](https://blog.zksecurity.xyz/posts/noname-r1cs/)

```sh
# `npm run fixtures:build` installs/uses the pinned compiler, reads the tracked
# private/public input JSON, and verifies the resulting proof before recording it.

# export Tolk contract
npx export-ton-verifier ./circuits/Sudoku/Sudoku_final.zkey ./contracts/verifier_sudoku.tolk
# export FunC contract
npx export-ton-verifier ./circuits/Sudoku/Sudoku_final.zkey ./contracts/verifier_sudoku.fc --func
# export Tact contract
npx export-ton-verifier ./circuits/Sudoku/Sudoku_final.zkey ./contracts/verifier_sudoku.tact --tact
```

### Gnark and Arkworks

You can generate a smart contract that verifies zk-SNARK proofs using a verification key.

For this workflow you need two files:

- `verification_key.json` – exported for your compiled circuit.
- `proof.json` – a zk-SNARK proof.

To export these files, use my:

- Go package: [mysteryon88/gnark-to-snarkjs](https://github.com/mysteryon88/gnark-to-snarkjs)
- Rust crate: [mysteryon88/ark-snarkjs](https://github.com/mysteryon88/ark-snarkjs)

Once you have both files, you can feed verification_key.json into the contract generator to produce an on-chain verifier.
Then `proof.json` can be used to test and validate the contract logic.

#### Cubic (Gnark)

- [gnark](https://github.com/Consensys/gnark)

```sh
# dependencies
go get github.com/consensys/gnark@latest
go get github.com/mysteryon88/gnark-to-snarkjs@latest

# compilation, export
go run main.go

# export Tolk contract
npx export-ton-verifier ./circuits/cubic-gnark/artifacts/verification_key.json ./contracts/verifier_cubic.tolk
npx export-ton-verifier ./circuits/cubic-gnark/artifacts/verification_key.json ./contracts/verifier_cubic.tolk --contract-name Cubic
# export FunC contract
npx export-ton-verifier ./circuits/cubic-gnark/artifacts/verification_key.json ./contracts/verifier_cubic.fc --func
# export Tact contract
npx export-ton-verifier ./circuits/cubic-gnark/artifacts/verification_key.json ./contracts/verifier_cubic.tact --tact

# export native Gnark JSON contracts
npx export-ton-verifier ./circuits/cubic-gnark/artifacts/verification_key_gnark.json ./contracts/verifier_cubic_gnark_json.tolk
npx export-ton-verifier ./circuits/cubic-gnark/artifacts/verification_key_gnark.json ./contracts/verifier_cubic_gnark_json.fc --func
npx export-ton-verifier ./circuits/cubic-gnark/artifacts/verification_key_gnark.json ./contracts/verifier_cubic_gnark_json.tact --tact

# export native Gnark binary contracts
npx export-ton-verifier ./circuits/cubic-gnark/artifacts/verification_key.bin ./contracts/verifier_cubic_gnark_bin.tolk
npx export-ton-verifier ./circuits/cubic-gnark/artifacts/verification_key.bin ./contracts/verifier_cubic_gnark_bin.fc --func
npx export-ton-verifier ./circuits/cubic-gnark/artifacts/verification_key.bin ./contracts/verifier_cubic_gnark_bin.tact --tact

# testing contracts
npx blueprint build --all
npx blueprint test Verifier_cubic_tact
npx blueprint test Verifier_cubic_gnark_json_tact
npx blueprint test Verifier_cubic_gnark_bin_tact
```

#### Multiplier (Arkworks)

- [arkworks](https://arkworks.rs/)

```sh
# dependencies
cargo add ark-snarkjs

# compilation, export
cargo run

# export Tolk contract
npx export-ton-verifier ./circuits/Arkworks/MulCircuit/json/verification_key.json ./contracts/verifier_ark.tolk
npx export-ton-verifier ./circuits/Arkworks/MulCircuit/json/verification_key.json ./contracts/verifier_ark.tolk --contract-name arkVerifier
# export FunC contract
npx export-ton-verifier ./circuits/Arkworks/MulCircuit/json/verification_key.json ./contracts/verifier_ark.fc --func
# export Tact contract
npx export-ton-verifier ./circuits/Arkworks/MulCircuit/json/verification_key.json ./contracts/verifier_ark.tact --tact

# export native Arkworks bundle contracts
npx export-ton-verifier ./circuits/Arkworks/MulCircuit/json/groth16_artifacts.json ./contracts/verifier_arkworks.tolk
npx export-ton-verifier ./circuits/Arkworks/MulCircuit/json/groth16_artifacts.json ./contracts/verifier_arkworks.fc --func
npx export-ton-verifier ./circuits/Arkworks/MulCircuit/json/groth16_artifacts.json ./contracts/verifier_arkworks.tact --tact

# testing contracts
npx blueprint build --all
npx blueprint test Verifier_ark
npx blueprint test Verifier_arkworks_tact
```
