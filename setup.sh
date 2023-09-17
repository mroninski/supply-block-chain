# Ask for the github userid
# echo "What is your github userid?"
# read github_userid

# Go into the home directory for the golang setup
# mkdir -p $HOME/go/src/github.com/$github_userid
# cd $HOME/go/src/github.com/github_userid

# Install the scripts
curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh && chmod +x install-fabric.sh

# Install the fabric docker samples
./install-fabric.sh docker samples binary