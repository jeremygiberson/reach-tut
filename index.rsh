'reach 0.1';

export const main = Reach.App(() => {
  const Alice = Participant('Alice', {
    // Specify Alice's interact interface here
    requestFunds: UInt,
    info: Bytes(42)
  });
  const Bob   = Participant('Bob', {
    // Specify Bob's interact interface here
    approve: Fun([UInt], Null),
    got: Fun([Bytes(42)], Null)
  });
  deploy(); // https://github.com/reach-sh/reach-lang/issues/474
  // write your program here

  Alice.only(() => {
    const amount = declassify(interact.requestFunds);
    // Note: this was just a demo to show how a constraint can be enforced, but amount < 100 isn't practical
    //  as depending on network, coin value ratio fluctuates, so `5` currency may be > 100 by many orders.
    //  so we comment this out when we actually `reach run` the program
    // assume(amount < 100);
  });

  // from the Lang perspective, publish is essentially making "amount" available to the App scope.
  // ie, App Scope = consensus network known state
  Alice.publish(amount); // when we publish, perspective shifts to the consensus network, and we can write constraints about what should be true
  //require(amount < 100);
  commit(); // back to perspective where any participant can do something

  Bob.only(() => {
    interact.approve(amount)
  });
  Bob.pay(amount); // like publish, but there's no additional info that needs to be added(published) to the consensus network
  commit();
  // note, that pay is putting the payment into escrow, if we exit'd here, we'd breach the ZeroBalance (of escrow) assertion
  // instead, we need to make sure that funds are transferred from escrow, to alice
  // What if the contract wants to explicitly keep funds for later use? Can the contract be referenced as a participant?
  //  "later" is essentialy a program path, and all paths are defined in this App scope. What ever the end operation you want to perform "later"
  //  would end up defined in a participant block.

  Alice.only(() => {
     const info = declassify(interact.info);
  });
  Alice.publish(info);
  // we move funds out of escrow and to a participant
  transfer(amount).to(Alice);
  // what if there was an error/typo in the program, and we end up trying to move the wrong amount?
  //   ie: transfer(amount + 1).to(Alice);
  //   reach checks for this explicitly by validating theorem "balance sufficient for transfer"
  //   compile results with: Verification failed: msg: "balance sufficient for transfer"
  commit();

  Bob.only(() => {
    interact.got(info);
  });

});