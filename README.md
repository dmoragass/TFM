# DemoStealthAddresses and PagoSalarios
DemoStealthAddresses is a smart contract that demonstrates the basic operation of stealth addresses. A user A can generate a stealth meta-address from his keys, and a user B can generate from the information contained in this stealth meta-address and his private key a stealth address, which he will publish. User B, using his keys, will search for and find the stealth addresses that correspond to him, and will be able to generate a private key for that address.


PagoSalarios is a smart contract which implements the stealth addresses technique in the context of a company that pays salaries to its workers. The company (contract owner) will register employees with their salaries, who must generate their keys so that the company can pay their salaries, either to all employees in the same execution or one at a time. Once the payment has been made, each employee will be able to consult the stealth address generated for the most recent payment along with their private key, as well as consult the previously generated keys and the balance of the address they enter.

A web interface has been generated for each of the contracts developed, in order to make the interaction with them more user-friendly.

## DemoStealthAddresses web interface
![image](https://github.com/dmoragass/TFM/assets/170375849/ea68c59d-0509-4bee-8004-01a9b8df5dc8)

## PagoSalarios web interface
![image](https://github.com/dmoragass/TFM/assets/170375849/2f2b78c9-d6bb-465b-8f50-177a288f01c9)

## Deployment

It is necessary to deploy a local blockchain. In this case it has been chosen `ganache-cli` in its Windows client version.

First of all, select `Quickstart (Ethereum)`.

![image](https://github.com/dmoragass/TFM/assets/170375849/326e0940-0f7d-438a-95b8-8d3968d6f7e5)

Once initialized, go to `Settings`.

![image](https://github.com/dmoragass/TFM/assets/170375849/72aebdcc-4e5f-408c-93b1-ae607a70eb61)

In the window named `Chain`, replace the `Gas limit` value. Use `672197500` instead of `6721975`, and then press the `Save and restart` button.

![image](https://github.com/dmoragass/TFM/assets/170375849/8217ca39-7e04-49d9-936f-bfafd75b7e6a)

Now, the main page shoud look like this. Check the highlighted values and make sure they are the same.

![image](https://github.com/dmoragass/TFM/assets/170375849/dd7d7903-01a4-4c23-bee2-c81d78316d2f)

Then, using `Visual Studio Code`, execute the `truffle migrate` command to compile and deploy the contracts.

Finally, in the `app` folder of the project you want to use, run the `npm install` command to install the necessary dependencies, and then run the `npm run dev` command in the app folder to launch the web application in question. Once launched, go to `http://localhost:8080/`.
