# Refresh network
fabric-samples/test-network/network.sh down
fabric-samples/test-network/network.sh up

# Initiate channel
fabric-samples/test-network/network.sh createChannel

# 
cd fabric-samples/asset-transfer-basic/rest-api-typescript
npm install
npm start