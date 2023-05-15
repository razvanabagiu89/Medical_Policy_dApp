
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
