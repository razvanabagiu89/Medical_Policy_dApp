from web3 import Web3
from scripts.utils import *
import yaml

web3 = Web3(Web3.HTTPProvider(web3_host))
patient_registry_contract_address = deploy(web3, "PatientRegistryContract")
access_policy_contract_address = deploy(web3, "AccessPolicyContract")
institution_registry_contract_address = deploy(web3, "InstitutionRegistryContract")

yaml_data = load_yaml_file("app_config.yaml")
yaml_data["web3"]["patient_registry_contract_address"] = str(
    patient_registry_contract_address
)
yaml_data["web3"]["access_policy_contract_address"] = str(
    access_policy_contract_address
)
yaml_data["web3"]["institution_registry_contract_address"] = str(
    institution_registry_contract_address
)

with open("app_config.yaml", "w") as file:
    yaml.safe_dump(yaml_data, file, default_flow_style=False)
