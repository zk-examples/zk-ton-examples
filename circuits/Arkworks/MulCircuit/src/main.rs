use std::fs::{self, File};
use std::io::Write;
use std::path::Path;

use ark_bls12_381::{Bls12_381, Fr};
use ark_ff::PrimeField;
use ark_groth16::{Groth16, prepare_verifying_key};
use ark_r1cs_std::{alloc::AllocVar, eq::EqGadget, fields::fp::FpVar};
use ark_relations::gr1cs::{ConstraintSynthesizer, ConstraintSystemRef, SynthesisError};
use ark_serialize::CanonicalSerialize;
use ark_snark::SNARK;
use ark_snarkjs::{export_proof, export_vk};
use ark_std::One;
use ark_std::rand::thread_rng;

#[derive(Clone)]
struct MulCircuit<F: PrimeField> {
    pub x: Option<F>, // witness
    pub y: Option<F>, // witness
    pub z: F,         // public = x*y
}

impl<F: PrimeField> ConstraintSynthesizer<F> for MulCircuit<F> {
    fn generate_constraints(self, cs: ConstraintSystemRef<F>) -> Result<(), SynthesisError> {
        let x = FpVar::<F>::new_witness(cs.clone(), || {
            self.x.ok_or(SynthesisError::AssignmentMissing)
        })?;
        let y = FpVar::<F>::new_witness(cs.clone(), || {
            self.y.ok_or(SynthesisError::AssignmentMissing)
        })?;
        let z = FpVar::<F>::new_input(cs, || Ok(self.z))?;
        let prod = &x * &y;
        prod.enforce_equal(&z)?;
        Ok(())
    }
}

fn write_bytes(path: &Path, bytes: &[u8]) {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).unwrap();
    }
    let mut file = File::create(path).unwrap();
    file.write_all(bytes).unwrap();
}

fn write_arkworks_bundle(
    out_dir: &Path,
    vk: &ark_groth16::VerifyingKey<Bls12_381>,
    proof: &ark_groth16::Proof<Bls12_381>,
    public_input: &Fr,
) {
    let mut vk_bytes = Vec::new();
    vk.serialize_compressed(&mut vk_bytes).unwrap();
    let mut proof_bytes = Vec::new();
    proof.serialize_compressed(&mut proof_bytes).unwrap();
    let mut public_input_bytes = Vec::new();
    public_input
        .serialize_compressed(&mut public_input_bytes)
        .unwrap();

    let mut proof_a_bytes = Vec::new();
    proof.a.serialize_compressed(&mut proof_a_bytes).unwrap();
    let mut proof_b_bytes = Vec::new();
    proof.b.serialize_compressed(&mut proof_b_bytes).unwrap();
    let mut proof_c_bytes = Vec::new();
    proof.c.serialize_compressed(&mut proof_c_bytes).unwrap();

    let mut vk_alpha_g1 = Vec::new();
    vk.alpha_g1.serialize_compressed(&mut vk_alpha_g1).unwrap();
    let mut vk_beta_g2 = Vec::new();
    vk.beta_g2.serialize_compressed(&mut vk_beta_g2).unwrap();
    let mut vk_gamma_g2 = Vec::new();
    vk.gamma_g2.serialize_compressed(&mut vk_gamma_g2).unwrap();
    let mut vk_delta_g2 = Vec::new();
    vk.delta_g2.serialize_compressed(&mut vk_delta_g2).unwrap();

    let json = format!(
        "{{\n  \"curve\": \"bls12_381\",\n  \"vk\": \"{}\",\n  \"proof\": \"{}\",\n  \"public_input\": \"{}\",\n  \"proof_a\": \"{}\",\n  \"proof_b\": \"{}\",\n  \"proof_c\": \"{}\",\n  \"vk_alpha_g1\": \"{}\",\n  \"vk_beta_g2\": \"{}\",\n  \"vk_gamma_g2\": \"{}\",\n  \"vk_delta_g2\": \"{}\"\n}}\n",
        hex::encode(vk_bytes),
        hex::encode(proof_bytes),
        hex::encode(public_input_bytes),
        hex::encode(proof_a_bytes),
        hex::encode(proof_b_bytes),
        hex::encode(proof_c_bytes),
        hex::encode(vk_alpha_g1),
        hex::encode(vk_beta_g2),
        hex::encode(vk_gamma_g2),
        hex::encode(vk_delta_g2),
    );

    write_bytes(&out_dir.join("groth16_artifacts.json"), json.as_bytes());
}

fn main() {
    let mut rng = thread_rng();

    let x: u128 = 641;
    let y: u128 = 6_700_417;

    let xf = Fr::from(x);
    let yf = Fr::from(y);
    let zf = xf * yf;

    let empty = MulCircuit::<Fr> {
        x: None,
        y: None,
        z: Fr::one(),
    };
    let params =
        Groth16::<Bls12_381>::generate_random_parameters_with_reduction(empty, &mut rng).unwrap();

    let circuit = MulCircuit::<Fr> {
        x: Some(xf),
        y: Some(yf),
        z: zf,
    };
    let proof = Groth16::<Bls12_381>::prove(&params, circuit, &mut rng).unwrap();

    let pvk = prepare_verifying_key(&params.vk);
    let public_inputs = vec![zf];
    let ok = Groth16::<Bls12_381>::verify_with_processed_vk(&pvk, &public_inputs, &proof).unwrap();
    assert!(ok);

    let out_dir = Path::new("json");
    fs::create_dir_all(out_dir).unwrap();
    let _ = export_proof::<Bls12_381, _>(&proof, &public_inputs, out_dir.join("proof.json"));
    let _ = export_vk::<Bls12_381, _>(
        &params.vk,
        public_inputs.len(),
        out_dir.join("verification_key.json"),
    );
    write_arkworks_bundle(out_dir, &params.vk, &proof, &zf);
}
