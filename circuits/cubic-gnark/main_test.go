package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestMainWritesAllOutputsToArtifacts(t *testing.T) {
	cwd, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}

	tmp := t.TempDir()
	if err := os.Chdir(tmp); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		if err := os.Chdir(cwd); err != nil {
			t.Fatal(err)
		}
	})

	main()

	expected := []string{
		"proof.json",
		"verification_key.json",
		"proof_gnark.json",
		"verification_key_gnark.json",
		"public.json",
		"proof.bin",
		"verification_key.bin",
	}

	for _, name := range expected {
		if _, err := os.Stat(filepath.Join(tmp, "artifacts", name)); err != nil {
			t.Fatalf("expected artifact %s: %v", name, err)
		}

		if _, err := os.Stat(filepath.Join(tmp, name)); !os.IsNotExist(err) {
			t.Fatalf("expected no root output %s, got err=%v", name, err)
		}
	}
}

func TestGenerateArtifactsRejectsUnsatisfiedAssignment(t *testing.T) {
	err := generateArtifacts(t.TempDir(), CubicCircuit{X: 3, Y: 36})
	if err == nil {
		t.Fatal("expected an unsatisfied cubic assignment to be rejected")
	}
}
