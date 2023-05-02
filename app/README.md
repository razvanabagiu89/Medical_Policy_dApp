
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
- parse app config in flutter for contract addresses
- more utils funcs
- remove medical record
- add wallet (+ add policy inside - 2 tx's)
- duplicate checks for creations, adding etc. - involve http request from frontend to backend
- involve S3 for MR:
  - doctor access patient's MR from his access_to list and sends request to backend which will check
with the blockchain if the patient has granted access to the doctor
  - if yes, the backend will send the MR to the doctor streamlined as PDF in flutter
  - if not, the backend will send a message to the doctor that he has no access to the MR

- the institution will have an admin account which will be able to add doctors to the institution (later)
- Ministry of Health will do the same and add institutions (later)


minor:
- if db fails dont move to blockchain steps and reverse too
- review all variables and functions names to be consistent across:
    - db
    - blockchain
    - backend
    - testing
    - frontend
