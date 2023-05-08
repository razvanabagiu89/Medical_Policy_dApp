
## steps

0. source "/mnt/c/Users/Lenovo Legion Y530/Desktop/Medical_Policy_dApp/app/myenv/bin/activate"

0.1
npm install ganache

1. start local blockchain
ganache --db ./my_chain -p 8545 -d

2. start docker with mongo-db
sudo service docker start
docker start test-mongo

3. deploy contract if not deployed already
python3 scripts/deploy.py
or
./reset_app.sh to reset db too

4. export PYTHONPATH="$PWD"

5. python3 app.py


#### obs:
- blockchain:
  
    when adding a patient:
    - patientID will be generated unique
    - his address must be unique. why? because of policy creation

each patient is uniquely identified by his ID - correlated in the db too
each policy is uniquely identified by its wallet
each wallet is unique in patient's wallet list


- db:
each patient is uniquely identified by his ID (random)
each wallet is unique in patient's wallet list
each institution is uniquely identified by his CIF (input)

#### todo:
- password hash in db
- more utils funcs
- duplicate checks for creations, adding etc. - involve http request from frontend to backend


minor:
- only access from fe (cors)
- if db fails dont move to blockchain steps and reverse too
- review all variables and functions names to be consistent across:
    - db
    - blockchain
    - backend
    - testing
    - frontend
