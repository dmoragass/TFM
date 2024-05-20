// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StealthAddressModel.sol";

contract PagoSalarios {
    // Se crea una instancia del contrato DemoStealthAddresses.
    DemoStealthAddresses public stealth = new DemoStealthAddresses();

    // Variables
    // Dirección que publica el contrato.
    address public owner;
    // Lista de direcciones de empleados.
    address[] addresses;
    // Suma total de los salarios.
    uint256 totalSalarios;

    // Data structures
    // Estructura que almacena claves de empleados.
    struct Claves {
        // Clave privada.
        uint256 privateKey;
        // Coordenada X de la clave pública.
        uint256 publicKeyX;
        // Coordenada Y de la clave pública.
        uint256 publicKeyY;
    }

    // Estructura que almacena información sobre las stealth addresses de los empleados.
    struct StealthAddressInfo {
        // Clave efímera privada.
        uint256 ephPrivateKey;
        // Coordenada X de la clave efímera pública.
        uint256 ephPublicKeyX;
        // Coordenada Y de la clave efímera pública.
        uint256 ephPublicKeyY;
        // Stealth address.
        address stealthAddress;
        // View tag de la stealth address.
        uint256 viewTag;
        // Hash de la stealth address.
        bytes32 hash;
    }

    // Mapping
    // Mapa que relaciona las direcciones de los empleados con sus salarios.
    mapping (address => uint256) salarios;
    // Mapa que relaciona las direcciones de los empleados con sus claves.
    mapping (address => Claves) claves;
    // Mapa que relaciona las direcciones de los empleados con sus stealth addresses.
    mapping (address => StealthAddressInfo) stealthAddresses;

    // Constructor
    // Se establece que quien crea el contrato es el owner.
    constructor() {
        owner = msg.sender;
    }

    // Modifiers
    // Se crea el modificador para que las funciones que lo incorporen solo puedan
    // ser ejecutadas por el poseedor del contrato.
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    // Functions
    // Función que da de alta un empleado.
    // @param empleado: Dirección de un empleado.
    // @param salario: Salario del empleado en ETH.
    function dar_alta_empleado(address empleado, uint256 salario) public onlyOwner{
        // Si el empleado tiene un salario distinto a 0 significará que ya está dado de alta,
        // por lo que no se dará de alta de nuevo.
        require(salarios[empleado] == 0, "ERROR: Empleado registrado anteriormente.");
        // Si el salario del empleado no es mayor que 0 no se le dará de alta.
        require(salario > 0, "ERROR: Salario no valido.");
        // Se añade la dirección del empleado a la lista de empleados.
        addresses.push(empleado);
        // Se añade el salario del empleado al total de salarios.
        totalSalarios += salario;
        // Se añade el empleado al mapa de salarios.
        salarios[empleado] = salario;
    }

    // Función que genera las claves del empleado que la llama y se las muestra.
    // @return claves[msg.sender].privateKey: Clave privada.
    // @return claves[msg.sender].publicKeyX: Coordenada X de la clave pública.
    // @return claves[msg.sender].publicKeyY: Coordenada Y de la clave pública.
    function generar_claves() public returns(uint256 clavePrivada, uint256 clavePublicaX, uint256 clavePublicaY){
        // Si el llamante de la función tiene un salario igual a 0, entonces no existe.
        require(salarios[msg.sender] != 0, "ERROR: Empleado no existe.");
        // Si la clave privada del llamante de la función no es igual a 0, entonces las
        // claves ya fueron generadas anteriormente.
        require(claves[msg.sender].privateKey == 0, "ERROR: Claves generadas anteriormente.");
        // Se genera y se guarda en el mapa de claves la clave privada.
        claves[msg.sender].privateKey = stealth.generate_random_private_key();
        // Se genera y se guarda en el mapa de claves la clave pública.
        (claves[msg.sender].publicKeyX, claves[msg.sender].publicKeyY) = stealth.generate_public_key(claves[msg.sender].privateKey);
        // Se devuelven la clave privada y la clave pública generadas para el empleado.
        return (claves[msg.sender].privateKey, claves[msg.sender].publicKeyX, claves[msg.sender].publicKeyY);
    }

    // Función que consulta las claves del empleado que la llama.
    // @return claves[msg.sender].privateKey: Clave privada.
    // @return claves[msg.sender].publicKeyX: Coordenada X de la clave pública.
    // @return claves[msg.sender].publicKeyY: Coordenada Y de la clave pública.
    function consultar_claves() public view returns(uint256 clavePrivada, uint256 clavePublicaX, uint256 clavePublicaY){
        // Si el llamante de la función tiene un salario igual a 0, entonces no existe.
        require(salarios[msg.sender] != 0, "ERROR: Empleado no existe.");
        // Si la clave privada del llamante de la función es igual a 0, entonces las
        // claves no existen.
        require(claves[msg.sender].privateKey != 0, "ERROR: Claves no existen.");
        // Se devuelven la clave privada y la clave pública del empleado.
        return (claves[msg.sender].privateKey, claves[msg.sender].publicKeyX, claves[msg.sender].publicKeyY);
    }

    // Función que devuelve el total de los salarios en ETH.
    // @return totalSalarios: Total de los salarios.
    function consultar_total_salarios() public onlyOwner view returns(uint256){
        // Se devuelve el total de los salarios.
        return totalSalarios;
    }

    // Función que genera una stealth address y paga el salario a todos los empleados
    function generar_stealth_address_y_pagar_salarios() public payable onlyOwner {
        // Si la cantidad de ETH introducida no se corresponde con el total de salarios,
        // entonces no se procede.
        require(msg.value == totalSalarios*10**18, "Cantidad de ETH no valida.");
        // Bucle que recorre las direcciones de empleados para generar la información
        // necesaria para generar la stealth address de cada uno de ellos, y después
        // realizar el pago de su salario.
        for(uint i = 0; i < addresses.length; i++) {
            // Se genera y almacena la clave efímera privada.
            stealthAddresses[addresses[i]].ephPrivateKey = stealth.generate_random_private_key();
            // Se genera y almacena la clave efímera pública.
            (stealthAddresses[addresses[i]].ephPublicKeyX, stealthAddresses[addresses[i]].ephPublicKeyY) = stealth.generate_public_key(stealthAddresses[addresses[i]].ephPrivateKey);
            // Se generan y almacenan la stealth address y la view tag.
            (stealthAddresses[addresses[i]].stealthAddress, stealthAddresses[addresses[i]].viewTag) = stealth.generate_stealth_address(stealthAddresses[addresses[i]].ephPrivateKey, claves[addresses[i]].publicKeyX, claves[addresses[i]].publicKeyY);
            // Se genera y almacena el hash de la clave privada de la stealth address.
            stealthAddresses[addresses[i]].hash = stealth.retrieve_hash(claves[addresses[i]].privateKey, stealthAddresses[addresses[i]].ephPublicKeyX, stealthAddresses[addresses[i]].ephPublicKeyY);
            // Se realiza la transferencia del salario a la stealth address generada.
            payable(stealthAddresses[addresses[i]].stealthAddress).transfer(salarios[addresses[i]]*10**18);
        }
    }

    // Función que genera una stealth address y paga el salario a un empleado
    // @param empleado: Dirección del empleado.
    function single_generar_stealth_address_y_pagar_salarios(address empleado) public payable onlyOwner {
        // Si la cantidad de ETH introducida no se corresponde con el salario del empleado,
        // entonces no se procede.
        require(msg.value == salarios[empleado]*10**18, "Cantidad de ETH no valida.");
        // Se genera y almacena la clave efímera privada.
        stealthAddresses[empleado].ephPrivateKey = stealth.generate_random_private_key();
        // Se genera y almacena la clave efímera pública.
        (stealthAddresses[empleado].ephPublicKeyX, stealthAddresses[empleado].ephPublicKeyY) = stealth.generate_public_key(stealthAddresses[empleado].ephPrivateKey);
        // Se generan y almacenan la stealth address y la view tag.
        (stealthAddresses[empleado].stealthAddress, stealthAddresses[empleado].viewTag) = stealth.generate_stealth_address(stealthAddresses[empleado].ephPrivateKey, claves[empleado].publicKeyX, claves[empleado].publicKeyY);
        // Se genera y almacena el hash de la clave privada de la stealth address.
        stealthAddresses[empleado].hash = stealth.retrieve_hash(claves[empleado].privateKey, stealthAddresses[empleado].ephPublicKeyX, stealthAddresses[empleado].ephPublicKeyY);
        // Se realiza la transferencia del salario a la stealth address generada.
        payable(stealthAddresses[empleado].stealthAddress).transfer(salarios[empleado]*10**18);
    }

    // Función que consulta la última stealth addresses del empleado que la llama.
    // @return stealthAddresses[msg.sender].stealthAddress: Stealth address del empleado.
    // @return stealthAddresses[msg.sender].hash: Hash de la clave privada de la stealth address del empleado.
    function consultar_stealth_address() public view returns(address stealthAddress, bytes32 hash){
        // Si el llamante de la función tiene un salario igual a 0, entonces no existe.
        require(salarios[msg.sender] != 0, "ERROR: Empleado no existe.");
        // Si la stealth addres del llamante de la función
        // es igual a 0x0000000000000000000000000000000000000000, entonces no existe.
        require(stealthAddresses[msg.sender].stealthAddress != 0x0000000000000000000000000000000000000000, "ERROR: Stealth Address no existe.");
        // Se devuelven la stealth address y el hash de su clave privada.
        return (stealthAddresses[msg.sender].stealthAddress, stealthAddresses[msg.sender].hash);
    }

    // Función que consulta el balance en wei de una dirección.
    // @param direccion: Dirección.
    // @return direccion.balance: Cantidad de wei de la dirección.
    function check_balance(address direccion) public view returns(uint256){
        // Se devuelve la cantidad de wei de la dirección.
        return direccion.balance;
    }        
}