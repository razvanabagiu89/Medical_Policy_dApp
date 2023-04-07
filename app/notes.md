0. source "/mnt/c/Users/Lenovo Legion Y530/Desktop/Medical_Policy_dApp/app/myenv/bin/activate"

1. start local blockchain
ganache-cli --db ./my_chain -p 8545 -d

2. start docker with mongo-db

3. deploy contract if not deployed already -> scripts/deploy.py

4. flask run

5. export PYTHONPATH="$PWD"

6. pytest
