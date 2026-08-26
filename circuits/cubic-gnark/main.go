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

func artifactPath(directory, name string) string {
	return filepath.Join(directory, name)
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

func generateArtifacts(outputDirectory string, assignment CubicCircuit) error {
	if err := os.MkdirAll(outputDirectory, 0o755); err != nil {
		return fmt.Errorf("create artifact directory: %w", err)
	}

	var circuit CubicCircuit
	ccs, err := frontend.Compile(ecc.BLS12_381.ScalarField(), r1cs.NewBuilder, &circuit)
	if err != nil {
		return fmt.Errorf("compile circuit: %w", err)
	}

	pk, vk, err := groth16.Setup(ccs)
	if err != nil {
		return fmt.Errorf("setup Groth16: %w", err)
	}

	fullWitness, err := frontend.NewWitness(&assignment, ecc.BLS12_381.ScalarField())
	if err != nil {
		return fmt.Errorf("build witness: %w", err)
	}
	publicWitness, err := fullWitness.Public()
	if err != nil {
		return fmt.Errorf("build public witness: %w", err)
	}

	proof, err := groth16.Prove(ccs, pk, fullWitness)
	if err != nil {
		return fmt.Errorf("prove Groth16: %w", err)
	}
	if err := groth16.Verify(proof, vk, publicWitness); err != nil {
		return fmt.Errorf("verify fresh Groth16 proof: %w", err)
	}

	signals, err := publicSignals(publicWitness)
	if err != nil {
		return err
	}

	{
		proof_out, err := os.Create(artifactPath(outputDirectory, "proof.json"))
		if err != nil {
			return fmt.Errorf("create snarkjs proof: %w", err)
		}
		defer proof_out.Close()
		if err := gnarktosnarkjs.ExportProof(proof, signals, proof_out); err != nil {
			return fmt.Errorf("export snarkjs proof: %w", err)
		}
	}

	{
		out, err := os.Create(artifactPath(outputDirectory, "verification_key.json"))
		if err != nil {
			return fmt.Errorf("create snarkjs verification key: %w", err)
		}
		defer out.Close()
		if err := gnarktosnarkjs.ExportVerifyingKey(vk, out); err != nil {
			return fmt.Errorf("export snarkjs verification key: %w", err)
		}
	}

	if err := writeJSON(artifactPath(outputDirectory, "verification_key_gnark.json"), vk); err != nil {
		return err
	}
	if err := writeJSON(artifactPath(outputDirectory, "proof_gnark.json"), proof); err != nil {
		return err
	}
	if err := writeJSON(artifactPath(outputDirectory, "public.json"), signals); err != nil {
		return err
	}
	if err := writeBinary(artifactPath(outputDirectory, "verification_key.bin"), vk); err != nil {
		return err
	}
	if err := writeBinary(artifactPath(outputDirectory, "proof.bin"), proof); err != nil {
		return err
	}
	return nil
}

func main() {
	must(generateArtifacts(artifactsDir, CubicCircuit{X: 3, Y: 35}))
}
