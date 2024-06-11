// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import "./EllipticCurve.sol";
// import "https://github.com/witnet/elliptic-curve-solidity/blob/master/contracts/EllipticCurve.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "./EllipticCurve.sol";
import "./Strings.sol";

contract DemoStealthAddresses {

    // Variables

    // Coordenada X del punto generador G de la curva elíptica.
    uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    // Coordenada Y del punto generador G de la curva elíptica.
    uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    // Coeficiente A de la ecuación de la curva elíptica y^2 = x^3 + AA*x + BB*y^2 mod PP.
    uint256 public constant AA = 0;
    // Coeficiente B de la ecuación de la curva elíptica y^2 = x^3 + AA*x + BB*y^2 mod PP.
    uint256 public constant BB = 7;
    // Coeficiente P de la ecuación de la curva elíptica y^2 = x^3 + AA*x + BB*y^2 mod PP.
    uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    // Array de uint256 que almacena los hash encontrados en el registro de stealth addresses.
    uint256[] foundH;
    // Array de address que almacena las stealth addresses encontradas en el registro de stealth addresses.
    address[] foundStA;

    // Array de uint256 que almacena claves privadas en el registro de stealth addresses.
    uint256[] privateKeys;
    // Array de uint256 que almacena coordenadas X de la clave pública en el registro de stealth addresses.
    uint256[] xs;
    // Array de uint256 que almacena coordenadas Y de la clave pública en el registro de stealth addresses.
    uint256[] ys;
    // Array de address que almacena stealth addresses en el registro de stealth addresses.
    address[] stealthAddresses;
    // Array de uint256 que almacena view tags en el registro de stealth addresses.
    uint256[] viewTags;
    // uint256 que almacena la posición del iterador que añade lo anterior al registro de stealth addresses.
    uint256 index = 0;

    // Data structures

    // Estructura que almacena los datos del registro de stealth addresses junto con la clave privada
    // y las coordenadas de la clave pública del receptor.
    struct RegistroStealthAddresses {
        // uint256 que almacena la coordenada X de la clave efímera pública obtenida del registro.
        uint256 ex;
        // uint256 que almacena la coordenada Y de la clave efímera pública obtenida del registro.
        uint256 ey;
        // address que almacena la stealth address obtenida del registro.
        address stA;
        // uint256 que almacena la view tag obtenida del registro.
        uint256 viewTag;
        // uint256 que almacena la clave privada del receptor.
        uint256 privateKey;
        // uint256 que almacena la coordenada X de la clave pública del receptor.
        uint256 x;
        // uint256 que almacena la coordenada Y de la clave pública del receptor.
        uint256 y;
    }

    // Functions

    // Función encargada de generar una clave privada aleatoria.
    // @return privateKey: Clave privada generada.
    function generate_random_private_key() public view returns (uint256) {
        // Obtención de un hash a partir del timestamp del bloque, su dificultad y la dirección de
        // quien llama a la función.
        bytes32 hash = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender));
        // Obtención de la clave privada con formato uint256.
        uint256 privateKey = uint256(hash);

        // Cálculo del módulo PP de la clave privada.
        privateKey = privateKey % PP;

        // Se devuelve la clave privada obtenida.
        return privateKey;
    }

    // Función encargada de generar una clave pública a partir de una clave privada.
    // @param privateKey: Clave privada.
    // @return x: Coordenada X de la clave pública generada.
    // @return y: Coordenada Y de la clave pública generada.
    function generate_public_key(uint256 privateKey) public pure returns (uint256, uint256) {
        // Se calculan las coordenadas X e Y de la clave pública generada a partir de la
        // multiplicación de la clave privada con el punto generador de la curva elíptica.
        (uint256 x, uint256 y) = EllipticCurve.ecMul(privateKey, GX, GY, AA, PP);

        // Se devuelven las coordenadas X e Y de la clave pública.
        return (x, y);
    }

    // Función que genera una stealth meta-address a partir de una clave pública.
    // @param x: Coordenada X de la clave pública.
    // @param y: Coordenada Y de la clave pública.
    // @return stealthMetaAddress: Stealth meta-address generada.
    function generate_stealth_meta_address(uint256 x, uint256 y) public pure returns (string memory) {
        // Inicialización de la variable prefix, que almacenará el prefijo.
        string memory prefix = "";
        // Si la coordenada Y de la clave pública es par, entonces el prefijo será 02.
        if (y % 2 == 0) {
            prefix = "02";
        }
        // Si la coordenada Y de la clave pública es impar, entonces el prefijo será 03.
        else {
            prefix = "03";
        }

        // Conversión de la coordenada X a string hexadecimal y a bytes para poder generar el
        // string a devolver eliminar el literal "0x" de este.
        bytes memory strBytes = bytes(Strings.toHexString(uint256(x), 32));
        // Obtención del tamaño de bytes para guardar la cadena resultante de eliminar el literal "0x".
        bytes memory result = new bytes(strBytes.length-2);
        // Bucle en el cual se recorre la cadena íntegra evitando el literal "0x", obteniendo el valor
        // hexadecimal de la coordenada X.
        for(uint i = 2; i < strBytes.length; i++) {
            result[i-2] = strBytes[i];
        }

        // Generación del string a devolver con el formato de la stealth meta-address.
        string memory stealthMetaAddress = string.concat("st:eth:0x", prefix, string(result));
        
        // Se devuelve la stealth meta-address generada.
        return stealthMetaAddress;
    }

    // Función que obtiene la clave pública a partir de los datos contenidos en una stealth meta-address.
    // @param prefix: Prefijo contenido en una stealth meta-address.
    // @param x: Coordenada X en hexadecimal de la clave pública a obtener, contenida en una stealth meta-address.
    // @return uint256(x): Coordenada X de la clave pública.
    // @return y: Coordenada Y de la clave pública.
    function uncompress_stealth_meta_address(uint8 prefix, uint256 x) public pure returns (uint256, uint256) {
        // Obtención de la coordenada Y de la clave pública a partir del prefijo y la coordenada X.
        uint256 y = EllipticCurve.deriveY(prefix, uint256(x), AA, BB, PP);

        // Se devuelven las coordenadas X e Y de la clave pública.
        return (uint256(x), y);
    }

    // Función que genera una stealth address a partir de una clave privada y una clave pública.
    // @param privateKey: Clave privada.
    // @param x: Coordenada X de la clave pública.
    // @param y: Coordenada Y de la clave pública.
    // @return stealthAddress: Stealth address generada.
    // @return viewTag: View tag de la stealth address generada.
    function generate_stealth_address(uint256 privateKey, uint256 x, uint256 y) public pure returns (address, uint256){
        // Cálculo del secreto compartido multiplicando la clave privada por la clave pública.
        (uint256 Qx,uint256 Qy) = EllipticCurve.ecMul(privateKey, x, y, AA, PP);
        // Cálculo del hash del secreto compartido.
        bytes32 hQ = keccak256(abi.encodePacked(Qx, Qy));
        // Cálculo del valor del hash con módulo PP.
        uint256 hQB = uint256(hQ)%PP;
        // Conversión a 32 bytes del hash.
        hQ = keccak256(abi.encodePacked(hQB));
        // Obtención de la view tag a partir del primer byte del hash.
        uint256 viewTag = uint256(uint8(hQ[0]));
        // Obtención de una clave pública multiplicando el hash del
        // secreto compartido con el punto generador de la curva elíptica.
        (Qx, Qy) = EllipticCurve.ecMul(uint256(hQ), GX, GY, AA, PP);
        // Obtención de la clave pública de la stealth address sumando la clave pública
        // anterior con la recibida por parámetro.
        (Qx, Qy) = EllipticCurve.ecAdd(x, y, Qx, Qy, AA, PP);
        // Generación de la stealth address a partir de su clave pública.
        address stealthAddress = address(uint160(uint256(keccak256(abi.encodePacked(Qx, Qy)))));
        // Se devuelven la stealth address y la view tag.
        return (stealthAddress, viewTag);
    }

    // Función que compara dos view tags.
    // @param retrievedViewTag: View tag obtenida.
    // @param comparedViewTag: View tag con la que se compara.
    // @return bool: True si coinciden, False si no coinciden.
    function check_view_tag(uint256 retrievedViewTag, uint256 comparedViewTag) public pure returns (bool) {
        // Se devuelve el resultado de comparar ambas view tags.
        return (retrievedViewTag == comparedViewTag);
    }

    // Función que obtiene el hash de la clave privada de una stealth address a partir de la clave privada
    // y la clave efímera pública.
    // @param privateKey: Clave privada.
    // @param ephPublicKeyX: Coordenada X de la clave efímera pública.
    // @param ephPublicKeyY: Coordenada Y de la clave efímera pública.
    // @return bytes32(result): Hash de la clave privada de la stealth address.
    function retrieve_hash(uint256 privateKey, uint256 ephPublicKeyX, uint256 ephPublicKeyY) public pure returns(bytes32){
        // Cálculo del secreto compartido multiplicando la clave privada por la clave efímera pública.
        (uint256 x,uint256 y) = EllipticCurve.ecMul(privateKey, ephPublicKeyX, ephPublicKeyY, AA, PP);
        // Cálculo del hash del secreto compartido.
        bytes32 hash = keccak256(abi.encodePacked(x, y));
        // Cálculo del valor del hash con módulo PP.
        uint256 hQB = uint256(hash)%PP;
        // Conversión a 32 bytes del hash.
        hash = keccak256(abi.encodePacked(hQB));
        // Cálculo de la clave privada de la stealth address.
        uint256 result = (privateKey + uint256(hash))%PP;
        // Se devuelve el hash de la clave privada de la stealth address.
        return bytes32(result);
    }

    // Función que obtiene el hash de la clave privada de una stealth address a partir
    // de una clave privada y un hash.
    // @param privateKey: Clave privada.
    // @param hash: Hash de la stealth address.
    // @return bytes32(result): Hash de la clave privada de la stealth address.
    function retrieve_stealth_address_priv_key(uint256 privateKey, uint256 hash) public pure returns(bytes32){
        // Cálculo de la clave privada de la stealth address.
        uint256 hashPP = uint256(hash)%PP;
        uint256 result = (privateKey + hashPP)%PP;
        // Se devuelve el hash de la clave privada de la stealth address.
        return bytes32(result);
    }

    // Función que genera una stealth address y su hash a partir de una entrada
    // del registro de stealth addresses.
    // @param registro: Entrada del registro de stealth addresses.
    // @return uint256, address: Devuelve el hash y la stealth address.
    function parse_single_event(RegistroStealthAddresses memory registro) public pure returns(uint256, address) {
        // Cálculo del secreto compartido multiplicando la clave privada por la clave efímera pública.
        (uint256 x,uint256 y) = EllipticCurve.ecMul(registro.privateKey, registro.ex, registro.ey, AA, PP);
        // Cálculo del hash del secreto compartido.
        bytes32 hash = keccak256(abi.encodePacked(x, y));
        // Cálculo del valor del hash con módulo PP.
        uint256 hQB = uint256(hash)%PP;
        // Conversión a 32 bytes del hash.
        hash = keccak256(abi.encodePacked(hQB));
        // Obtención de la view tag a partir del primer byte del hash.
        uint256 retrievedViewTag = uint256(uint8(hash[0]));
        // Se comprueba que la view tag almacenada en la entrada del registro sea
        // igual que la obtenida en el paso anterior. Si no lo son, se devuelve
        // 0 y la stealth address almacenada en la entrada del registro.
        if (!check_view_tag(retrievedViewTag, registro.viewTag)){
            return (0, registro.stA);
        }

        // Obtención de una clave pública multiplicando el hash del
        // secreto compartido con el punto generador de la curva elíptica.
        (uint256 x2, uint256 y2) = EllipticCurve.ecMul(uint256(hash), GX, GY, AA, PP);        
        // Obtención de la clave pública de la stealth address sumando la clave pública
        // anterior con la recibida por parámetro.
        (x2, y2) = EllipticCurve.ecAdd(registro.x, registro.y, x2, y2, AA, PP);
        // Generación de la stealth address a partir de su clave pública.
        address stealthAddress = address(uint160(uint256(keccak256(abi.encodePacked(x2, y2)))));

        // Se comprueba que la stealth address almacenada coincida con la generada en el
        // paso anterior. Si es así, se devuelve el valor del hash y la stealth address.
        if (stealthAddress == registro.stA){
            return (uint256(hash), stealthAddress); 
        }

        // En caso de no coincidir, se devolverá 0 y la stealth address generada en esta función.
        return (0, stealthAddress);

    }

    // Función que busca entradas en el registro de stealth addresses que coincidan con las que se generan
    // a partir de una clave privada y su clave pública.
    // @param privateKey: Clave privada.
    // @param x: Coordenada X de la clave pública.
    // @param y: Coordenada Y de la clave pública.
    // @return foundStA, foundH: Listas de stealth addresses coincidentes y de sus hashes.
    function parse(uint256 privateKey, uint256 x, uint256 y) public returns (address[] memory, uint256[] memory) {
        // Inicialización de la variable dhSecretHash, que almacenará el hash obtenido.
        uint256 dhSecretHash;
        // Inicialización de la variable stealthAddress, que almacenará la stealth address obtenida.
        address stealthAddress;
        // Bucle que recorre el registro de stealth addresses.
        for (uint256 i = 0; i < xs.length; i++) {
            // Selección de una entrada del registro de stealth addresses, añadiendo la
            // clave privada y la clave pública pasadas por parámetro.
            RegistroStealthAddresses memory registro = RegistroStealthAddresses({
                ex: xs[i],
                ey: ys[i],
                stA: stealthAddresses[i],
                viewTag: viewTags[i],
                privateKey: privateKey,
                x: x,
                y: y
            });
            // Llamada a la función parse_single_event() para obtener el hash y la
            // stealth address obtenidos a partir de los datos de la entrada del registro.
            (dhSecretHash, stealthAddress) = parse_single_event(registro);
            // Se comprueba que el hash devuelto no sea 0. Si se cumple la concición,
            // se añaden el hash y la stealth address a las listas de encontrados.
            if (dhSecretHash != 0) {
                foundH.push(dhSecretHash);
                foundStA.push(stealthAddress);
            }
        }

        // Se devuelven las listas de stealth addresses y hashes encontrados en el registro.
        return (foundStA, foundH);        
    }

    // Función que añade una entrada aleatoria al registro de stealth addresses.
    function rellenar_random() public {
        // Se genera una clave privada y se añade a la lista de claves privadas
        // del registro de stealth addresses.
        privateKeys.push(generate_random_private_key());
        // Se generan las coordenadas X e Y de la clave pública correspondiente
        // a la clave privada generada.
        (uint256 x, uint256 y) = generate_public_key(privateKeys[index]);
        // Se añade la coordenada X a la lista de coordenadas X del registro de
        // stealth addresses.
        xs.push(x);
        // Se añade la coordenada Y a la lista de coordenadas X del registro de
        // stealth addresses.
        ys.push(y);
        // Se calcula la stealth address y se añade al registro de stealth addresses.
        stealthAddresses.push(address(uint160(uint256(keccak256(abi.encodePacked(x, y))))));
        // Se añade el índice como view tag al registro de stealth addresses.
        viewTags.push(index);
        // Se aumenta el índice.
        index ++;
    }

    // Función que añade una entrada específica al registro de stealth addresses.
    // @param privateKey: Clave privada.
    // @param x: Coordenada X de la clave pública.
    // @param y: Coordenada Y de la clave pública.
    // @param stealthAddress: Stealth address.
    // @param viewTag: View tag de la stealth address.
    function rellenar_especifico(uint256 privateKey, uint256 x, uint256 y, address stealthAddress, uint256 viewTag) public {
        // Se añade la clave privada a la lista de claves privadas
        // del registro de stealth addresses.
        privateKeys.push(privateKey);
        // Se añade la coordenada X a la lista de coordenadas X del registro de
        // stealth addresses.
        xs.push(x);
        // Se añade la coordenada Y a la lista de coordenadas X del registro de
        // stealth addresses.
        ys.push(y);
        // Se añade la stealth address al registro de stealth addresses.
        stealthAddresses.push(stealthAddress);
        // Se añade la view tag al registro de stealth addresses.
        viewTags.push(viewTag);
        // Se aumenta el índice.
        index ++;
    }
}
