# zk-ton-example

This repository is currently under development and testing.
It demonstrates how to integrate zero-knowledge proofs from **Circom**, **Noname**, **Gnark** or **Arkworks** into the TON blockchain using smart contracts written in **FunC**, **Tolk** and **Tact**.

Gas cost tests have been performed, and the results are located in the `bench-snapshots` directory.

Example usage of verifiers in a TON project can be found at: [zk-examples/zkJetton (Tact)](https://github.com/zk-examples/zkJetton)

For more details, see the [TON documentation on zk-proofs](https://docs.ton.org/contract-dev/zero-knowledge).

## How to create

```sh
npm create ton@latest

npm install snarkjs @types/snarkjs
npm install export-ton-verifier@latest
```

## How to use

### Multiplier (circom)

```sh
mkdir circuits/Multiplier
cd circuits/Multiplier

# compile circuit
circom Multiplier.circom --r1cs --wasm --sym --prime bls12381

# trusted setup
snarkjs powersoftau new bls12-381 10 pot10_0000.ptau -v
snarkjs powersoftau contribute pot10_0000.ptau pot10_0001.ptau --name="First contribution" -v -e="some random text"
snarkjs powersoftau prepare phase2 pot10_0001.ptau pot10_final.ptau -v
snarkjs groth16 setup Multiplier.r1cs pot10_final.ptau Multiplier_0000.zkey
snarkjs zkey contribute Multiplier_0000.zkey Multiplier_final.zkey --name="1st Contributor Name" -v -e="some random text"
snarkjs zkey export verificationkey Multiplier_final.zkey verification_key.json

cd ../..

# export FunC contract
npx export-ton-verifier ./circuits/Multiplier/Multiplier_final.zkey ./contracts/verifier_multiplier.fc
# export Tact contract
npx export-ton-verifier ./circuits/Multiplier/Multiplier_final.zkey ./contracts/verifier_multiplier.tact --tact
# export Tolk contract
npx export-ton-verifier ./circuits/Multiplier/Multiplier_final.zkey ./contracts/verifier_multiplier.tolk --tolk

# Only copy the TypeScript wrapper
npx export-ton-verifier import-wrapper ./wrappers/Verifier.ts --force
```

### Sudoku (noname)

- [Article about integration with SnarkJS](https://blog.zksecurity.xyz/posts/noname-r1cs/)

```sh
noname check

noname run --backend r1cs-bls12-381 --private-inputs '{"solution": { "inner": ["9", "5", "3", "6", "2", "1", "7", "8", "4", "1", "4", "8", "7", "5", "9", "2", "6", "3", "2", "7", "6", "8", "3", "4", "9", "5", "1", "3", "6", "9", "2", "7", "5", "4", "1", "8", "4", "8", "5", "9", "1", "6", "3", "7", "2", "7", "1", "2", "3", "4", "8", "6", "9", "5", "6", "3", "7", "1", "8", "2", "5", "4", "9", "5", "2", "1", "4", "9", "7", "8", "3", "6", "8", "9", "4", "5", "6", "3", "1", "2", "7"] }}' --public-inputs '{"grid": { "inner": ["0", "5", "3", "6", "2", "1", "7", "8", "4", "0", "4", "8", "7", "5", "9", "2", "6", "3", "2", "7", "6", "8", "3", "4", "9", "5", "1", "3", "6", "9", "2", "7", "0", "4", "1", "8", "4", "8", "5", "9", "1", "6", "3", "7", "2", "0", "1", "2", "3", "4", "8", "6", "9", "5", "6", "3", "0", "1", "8", "2", "5", "4", "9", "5", "2", "1", "4", "9", "0", "8", "3", "6", "8", "9", "4", "5", "6", "3", "1", "2", "7"] }}'

# trusted setup
snarkjs powersoftau new bls12-381 14 pot14_0000.ptau -v
snarkjs powersoftau contribute pot14_0000.ptau pot14_0001.ptau --name="First contribution" -v -e="some random text"
snarkjs powersoftau prepare phase2 pot14_0001.ptau pot14_final.ptau -v
snarkjs groth16 setup Sudoku.r1cs pot14_final.ptau Sudoku_0000.zkey
snarkjs zkey contribute Sudoku_0000.zkey Sudoku_final.zkey --name="1st Contributor Name" -v -e="some random text"
snarkjs zkey export verificationkey Sudoku_final.zkey verification_key.json

# Generating a Proof
snarkjs groth16 prove Sudoku_final.zkey Sudoku.wtns proof.json public.json
# Verifying a Proof
snarkjs groth16 verify verification_key.json public.json proof.json

# export FunC contract
npx export-ton-verifier ./circuits/Sudoku/Sudoku_final.zkey ./contracts/verifier_sudoku.fc
# export Tact contract
npx export-ton-verifier ./circuits/Sudoku/Sudoku_final.zkey ./contracts/verifier_sudoku.tact --tact
# export Tolk contract
npx export-ton-verifier ./circuits/Sudoku/Sudoku_final.zkey ./contracts/verifier_sudoku.tolk --tolk
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

# export FunC contract
npx export-ton-verifier ./circuits/cubic-gnark/verification_key.json ./contracts/verifier_cubic.fc
# export Tact contract
npx export-ton-verifier ./circuits/cubic-gnark/verification_key.json ./contracts/verifier_cubic.tact --tact
# export Tolk contract
npx export-ton-verifier ./circuits/cubic-gnark/verification_key.json ./contracts/verifier_cubic.tolk --tolk

# testing contracts
npx blueorint build
npx blueprint test Verifier_cubic_tact
```

#### Multiplier (Arkworks)

- [arkworks](https://arkworks.rs/)

```sh
# dependencies
cargo add ark-snarkjs

# compilation, export
cargo run

# export FunC contract
npx export-ton-verifier ./circuits/Arkworks/MulCircuit/json/verification_key.json ./contracts/verifier_ark.fc
# export Tact contract
npx export-ton-verifier ./circuits/Arkworks/MulCircuit/json/verification_key.json ./contracts/verifier_ark.tact --tact
# export Tolk contract
npx export-ton-verifier ./circuits/Arkworks/MulCircuit/json/verification_key.json ./contracts/verifier_ark.tolk --tolk

# testing contracts
npx blueorint build --all
npx blueprint test Verifier_ark
```
