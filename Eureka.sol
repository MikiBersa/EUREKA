pragma solidity ^0.8.0;

// Interfaccia dell'oracolo
interface OracleInterface {
    function verificaLiquiditaConto(address _wallet, string memory _contobancario) external view returns (bool);
}

contract ContoBancario {
    OracleInterface private oracle; // Riferimento all'oracolo

    struct Wallet {
        string contoBancario;
        uint256 capitaleBloccato;
        uint256 tokenEurekaGenerati;
        uint256 numeroRateMancanti;
        uint256 interesseTotale;
    }

    mapping(address => Wallet) public wallets;

    uint256 public constant MAX_RATE_MANCANTI = 3; // Numero massimo di rate mancanti consentite

    constructor(address _oracleAddress) {
        oracle = OracleInterface(_oracleAddress);
    }

    function associaContoBancario(string memory _contoBancario) external {
        require(bytes(wallets[msg.sender].contoBancario).length == 0, "Conto bancario già associato");

        bool isLiquiditaVerificata = oracle.verificaLiquiditaConto(msg.sender, _contoBancario);

        require(isLiquiditaVerificata, "Liquidità del conto non verificata");

        wallets[msg.sender].contoBancario = _contoBancario;
    }

    function bloccaCapitale(uint256 _capitale) external {
        require(bytes(wallets[msg.sender].contoBancario).length != 0, "Conto bancario non associato");

        // Aggiorna il capitale bloccato nel wallet
        wallets[msg.sender].capitaleBloccato = _capitale;
    }

    function ripagaRata(uint256 _rata) external {
        require(bytes(wallets[msg.sender].contoBancario).length != 0, "Conto bancario non associato");

        // Verifica che il capitale bloccato sia maggiore o uguale alla rata da ripagare
        require(wallets[msg.sender].capitaleBloccato >= _rata, "Capitale bloccato insufficiente");

        // Aggiorna il numero di rate mancanti nel caso in cui la rata non sia stata pagata
        if (_rata > 0) {
            wallets[msg.sender].numeroRateMancanti = 0;
        } else {
            wallets[msg.sender].numeroRateMancanti++;
        }

        // Verifica se il cliente ha mancato 3 rate di fila
        if (wallets[msg.sender].numeroRateMancanti >= MAX_RATE_MANCANTI) {
            // Se il cliente ha mancato 3 rate di fila, elimina completamente i token EUREKA e impossessati del capitale bloccato
            wallets[msg.sender].tokenEurekaGenerati = 0;
            wallets[msg.sender].capitaleBloccato = 0;
            wallets[msg.sender].interesseTotale = 0;
        } else {
            // Calcola la quantità di token EUREKA da generare come il 90% del capitale bloccato più il 2,4%
            uint256 quantitaTokenEureka = (wallets[msg.sender].capitaleBloccato * 90) / 100 + (wallets[msg.sender].capitaleBloccato * 24) / 1000;

            // Aggiorna il numero di token EUREKA generati nel wallet
            wallets[msg.sender].tokenEurekaGenerati = quantitaTokenEureka;

            // Riduci il capitale bloccato del cliente della stessa quantità della rata ripagata
            wallets[msg.sender].capitaleBloccato -= _rata;
        }
    }
}
