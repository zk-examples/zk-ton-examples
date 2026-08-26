use std::error::Error;
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};

use ark_bls12_381::Bls12_381;
use ark_bn254::Bn254;
use ark_ec::{AffineRepr, pairing::Pairing};
use ark_ff::{Field, One, PrimeField, UniformRand};
use ark_groth16::{Groth16, Proof, VerifyingKey, prepare_verifying_key};
use ark_r1cs_std::{alloc::AllocVar, eq::EqGadget, fields::FieldVar, fields::fp::FpVar};
use ark_relations::gr1cs::{
    ConstraintSynthesizer, ConstraintSystem, ConstraintSystemRef, SynthesisError,
};
use ark_serialize::CanonicalSerialize;
use ark_snark::{CircuitSpecificSetupSNARK, SNARK};
use ark_snarkjs::{export_proof, export_vk};
use rand::{
    SeedableRng,
    rngs::{OsRng, StdRng},
};

const MIMC_ROUNDS: usize = 322;

#[derive(Clone)]
struct MulCircuit<F: PrimeField> {
    x: Option<F>,
    y: Option<F>,
    z: F,
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
        (&x * &y).enforce_equal(&z)?;
        Ok(())
    }
}

fn mimc<F: Field>(mut xl: F, mut xr: F, constants: &[F]) -> F {
    assert_eq!(constants.len(), MIMC_ROUNDS);
    for constant in constants {
        let tmp = xl + constant;
        let new_xl = tmp.square() * tmp + xr;
        xr = xl;
        xl = new_xl;
    }
    xl
}

#[derive(Clone)]
struct MiMCCircuit<F: PrimeField> {
    xl: Option<F>,
    xr: Option<F>,
    output: Option<F>,
    constants: Vec<F>,
}

impl<F: PrimeField> ConstraintSynthesizer<F> for MiMCCircuit<F> {
    fn generate_constraints(self, cs: ConstraintSystemRef<F>) -> Result<(), SynthesisError> {
        assert_eq!(self.constants.len(), MIMC_ROUNDS);
        let mut xl = FpVar::new_witness(cs.clone(), || {
            self.xl.ok_or(SynthesisError::AssignmentMissing)
        })?;
        let mut xr = FpVar::new_witness(cs.clone(), || {
            self.xr.ok_or(SynthesisError::AssignmentMissing)
        })?;
        let output = FpVar::new_input(cs, || self.output.ok_or(SynthesisError::AssignmentMissing))?;

        for constant in self.constants {
            let tmp = (&xl + constant).square()?;
            let new_xl = tmp * (&xl + constant) + xr;
            xr = xl;
            xl = new_xl;
        }
        output.enforce_equal(&xl)?;
        Ok(())
    }
}

struct Generated<E: Pairing> {
    vk: VerifyingKey<E>,
    proof: Proof<E>,
    public_inputs: Vec<E::ScalarField>,
}

fn prove_and_verify<E, C>(
    empty: C,
    assigned: C,
    public_inputs: Vec<E::ScalarField>,
) -> Result<Generated<E>, Box<dyn Error>>
where
    E: Pairing,
    C: ConstraintSynthesizer<E::ScalarField> + Clone,
{
    let cs = ConstraintSystem::<E::ScalarField>::new_ref();
    assigned.clone().generate_constraints(cs.clone())?;
    cs.finalize();
    if !cs.is_satisfied()? {
        return Err("generated circuit is not satisfied".into());
    }

    let mut rng = OsRng;
    let (pk, vk) = Groth16::<E>::setup(empty, &mut rng)?;
    let proof = Groth16::<E>::prove(&pk, assigned, &mut rng)?;
    let pvk = prepare_verifying_key(&vk);
    if !Groth16::<E>::verify_with_processed_vk(&pvk, &public_inputs, &proof)? {
        return Err("fresh Arkworks proof did not verify".into());
    }

    let mut wrong_inputs = public_inputs.clone();
    wrong_inputs[0] += E::ScalarField::one();
    if Groth16::<E>::verify_with_processed_vk(&pvk, &wrong_inputs, &proof)? {
        return Err("fresh Arkworks proof accepted a changed public input".into());
    }

    Ok(Generated {
        vk,
        proof,
        public_inputs,
    })
}

fn generate_mul<E>() -> Result<Generated<E>, Box<dyn Error>>
where
    E: Pairing,
    E::ScalarField: From<u128>,
{
    let x = E::ScalarField::from(641u128);
    let y = E::ScalarField::from(6_700_417u128);
    let z = x * y;
    prove_and_verify::<E, _>(
        MulCircuit {
            x: None,
            y: None,
            z: E::ScalarField::one(),
        },
        MulCircuit {
            x: Some(x),
            y: Some(y),
            z,
        },
        vec![z],
    )
}

fn generate_mimc<E>(seed: u64) -> Result<Generated<E>, Box<dyn Error>>
where
    E: Pairing,
{
    let mut public_rng = StdRng::seed_from_u64(seed);
    let constants = (0..MIMC_ROUNDS)
        .map(|_| E::ScalarField::rand(&mut public_rng))
        .collect::<Vec<_>>();
    let xl = E::ScalarField::rand(&mut public_rng);
    let xr = E::ScalarField::rand(&mut public_rng);
    let image = mimc(xl, xr, &constants);

    prove_and_verify::<E, _>(
        MiMCCircuit {
            xl: None,
            xr: None,
            output: None,
            constants: constants.clone(),
        },
        MiMCCircuit {
            xl: Some(xl),
            xr: Some(xr),
            output: Some(image),
            constants,
        },
        vec![image],
    )
}

fn export_snarkjs<E>(
    generated: &Generated<E>,
    output_directory: &Path,
) -> Result<(), Box<dyn Error>>
where
    E: Pairing + ark_snarkjs::snarkjs_common::CurveTag,
    <E::G1Affine as AffineRepr>::BaseField: PrimeField,
    <E::G2Affine as AffineRepr>::BaseField: ark_snarkjs::snarkjs_common::AsFp2,
{
    fs::create_dir_all(output_directory)?;
    export_proof::<E, _>(
        &generated.proof,
        &generated.public_inputs,
        output_directory.join("proof.json"),
    )?;
    export_vk::<E, _>(
        &generated.vk,
        generated.public_inputs.len(),
        output_directory.join("verification_key.json"),
    )?;
    Ok(())
}

fn write_bytes(path: &Path, bytes: &[u8]) -> Result<(), Box<dyn Error>> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let mut file = File::create(path)?;
    file.write_all(bytes)?;
    Ok(())
}

fn write_arkworks_bundle(
    output_directory: &Path,
    generated: &Generated<Bls12_381>,
) -> Result<(), Box<dyn Error>> {
    let mut vk_bytes = Vec::new();
    generated.vk.serialize_compressed(&mut vk_bytes)?;
    let mut proof_bytes = Vec::new();
    generated.proof.serialize_compressed(&mut proof_bytes)?;
    let mut public_input_bytes = Vec::new();
    generated.public_inputs[0].serialize_compressed(&mut public_input_bytes)?;

    let mut proof_a_bytes = Vec::new();
    generated.proof.a.serialize_compressed(&mut proof_a_bytes)?;
    let mut proof_b_bytes = Vec::new();
    generated.proof.b.serialize_compressed(&mut proof_b_bytes)?;
    let mut proof_c_bytes = Vec::new();
    generated.proof.c.serialize_compressed(&mut proof_c_bytes)?;

    let mut vk_alpha_g1 = Vec::new();
    generated
        .vk
        .alpha_g1
        .serialize_compressed(&mut vk_alpha_g1)?;
    let mut vk_beta_g2 = Vec::new();
    generated.vk.beta_g2.serialize_compressed(&mut vk_beta_g2)?;
    let mut vk_gamma_g2 = Vec::new();
    generated
        .vk
        .gamma_g2
        .serialize_compressed(&mut vk_gamma_g2)?;
    let mut vk_delta_g2 = Vec::new();
    generated
        .vk
        .delta_g2
        .serialize_compressed(&mut vk_delta_g2)?;

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
    write_bytes(
        &output_directory.join("groth16_artifacts.json"),
        json.as_bytes(),
    )
}

fn main() -> Result<(), Box<dyn Error>> {
    let project_directory = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    let fixtures_directory = project_directory
        .parent()
        .ok_or("missing Arkworks fixtures parent")?
        .join("json");
    let native_directory = project_directory.join("json");

    println!("Generating Arkworks MiMC BN254 fixture...");
    export_snarkjs(
        &generate_mimc::<Bn254>(0x4d49_4d43_424e_3235)?,
        &fixtures_directory.join("mimc/Bn254"),
    )?;

    println!("Generating Arkworks MiMC BLS12-381 fixture...");
    export_snarkjs(
        &generate_mimc::<Bls12_381>(0x4d49_4d43_424c_5331)?,
        &fixtures_directory.join("mimc/Bls12-381"),
    )?;

    println!("Generating Arkworks multiplication BN254 fixtures...");
    let mul_bn254 = generate_mul::<Bn254>()?;
    export_snarkjs(&mul_bn254, &fixtures_directory.join("mul/Bn254"))?;
    export_snarkjs(&mul_bn254, &fixtures_directory.join("mulbn254"))?;

    println!("Generating Arkworks multiplication BLS12-381 fixtures and native bundle...");
    let mul_bls = generate_mul::<Bls12_381>()?;
    export_snarkjs(&mul_bls, &fixtures_directory.join("mul/Bls12-381"))?;
    export_snarkjs(&mul_bls, &native_directory)?;
    write_arkworks_bundle(&native_directory, &mul_bls)?;

    println!("All Arkworks fixtures generated and self-verified.");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use ark_bls12_381::Fr as BlsFr;

    #[test]
    fn multiplication_constraint_accepts_the_expected_product() {
        let x = BlsFr::from(641u64);
        let y = BlsFr::from(6_700_417u64);
        let circuit = MulCircuit {
            x: Some(x),
            y: Some(y),
            z: x * y,
        };
        let cs = ConstraintSystem::new_ref();
        circuit.generate_constraints(cs.clone()).unwrap();
        assert!(cs.is_satisfied().unwrap());
    }

    #[test]
    fn mimc_constraint_accepts_the_computed_image() {
        let constants = (0..MIMC_ROUNDS)
            .map(|i| BlsFr::from((i + 1) as u64))
            .collect::<Vec<_>>();
        let xl = BlsFr::from(123u64);
        let xr = BlsFr::from(456u64);
        let image = mimc(xl, xr, &constants);
        let circuit = MiMCCircuit {
            xl: Some(xl),
            xr: Some(xr),
            output: Some(image),
            constants,
        };
        let cs = ConstraintSystem::new_ref();
        circuit.generate_constraints(cs.clone()).unwrap();
        assert!(cs.is_satisfied().unwrap());
    }
}
