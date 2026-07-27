import '@ton/test-utils';

import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { beginCell, Cell, toNano } from '@ton/core';
import { compile } from '@ton/blueprint';

import { getExportTonVerifier } from './export-ton-verifier';
import { GasLogAndSave } from './gas-logger';
import type { Groth16Payload } from './groth16-payloads';

type TonValue = bigint | string;

type FuncOrTolkWrapper = {
    createFromConfig(config: Record<string, never>, code: Cell): any;
};

type TactWrapper = {
    fromInit(): Promise<any>;
};

export type DeployedFuncOrTolkVerifier = {
    blockchain: Blockchain;
    verifier: SandboxContract<any>;
    deployer: SandboxContract<TreasuryContract>;
};

function toTonValue(value: TonValue | undefined, fallback: string) {
    if (typeof value === 'bigint') {
        return value;
    }
    return toNano(value ?? fallback);
}

export function payloadToFuncOrTolkArgs(payload: Groth16Payload) {
    return {
        pi_a: payload.pi_a,
        pi_b: payload.pi_b,
        pi_c: payload.pi_c,
        pubInputs: payload.pubInputs,
    };
}

export async function deployFuncOrTolkVerifier(opts: {
    compileName: string;
    gasName: string;
    Wrapper: FuncOrTolkWrapper;
    gasLog: GasLogAndSave;
    deployValue?: TonValue;
}): Promise<DeployedFuncOrTolkVerifier> {
    const code = await compile(opts.compileName);
    opts.gasLog.rememberBocSize(opts.gasName, code);

    const blockchain = await Blockchain.create();
    const verifier = blockchain.openContract(opts.Wrapper.createFromConfig({}, code)) as SandboxContract<any>;
    const deployer = await blockchain.treasury('deployer');

    const deployResult = await verifier.sendDeploy(deployer.getSender(), toTonValue(opts.deployValue, '0.05'));
    expect(deployResult.transactions).toHaveTransaction({
        from: deployer.address,
        to: verifier.address,
        deploy: true,
        success: true,
    });
    opts.gasLog.rememberGas('Deploy', deployResult.transactions.slice(1));

    return { blockchain, verifier, deployer };
}

export async function callFuncOrTolkGetter(
    verifier: SandboxContract<any>,
    payload: Groth16Payload,
    getMethodName = 'getVerify',
) {
    const getter = verifier[getMethodName] as
        | ((payload: ReturnType<typeof payloadToFuncOrTolkArgs>) => Promise<boolean>)
        | undefined;
    if (!getter) {
        throw new Error(`Verifier wrapper does not expose ${getMethodName}.`);
    }
    return getter.call(verifier, payloadToFuncOrTolkArgs(payload));
}

export async function expectFuncOrTolkGetter(
    verifier: SandboxContract<any>,
    payload: Groth16Payload,
    getMethodName = 'getVerify',
) {
    expect(await callFuncOrTolkGetter(verifier, payload, getMethodName)).toBe(true);
}

export async function sendFuncOrTolkVerify(
    deployed: Pick<DeployedFuncOrTolkVerifier, 'verifier' | 'deployer'>,
    payload: Groth16Payload,
    verifyValue?: TonValue,
) {
    return deployed.verifier.sendVerify(deployed.deployer.getSender(), {
        ...payloadToFuncOrTolkArgs(payload),
        value: toTonValue(verifyValue, '0.05'),
    });
}

export async function runFuncOrTolkVerifierTest(opts: {
    compileName: string;
    gasName: string;
    Wrapper: FuncOrTolkWrapper;
    gasLog: GasLogAndSave;
    payload: Groth16Payload;
    getMethodName?: string;
    deployValue?: TonValue;
    verifyValue?: TonValue;
}) {
    const deployed = await deployFuncOrTolkVerifier(opts);

    await expectFuncOrTolkGetter(deployed.verifier, opts.payload, opts.getMethodName);

    const verifyResult = await sendFuncOrTolkVerify(deployed, opts.payload, opts.verifyValue);
    expect(verifyResult.transactions).toHaveTransaction({
        from: deployed.deployer.address,
        to: deployed.verifier.address,
        success: true,
    });
    opts.gasLog.rememberGas('Verify', verifyResult.transactions.slice(1));
}

export async function runTactVerifierTest(opts: {
    gasName: string;
    Contract: TactWrapper;
    gasLog: GasLogAndSave;
    payload: Groth16Payload;
    deployValue?: TonValue;
    verifyValue?: TonValue;
}) {
    const { dictFromInputList } = getExportTonVerifier();
    const blockchain = await Blockchain.create();
    const verifier = blockchain.openContract((await opts.Contract.fromInit()) as any) as SandboxContract<any>;
    const deployer = await blockchain.treasury('deployer');
    const pubInputsDict = dictFromInputList(opts.payload.pubInputs);

    opts.gasLog.rememberBocSize(opts.gasName, verifier.init?.code!);

    const deployResult = await verifier.send(
        deployer.getSender(),
        {
            value: toTonValue(opts.deployValue, '0.05'),
        },
        null,
    );
    expect(deployResult.transactions).toHaveTransaction({
        from: deployer.address,
        to: verifier.address,
        deploy: true,
        success: true,
    });
    opts.gasLog.rememberGas('Deploy', deployResult.transactions.slice(1));

    expect(
        await verifier.getVerify(
            beginCell().storeBuffer(opts.payload.pi_a).endCell().asSlice(),
            beginCell().storeBuffer(opts.payload.pi_b).endCell().asSlice(),
            beginCell().storeBuffer(opts.payload.pi_c).endCell().asSlice(),
            pubInputsDict,
        ),
    ).toBe(true);

    const verifyResult = await verifier.send(
        deployer.getSender(),
        {
            value: toTonValue(opts.verifyValue, '0.05'),
        },
        {
            $$type: 'Verify',
            piA: beginCell().storeBuffer(opts.payload.pi_a).endCell(),
            piB: beginCell().storeBuffer(opts.payload.pi_b).endCell(),
            piC: beginCell().storeBuffer(opts.payload.pi_c).endCell(),
            pubInputs: pubInputsDict,
        },
    );
    expect(verifyResult.transactions).toHaveTransaction({
        from: deployer.address,
        to: verifier.address,
        success: true,
    });
    opts.gasLog.rememberGas('Verify', verifyResult.transactions.slice(1));
}

export function describeFuncOrTolkVerifier(opts: {
    name: string;
    Wrapper: FuncOrTolkWrapper;
    getPayload: () => Promise<Groth16Payload>;
    getMethodName?: string;
    deployValue?: TonValue;
    verifyValue?: TonValue;
}) {
    describe(opts.name, () => {
        const GAS_LOG = new GasLogAndSave(opts.name);

        afterAll(() => {
            GAS_LOG.saveCurrentRunAfterAll();
        });

        it('should verify', async () => {
            await runFuncOrTolkVerifierTest({
                compileName: opts.name,
                gasName: opts.name,
                Wrapper: opts.Wrapper,
                gasLog: GAS_LOG,
                payload: await opts.getPayload(),
                getMethodName: opts.getMethodName,
                deployValue: opts.deployValue,
                verifyValue: opts.verifyValue,
            });
        });
    });
}

export function describeTactVerifier(opts: {
    name: string;
    Contract: TactWrapper;
    getPayload: () => Promise<Groth16Payload>;
    deployValue?: TonValue;
    verifyValue?: TonValue;
}) {
    describe(opts.name, () => {
        const GAS_LOG = new GasLogAndSave(opts.name);

        afterAll(() => {
            GAS_LOG.saveCurrentRunAfterAll();
        });

        it('should verify', async () => {
            await runTactVerifierTest({
                gasName: opts.name,
                Contract: opts.Contract,
                gasLog: GAS_LOG,
                payload: await opts.getPayload(),
                deployValue: opts.deployValue,
                verifyValue: opts.verifyValue,
            });
        });
    });
}
