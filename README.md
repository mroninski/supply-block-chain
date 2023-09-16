# supply-block-chain

# Explanation
  - Oracle architecture proposed in the following article was implemented in Hyperledger Fabric 2.5
  - Option implemented is number 2, Introducing a trusted oracle:
    - https://developer.ibm.com/articles/cl-extend-blockchain-smart-contracts-trusted-oracle/
  - Data Call to an external source is made from inside the smart contract (aka chaincode)

#  Download Fabric samples, Docker images, and binaries
  - Further instructions can be found here:
    - https://hyperledger-fabric.readthedocs.io/en/latest/install.html
    - mkdir -p $HOME/go/src/github.com/<your_github_userid>
    - cd $HOME/go/src/github.com/<your_github_userid>
  - Install the script
    - curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/bootstrap.sh| bash -s
  - Pull docker containers 
    - ./install-fabric.sh docker samples binary
  - Bring up the test/network
    - cd fabric-samples/test-network
    - ./network.sh down
    - ./network.sh up
  - Create channel
    - ./network.sh createChannel
  - Further instructions can be found here:
    - https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html

# Running a fabric application
  - asset-transfer-basic/application-gateway-typescript
  - ./network.sh up createChannel -c mychannel -ca
    - we bring up the test network using certificate authorities, hence the -ca flag
# Deploy the contract (from test/network)
  - ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-typescript/ -ccl typescript
# Open a new terminal 
  - cd asset-transfer-basic/application-gateway-typescript
  - npm install
  - npm start
  - further instructions here:
    - https://hyperledger-fabric.readthedocs.io/en/latest/write_first_app.html
# Changes made
  - asset-transfer-basic/application-gateway-typescript/src/app.ts

    ```typescript
    async function main(): Promise<void> {

      await displayInputParameters();
  
      // The gRPC client connection should be shared by all Gateway connections to this endpoint.
      const client = await newGrpcConnection();
  
      ...
      // Call the oracle
          await transactionProposal(contract);
  
      ...
    }
    ...
   
    async function transactionProposal(contract: Contract): Promise<void> {
      console.log('\n--> Async Submit Transaction: transactionProposal, updates existing asset AppraisedValue');

      const commit = await contract.submitAsync('InvokeOracle', {
          arguments: [assetId],
      });
      const newLatitude = utf8Decoder.decode(commit.getResult());

        console.log(`*** Successfully submitted transaction to change Coordinates ${newLatitude} to Saptha`);
        console.log('*** Waiting for transaction commit');
    
        const status = await commit.getStatus();
        if (!status.successful) {
            throw new Error(`Transaction ${status.transactionId} failed to commit with status code ${status.code}`);
        }
    
        console.log('*** Transaction committed successfully');
    }
    ...
    
    await getAllAssets(contract);

    ...

    ```
  - asset-transfer-basic/chaincode-typescript/src/assetTransfer.ts
    ```typescript
    @Info({title: 'AssetTransfer', description: 'Smart contract for trading assets'})
    export class AssetTransferContract extends Contract {

      @Transaction()
      public async InitLedger(ctx: Context): Promise<void> {
          // coordinates key was added
          const assets: Asset[] = [
              {
                  ID: 'asset1',
                  Color: 'black',
                  Size: 15,
                  Owner: 'Adriana',
                  Coordinates: {latitude: -31.8129, longitude: 62.5342},
                  AppraisedValue: 700,
              },
              {
                  ID: 'asset2',
                  Color: 'white',
                  Size: 15,
                  Owner: 'Michel',
                  Coordinates: {latitude: -71.4197, longitude: 71.7478},
                  AppraisedValue: 800,
              },
          ];
  
          for (const asset of assets) {
              asset.docType = 'asset';
              // example of how to write to world state deterministically
              // use convetion of alphabetic order
              // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
              // when retrieving data, in any lang, the order of data will be the same and consequently also the corresonding hash
              await ctx.stub.putState(asset.ID, Buffer.from(stringify(sortKeysRecursive(asset))));
              console.info(`Asset ${asset.ID} initialized`);
          }
      }
    ...

    // TransferAsset updates the owner field of asset with given id in the world state, and returns the old owner.
    @Transaction()
    public async InvokeOracle(ctx: Context, id: string): Promise<string> {
        const assetString = await this.ReadAsset(ctx, id);
        const asset = JSON.parse(assetString);
        const oldCoordinates = asset.Coordinates;


        // Create a URL to the weather API.
        // const url = `https://forecast-v2.metoceanapi.com/point/time`;

        // this is an x site with some public data to be fetched in json format
        const url = `https://jsonplaceholder.typicode.com/users/10`;
        
        // Create a request to the weather API.
        const request = new Request(url);

        // Make the request to the weather API.
        const response = await fetch(request);

        // Check the status code of the response.
        if (response.status !== 200) {
            throw new Error('Error getting weather: ' + response.status);
        }

        // Get the weather data from the response body.
        const newCoordinates = await response.json();

        // Return the weather data.
        // writes new data 
        asset.Coordinates.longitude = +newCoordinates.address.geo.lng;
        asset.Coordinates.latitude = +newCoordinates.address.geo.lat;

        // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
        await ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(asset))));
        return oldCoordinates;
    }
    ```
