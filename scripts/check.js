const Lottery = artifacts.require("Lottery")

module.exports = async (callback) => {
    const lottery = await Lottery.deployed()
    const count = await lottery.lotteryCount()
    console.log(`Lotteries: ${count}`)
    const address = await lottery.address
    console.log(`address: ${address}`)
    const subscriptionId = await lottery.subscriptionId()
    console.log(`subscriptionId: ${subscriptionId}`)

    await lottery.createLottery("0xF722480FEEd1D5734C603efe9b70b2116Ec9a35b")
    const requestTx = await lottery.buyTickets(3, 3)
    //console.log(`Buy tickets: ${JSON.stringify(requestTx)}`);
    //const lotteryData = await lottery.lottery(1);

   // console.log(`Lottery2: ${JSON.stringify(lotteryData)}`);
   // const tickets = await lottery.getTickets(1);
    //console.log(`Tickets: ${tickets}`);
    //console.log(`Lottery3: ${lotteryData[2]}`);
  //  const lotteryStatus = await lottery.requests("68981790106067759361205946113036245723642953123676886947794515739946384395551");
   // console.log(`Lottery status: ${JSON.stringify(lotteryStatus)}`);
    const requestId = await lottery.drawLotteryWinner(3);
    console.log(`Request ID: ${requestId.toNumber()}`);
    console.log(`Request ID2: ${requestId}`);
    callback()
}
