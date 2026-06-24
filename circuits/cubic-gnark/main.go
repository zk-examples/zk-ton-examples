package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"github.com/consensys/gnark-crypto/ecc"
	bls12381fr "github.com/consensys/gnark-crypto/ecc/bls12-381/fr"
	"github.com/consensys/gnark/backend/groth16"
	"github.com/consensys/gnark/backend/witness"
	"github.com/consensys/gnark/frontend"
	"github.com/consensys/gnark/frontend/cs/r1cs"
	gnarktosnarkjs "github.com/mysteryon88/gnark-to-snarkjs"
)

const artifactsDir = "artifacts"

// CubicCircuit defines a simple circuit
// x**3 + x + 5 == y
type CubicCircuit struct {
	// struct tags on a variable is optional
	// default uses variable name and secret visibility.
	X frontend.Variable `gnark:"x"`
	Y frontend.Variable `gnark:",public"`
}

// Define declares the circuit constraints
// x**3 + x + 5 == y
func (circuit *CubicCircuit) Define(api frontend.API) error {
	x3 := api.Mul(circuit.X, circuit.X, circuit.X)
	api.AssertIsEqual(circuit.Y, api.Add(x3, circuit.X, 5))
	return nil
}

func artifactPath(name string) string {
	return filepath.Join(artifactsDir, name)
}

func publicSignals(w witness.Witness) ([]string, error) {
	vector, ok := w.Vector().(bls12381fr.Vector)
	if !ok {
		return nil, fmt.Errorf("unsupported public witness vector type %T", w.Vector())
	}

	signals := make([]string, len(vector))
	for i := range vector {
		signals[i] = vector[i].String()
	}
	return signals, nil
}

func writeJSON(path string, value any) error {
	file, err := os.Create(path)
	if err != nil {
		return fmt.Errorf("create %s: %w", path, err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(value); err != nil {
		return fmt.Errorf("write %s: %w", path, err)
	}
	return nil
}

type writerTo interface {
	WriteTo(io.Writer) (int64, error)
}

func writeBinary(path string, value writerTo) error {
	file, err := os.Create(path)
	if err != nil {
		return fmt.Errorf("create %s: %w", path, err)
	}
	defer file.Close()

	if _, err := value.WriteTo(file); err != nil {
		return fmt.Errorf("write %s: %w", path, err)
	}
	return nil
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}

func main() {
	must(os.MkdirAll(artifactsDir, 0o755))

	// compiles our circuit into a R1CS
	var circuit CubicCircuit
	ccs, _ := frontend.Compile(ecc.BLS12_381.ScalarField(), r1cs.NewBuilder, &circuit)

	// groth16 zkSNARK: Setup
	pk, vk, _ := groth16.Setup(ccs)

	// witness definition
	assignment := CubicCircuit{X: 3, Y: 35}
	witness, _ := frontend.NewWitness(&assignment, ecc.BLS12_381.ScalarField())
	publicWitness, _ := witness.Public()

	// groth16: Prove & Verify
	proof, _ := groth16.Prove(ccs, pk, witness)
	groth16.Verify(proof, vk, publicWitness)

	publicSignals, _ := publicSignals(publicWitness)

	// Export the proof
	{
		proof_out, err := os.Create(artifactPath("proof.json"))
		must(err)
		defer proof_out.Close()
		must(gnarktosnarkjs.ExportProof(proof, publicSignals, proof_out))
	}

	// Export the verification key
	{
		out, err := os.Create(artifactPath("verification_key.json"))
		must(err)
		defer out.Close()
		must(gnarktosnarkjs.ExportVerifyingKey(vk, out))
	}

	must(writeJSON(artifactPath("verification_key_gnark.json"), vk))
	must(writeJSON(artifactPath("proof_gnark.json"), proof))
	must(writeJSON(artifactPath("public.json"), publicSignals))
	must(writeBinary(artifactPath("verification_key.bin"), vk))
	must(writeBinary(artifactPath("proof.bin"), proof))
}
