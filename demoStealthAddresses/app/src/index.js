// Importing necessary libraries and contracts for the DApp
import Web3 from "web3";
import demoStealthAddressesArtifact from "../../build/contracts/DemoStealthAddresses.json";

// Main App object containing all the functions and properties
const App = {
  web3: null, // Web3 instance
  demoStealthAddresses: null, // Smart contract instance
  account: null, // Current user account address

  // Initializes the application by setting up the web3 instance and contract
  start: async function () {
    const { web3 } = this;

    try {
      // Retrieve the network ID and initialize the contract
      const networkId = await web3.eth.net.getId();
      this.demoStealthAddresses = new web3.eth.Contract(
        demoStealthAddressesArtifact.abi,
        demoStealthAddressesArtifact.networks[networkId].address
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
    const { owner } = this.demoStealthAddresses.methods;
    document.getElementById("contractOwner").innerHTML = await owner().call();
    document.getElementById('contractAddress').innerText = this.demoStealthAddresses.options.address;
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

  demoPrivateKey: async function() {
    document.getElementById('democlavepriv').innerText = "";

    try {
      const gasPrice = await this.web3.eth.getGasPrice();
      const gasLimit = 672197500;

      const privKey = await this.demoStealthAddresses.methods.generate_random_private_key().call({
        from: this.account,
        gasPrice: gasPrice,
        gas: gasLimit
      });      

      if (privKey != 0) {
        document.getElementById('democlavepriv').innerText = "Clave privada: " + privKey;
      } else {
        document.getElementById('democlavepriv').innerText = "La clave no se ha podido generar.";
      }
    } catch (error) {
      this.showMessage("Transacción fallida: " + error.message, "error");
      console.error("Error generando la clave privada:", error);
    } 
  },

  demoPublicKey: async function() {
    document.getElementById('democlavepubX').innerText = "";
    document.getElementById('democlavepubY').innerText = "";

    const privateKey = document.getElementById('privKey').value;

    if (privateKey.trim() === '') {
      this.showMessage('Por favor, rellena todos los campos.', 'error');
      return;
    }

    try {
      const pubKey = await this.demoStealthAddresses.methods.generate_public_key(privateKey).call();      

      if (pubKey != 0) {
        document.getElementById('democlavepubX').innerText = "Clave pública X: " + pubKey[0];
        document.getElementById('democlavepubY').innerText = "Clave pública Y: " + pubKey[1];
      } else {
        document.getElementById('democlavepubX').innerText = "No se ha podido generar la clave pública";
        document.getElementById('democlavepubY').innerText = "";
      }
    } catch (error) {
      this.showMessage("Transacción fallida: " + error.message, "error");
      console.error("Error generando la clave pública:", error);
    }
  },

  demoStealthMetaAddress: async function() {
    document.getElementById('stMetaAdd').innerText = "";

    const publicKeyX = document.getElementById('metaAddX').value;
    const publicKeyY = document.getElementById('metaAddY').value;

    if (publicKeyX.trim() === '' || publicKeyY.trim() === '') {
      this.showMessage('Por favor, rellena todos los campos.', 'error');
      return;
    }

    try {
      const stMetaAddr = await this.demoStealthAddresses.methods.generate_stealth_meta_address(publicKeyX, publicKeyY).call();

      if (stMetaAddr != 0) {
        document.getElementById('stMetaAdd').innerText = "Stealth meta-address: " + stMetaAddr;
      } else {
        document.getElementById('stMetaAdd').innerText = "No ha podido generarse la stealth meta-address.";
      }
    } catch (error) {
      this.showMessage("Transacción fallida: " + error.message, "error");
      console.error("Error generando stealth meta-address:", error);
    }
  },

  demoUncompressStealthMetaAddress: async function() {
    document.getElementById('demometaclavepubX').innerText = "";
    document.getElementById('demometaclavepubY').innerText = "";

    const prefix = document.getElementById('prefix').value;
    const x = document.getElementById('demoX').value;

    if (prefix.trim() === '' || x.trim() === '') {
      this.showMessage('Por favor, rellena todos los campos.', 'error');
      return;
    }

    try {
      const pubKey = await this.demoStealthAddresses.methods.uncompress_stealth_meta_address(Number(prefix), Web3.utils.toNumber(x)).call();
     
      if (pubKey != 0) {
        document.getElementById('demometaclavepubX').innerText = "Clave pública X: " + pubKey[0];
        document.getElementById('demometaclavepubY').innerText = "Clave pública Y: " + pubKey[1];
      } else {
        document.getElementById('demometaclavepubX').innerText = "No se ha podido descomprimir la stealth meta-address.";
        document.getElementById('demometaclavepubY').innerText = "";
      }
    } catch (error) {
      this.showMessage("Transacción fallida: " + error.message, "error");
      console.error("Error descomprimiendo stealth meta-address:", error);
    }
  },

  demoGenerateStealthAddress: async function() {
    document.getElementById('demostealthaddress').innerText = "";
    document.getElementById('demoviewtag').innerText = "";

    const privateKey = document.getElementById('sapriv').value;
    const publicKeyX = document.getElementById('sapubX').value;
    const publicKeyY = document.getElementById('sapubY').value;    

    if (privateKey.trim() === '' || publicKeyX.trim() === '' || publicKeyY.trim() === '') {
      this.showMessage('Por favor, rellena todos los campos.', 'error');
      return;
    }

    try {
      const stAddr = await this.demoStealthAddresses.methods.generate_stealth_address(privateKey, publicKeyX, publicKeyY).call();

      if (stAddr != 0) {
        document.getElementById('demostealthaddress').innerText = "Stealth address: " + stAddr[0];
        document.getElementById('demoviewtag').innerText = "View tag: " + stAddr[1];
      } else {
        document.getElementById('demostealthaddress').innerText = "No se ha podido generar la stealth address.";
        document.getElementById('demoviewtag').innerText = "";
      }
    } catch (error) {
      this.showMessage("Transacción fallida: " + error.message, "error");
      console.error("Error generando stealth address:", error);
    }
  },

  demoRetrieveHash: async function() {
    document.getElementById('demohash').innerText = "";

    const privateKey = document.getElementById('hashpriv').value;
    const publicKeyX = document.getElementById('hashpubX').value;
    const publicKeyY = document.getElementById('hashpubY').value;    

    if (privateKey.trim() === '' || publicKeyX.trim() === '' || publicKeyY.trim() === '') {
      this.showMessage('Por favor, rellena todos los campos.', 'error');
      return;
    }

    try {
      const hash = await this.demoStealthAddresses.methods.retrieve_hash(privateKey, publicKeyX, publicKeyY).call();
      
      if (hash != 0) {
        document.getElementById('demohash').innerText = "Hash: " + hash;
      } else {
        document.getElementById('demohash').innerText = "No se ha podido obtener el hash.";
      }
    } catch (error) {
      this.showMessage("Transacción fallida: " + error.message, "error");
      console.error("Error obteniendo el hash:", error);
    }
  },

  demoRellenarRandom: async function() {
    document.getElementById('demorellenar').innerText = "";

    try {
      const gasPrice = await this.web3.eth.getGasPrice();
      const gasLimit = 672197500;

      const random = await this.demoStealthAddresses.methods.rellenar_random().send({
        from: this.account,
        gasPrice: gasPrice,
        gas: gasLimit
      });      

      if (random != 0) {
        document.getElementById('demorellenar').innerText = "Datos aleatorios añadidos.";
      } else {
        document.getElementById('demorellenar').innerText = "No se han podido añadir datos aleatorios.";
      }
    } catch (error) {
      this.showMessage("Transacción fallida: " + error.message, "error");
      console.error("Error añadiendo datos aleatorios:", error);
    }
  },

  demoRellenarEspecifico: async function() {
    document.getElementById('demorellenarb').innerText = "";

    const privateKey = document.getElementById('addpriv').value;
    const publicKeyX = document.getElementById('addpubX').value;
    const publicKeyY = document.getElementById('addpubY').value;
    const stealthAddress = document.getElementById('addsa').value;
    const viewTag = document.getElementById('addviewtag').value;    

    if (privateKey.trim() === '' || publicKeyX.trim() === '' || publicKeyY.trim() === '') {
      this.showMessage('Por favor, rellena todos los campos.', 'error');
      return;
    }

    try {
      const gasPrice = await this.web3.eth.getGasPrice();
      const gasLimit = 672197500;

      const data = await this.demoStealthAddresses.methods.rellenar_especifico(privateKey, publicKeyX, publicKeyY, stealthAddress, viewTag).send({
        from: this.account,
        gasPrice: gasPrice,
        gas: gasLimit
      });     

      if (data != 0) {
        document.getElementById('demorellenarb').innerText = "Datos añadidos.";
      } else {
        document.getElementById('demorellenarb').innerText = "No se han podido añadir los datos.";
      }
    } catch (error) {
      this.showMessage("Transacción fallida: " + error.message, "error");
      console.error("Error añadiendo los datos:", error);
    }
  },

  demoParse: async function() {
    document.getElementById('demoparse').innerText = "";
    document.getElementById('demoparseb').innerText = "";

    const privateKey = document.getElementById('parsepriv').value;
    const publicKeyX = document.getElementById('parsepubX').value;
    const publicKeyY = document.getElementById('parsepubY').value;

    try {
      const stAddr = await this.demoStealthAddresses.methods.parse(privateKey, publicKeyX, publicKeyY).call();

      if (stAddr[0].length != 0) {
        document.getElementById('demoparse').innerText = "Stealth addresses: " + stAddr[0];
        document.getElementById('demoparseb').innerText = "Hashes: " + stAddr[1];
      } else {
        document.getElementById('demoparse').innerText = "No se han encontrado stealth addresses.";
        document.getElementById('demoparseb').innerText = "";
      }
    } catch (error) {
      this.showMessage("Transacción fallida: " + error.message, "error");
      console.error("Error recuperando las stealth addresses y sus hashes:", error);
    }
  },

  demoPrivStA: async function() {
    document.getElementById('demoret').innerText = "";

    const privateKey = document.getElementById('retpriv').value;
    const hash = document.getElementById('rethash').value;    

    if (privateKey.trim() === '' || hash.trim() === '') {
      this.showMessage('Por favor, rellena todos los campos.', 'error');
      return;
    }

    try {
      const privKey = await this.demoStealthAddresses.methods.retrieve_stealth_address_priv_key(privateKey, hash).call();

      if (privKey != 0) {
        document.getElementById('demoret').innerText = "Clave privada: " + privKey;
      } else {
        document.getElementById('demoret').innerText = "No se ha podido generar la clave privada.";
      }
    } catch (error) {
      this.showMessage("Transacción fallida: " + error.message, "error");
      console.error("Error generando la clave privada:", error);
    }
  },
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
