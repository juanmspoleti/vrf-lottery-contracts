const Lottery = artifacts.require("Lottery")
const { developmentChains } = require("../helper-truffle-config")

module.exports = async function (deployer, network) {
    await deployer.deploy(Lottery, process.env.SUBSCRIPTION_ID)
}
