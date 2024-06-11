// Importing necessary libraries and contracts for the DApp
import Web3 from "web3";
import pagoSalariosArtifact from "../../build/contracts/pagoSalarios.json";


// Main App object containing all the functions and properties
const App = {
  web3: null, // Web3 instance
  pagoSalarios: null, // Smart contract instance
  account: null, // Current user account address

  // Initializes the application by setting up the web3 instance and contract
  start: async function () {
    const { web3 } = this;

    try {
      // Retrieve the network ID and initialize the contract
      const networkId = await web3.eth.net.getId();
      this.pagoSalarios = new web3.eth.Contract(
        pagoSalariosArtifact.abi,
        pagoSalariosArtifact.networks[networkId].address
      );

      // Retrieve the list of accounts and set the current account
      const accounts = await web3.eth.getAccounts();
      this.account = accounts[0]; // Modificar para cambiar de cuenta

    } catch (error) {
      this.showMessage("Could not connect to contract or chain", "error");
      console.error("Could not connect to contract or chain");
    }
  },

  // Displays a message in the DApp's UI
  showMessage: function (message, type = "info") {
    const messageBox = document.getElementById('messageBox');
    const messageElement = document.createElement('div');
    messageElement.classList.add('message', type);

    const messageText = document.createElement('span');
    messageText.innerText = message;
    messageElement.appendChild(messageText);

    // Add a delete button to the message
    const deleteButton = document.createElement('button');
    deleteButton.innerText = 'X';
    deleteButton.classList.add('delete-button');
    deleteButton.onclick = function () {
      messageBox.removeChild(messageElement);
    };
    messageElement.appendChild(deleteButton);

    messageBox.appendChild(messageElement);
  },

  // Retrieves and displays contract information in the UI
  getContractInfo: async function () {
    const { owner } = this.pagoSalarios.methods;
    document.getElementById("contractOwner").innerHTML = await owner().call();
    document.getElementById('contractAddress').innerText = this.pagoSalarios.options.address;
  },

  // Retrieves and displays account information in the UI
  getAccountInfo: async function () {
    const balanceWei = await this.web3.eth.getBalance(this.account);
    const balanceEth = this.web3.utils.fromWei(balanceWei, 'ether');

    document.getElementById('accountAddress').innerText = this.account;
    document.getElementById('accountBalance').innerText = balanceEth;
  },

  // Handles connecting to MetaMask
  connectMetaMask: async function () {
    if (typeof window.ethereum !== 'undefined') {
      try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        App.account = accounts[0];
        App.getAccountInfo();
        this.showMessage("Account connected successfully", "success")
      } catch (error) {
        if (error.code === 4001) {
          this.showMessage("Please connect to MetaMask.", "error")
        } else {
          this.showMessage(error, "error")
        }
      }
    }
  },

  altaEmpleado: async function () {
    document.getElementById('alta').innerText = "";

    const direccion = document.getElementById('direccion').value;
    const salario = document.getElementById('salario').value;

    if (direccion.trim() === '' || salario.trim() === '') {
      this.showMessage('Por favor, rellena todos los campos.', 'error');
      return;
    }

    if(this.web3.utils.isAddress(direccion)) {
      try {
        const gasPrice = await this.web3.eth.getGasPrice();
        const gasLimit = 672197500;

        await this.pagoSalarios.methods.dar_alta_empleado(direccion, salario).send({
          from: this.account,
          gasPrice: gasPrice,
          gas: gasLimit
        })
          .on('transactionHash', function(hash){
            console.log(`Transaction hash: ${hash}`);
            App.showMessage('Transacción enviada. Esperando confirmación...');
          })
          .on('receipt', function(receipt){
            console.log(receipt);
            App.showMessage('¡Transacción confirmada!', 'success');
            document.getElementById('alta').innerText = "Empleado dado de alta correctamente.";
          });
          
      } catch (error) {
          this.showMessage("Transacción fallida: " + error.message, "error");
          console.error("Error en la transacción:", error);
        }
    }
    else {
      alert('Dirección Ethereum inválida.');
    }
  },

  getSalarios: async function() {
    document.getElementById('totalSalarios').innerText = "";

    try {
      const gasPrice = await this.web3.eth.getGasPrice();
      const gasLimit = 672197500;

      const salarios = await this.pagoSalarios.methods.consultar_total_salarios().call({
        from: this.account,
        gasPrice: gasPrice,
        gas: gasLimit
      });
      
      document.getElementById('totalSalarios').innerText = salarios;
    } catch (error) {
      this.showMessage("Transacción fallida: " + error.message, "error");
      console.error("Error obteniendo el total de salarios:", error);
    }
  },

  generarClaves: async function() {
    document.getElementById('claves').innerText = "";

    try {
      const gasPrice = await this.web3.eth.getGasPrice();
      const gasLimit = 672197500;

      await this.pagoSalarios.methods.generar_claves().send({
        from: this.account,
        gasPrice: gasPrice,
        gas: gasLimit
      })
      .on('transactionHash', function(hash){
        console.log(`Transaction hash: ${hash}`);
        App.showMessage('Transacción enviada. Esperando confirmación...');
      })
      .on('receipt', function(receipt){
        console.log(receipt);
        App.showMessage('¡Transacción confirmada!', 'success');
        document.getElementById('claves').innerText = "Claves generadas correctamente.";
      });

    } catch (error) {
      this.showMessage("Transacción fallida: " + error.message, "error");
      console.error("Error generando las claves:", error);
    }
  },

  consultarClaves: async function() {
    document.getElementById('clavePrivada').innerText = "";
    document.getElementById('clavePublicaX').innerText = "";
    document.getElementById('clavePublicaY').innerText = "";

    try {
      const gasPrice = await this.web3.eth.getGasPrice();
      const gasLimit = 672197500;

      const clave = await this.pagoSalarios.methods.consultar_claves().call({
        from: this.account,
        gasPrice: gasPrice,
        gas: gasLimit
      });
      
      document.getElementById('clavePrivada').innerText = "Clave privada: "+ clave.clavePrivada;
      document.getElementById('clavePublicaX').innerText = "Clave pública (X): "+ clave.clavePublicaX;
      document.getElementById('clavePublicaY').innerText = "Clave pública (Y): "+ clave.clavePublicaY;

    } catch (error) {
      this.showMessage("Transacción fallida: " + error.message, "error");
      console.error("Error recuperando las claves:", error);
    }
  },

  generarStealth: async function () {
    document.getElementById('genStealth').innerText = "";

    try {
      const gasPrice = await this.web3.eth.getGasPrice();
      const gasLimit = 672197500;
      const price = await this.pagoSalarios.methods.consultar_total_salarios().call({
        from: this.account,
        gasPrice: gasPrice,
        gas: gasLimit
      });

      await this.pagoSalarios.methods.generar_stealth_address_y_pagar_salarios().send({
        from: this.account,
        gasPrice: gasPrice,
        gas: gasLimit,
        value: price*1000000000000000000n
      })
        .on('transactionHash', function(hash){
          console.log(`Transaction hash: ${hash}`);
          App.showMessage('Transacción enviada. Esperando confirmación...');
        })
        .on('receipt', function(receipt){
          console.log(receipt);
          App.showMessage('¡Transacción confirmada!', 'success');
          document.getElementById('genStealth').innerText = "Stealth address generada y pago realizado.";
        });
    } catch (error) {
        this.showMessage("Transacción fallida: " + error.message, "error");
        console.error("Error en la transacción:", error);
    }
  },

  generarStealthUnique: async function () {
    document.getElementById('genStealthUnique').innerText = "";

    const direccion = document.getElementById('empleado').value;
    const cantidad = document.getElementById('cantidad').value;

    if (direccion.trim() === '' || cantidad.trim() === '') {
      this.showMessage('Por favor, rellena todos los campos.', 'error');
      return;
    }
    if(this.web3.utils.isAddress(direccion)) {
      try {
        const gasPrice = await this.web3.eth.getGasPrice();
        const gasLimit = 672197500;
        await this.pagoSalarios.methods.single_generar_stealth_address_y_pagar_salarios(direccion).send({
          from: this.account,
          gasPrice: gasPrice,
          gas: gasLimit,
          value: cantidad*1000000000000000000
        })
          .on('transactionHash', function(hash){
            console.log(`Transaction hash: ${hash}`);
            App.showMessage('Transacción enviada. Esperando confirmación...');
          })
          .on('receipt', function(receipt){
            console.log(receipt);
            App.showMessage('¡Transacción confirmada!', 'success');
            document.getElementById('genStealthUnique').innerText = "Stealth address generada y pago realizado.";
          });
      } catch (error) {
          this.showMessage("Transacción fallida: " + error.message, "error");
          console.error("Error en la transacción:", error);
      }

    } else {
      alert('Dirección Ethereum inválida.');
    }
  },

  consultarStealth: async function() {
    document.getElementById('stealthConsultaHash').innerText = "";

    try {
      const gasPrice = await this.web3.eth.getGasPrice();
      const gasLimit = 672197500;

      const stealth = await this.pagoSalarios.methods.consultar_stealth_address().call({
        from: this.account,
        gasPrice: gasPrice,
        gas: gasLimit
      });
      
      document.getElementById('stealthConsultaHash').innerText = "Hash: " + stealth.hash;
      document.getElementById('stealthConsultaDir').innerText = "Stealth Address: " + stealth.stealthAddress;

    } catch (error) {
      this.showMessage("Transacción fallida: " + error.message, "error");
      console.error("Error buscando la stealth address:", error);
    }
  },

  consultarBalance: async function() {
    document.getElementById('balance').innerText = "";

    const direccion = document.getElementById('stealthEmpleado').value;

    if (direccion.trim() === '') {
      this.showMessage('Por favor, rellena todos los campos.', 'error');
      return;
    }
    if(this.web3.utils.isAddress(direccion)) {
      try {
        const gasPrice = await this.web3.eth.getGasPrice();
        const gasLimit = 672197500;

        const bal = await this.pagoSalarios.methods.check_balance(direccion).call({
          from: this.account,
          gasPrice: gasPrice,
          gas: gasLimit
        });
      
        document.getElementById('balance').innerText = bal + " wei.";

      } catch (error) {
        this.showMessage("Transacción fallida: " + error.message, "error");
        console.error("Error obteniendo el balance:", error);
      }

    } else {
        alert('Dirección Ethereum inválida.');
      }
  }
};

// Initialize the application and set up event listeners
window.App = App;
window.addEventListener("load", async function () {
  // Check for Ethereum provider and initialize web3
  App.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:7545"));

  // Check if there are already connected accounts
  if (window.ethereum) {
    try {
      const accounts = await window.ethereum.request({ method: 'eth_accounts' });
      if (accounts.length > 0) {
        App.account = accounts[0];
        App.getAccountInfo();
      }
    } catch (error) {
      console.error('Could not get accounts', error);
    }
  }

  // Start the application
  App.start();
});

// Listen for account changes in MetaMask
window.ethereum.on('accountsChanged', function (accounts) {
  App.account = accounts[0];
  App.getAccountInfo();
  App.showMessage('Changed account to: ' + accounts[0]);
});
