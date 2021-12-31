import { loadStdlib } from "@reach-sh/stdlib";
import * as backend from "./build/index.main.mjs";

(async () => {
  // essentially connects to the consensus network
  const stdlib = await loadStdlib();

  const showBalance = async (who, acc) => {
    console.log(who, stdlib.formatCurrency(await stdlib.balanceOf(acc)))
  };

  const accAlice = await stdlib.newTestAccount(stdlib.parseCurrency(5));
  const accBob = await stdlib.newTestAccount(stdlib.parseCurrency(10));

  // uploads to consensus network and return a handle
  const contractAlice = await accAlice.contract(backend); // address of deployment and metadata, no secure info
  const contractBob = await accBob.contract(backend, contractAlice.getInfo()); // verifies bytecode matches expected


  await showBalance('Alice - before', accAlice);
  await showBalance('Bob - before', accBob);

  await Promise.all([
    backend.Alice(contractAlice, {
      // alice's interaction object
      requestFunds: stdlib.parseCurrency(3),
      info: "fruit cookie recipe"
    }),
    backend.Bob(contractBob, {
      // bob's interaction object
      approve: (amt) => {
        console.log(`Alice is asking me, Bob, for ${stdlib.formatCurrency(amt)} in exchange for her recipe.`)
        // ideally we would prompt bob to accept
        console.log('I, Bob, approve')
      },
      got: (info) => {
        console.log(`Alice's recipe is: ${info}`)
      }
    })
  ]);

  await showBalance('Alice - after', accAlice);
  await showBalance('Bob - after', accBob);
})();