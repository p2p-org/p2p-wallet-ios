# ``TransactionParser``

The library that allow to parse solana transaction into user-friendly transaction struct.

It makes application layer easier to read the data from raw solana transaction by categorize the type and recognize the important fields.

## Topics

### Service

- ``TransactionParserService``
- ``TransactionParserServiceImpl``

### Transaction parsing strategy

- ``TransactionParseStrategy``
- ``TransferParseStrategy``
- ``CloseAccountParseStrategy``
- ``CreationAccountParseStrategy``
- ``SerumSwapParseStrategy``
- ``OrcaSwapParseStrategy``

### Fee parsing strategy

- ``FeeParseStrategy``
- ``DefaultFeeParseStrategy``