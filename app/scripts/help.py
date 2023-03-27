from solcx import compile_source


def get_contract(web3, contract_name, contract_address):
    code = web3.eth.get_code(contract_address)

    if code.hex() == "0x":
        print(f"Contract not found at address {contract_address}")
        exit()
    else:
        print(f"Contract found at address {contract_address}")
        with open(f"contracts/{contract_name}.sol", "r") as file:
            source_code = file.read()
        compiled_contract = compile_source(
            source=source_code,
            output_values=["abi", "bin"],
            solc_version="0.8.0",
        )
        contract_interface = compiled_contract[f"<stdin>:{contract_name}"]
        abi = contract_interface["abi"]
        contract = web3.eth.contract(address=contract_address, abi=abi)

        return contract
