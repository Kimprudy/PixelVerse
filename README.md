# PixelVerse Protocol

PixelVerse is a dynamic NFT protocol built on Stacks blockchain that implements market-driven minting mechanics with real-time adjustments. The protocol features an innovative ecosystem factor that automatically adjusts creation limits based on market activity and collector engagement.

## Features

### Dynamic Creation Mechanics
- Adaptive minting limits based on market activity
- Real-time price floor adjustments
- Automatic ecosystem factor calculation
- Built-in cooldown periods between creations

### Market Analytics
- Comprehensive trading volume tracking
- Unique collector metrics
- Historical price point tracking
- Individual collector activity statistics

### Smart Contract Security
- Robust input validation
- Comprehensive error handling
- Admin-only protected functions
- Secure transfer mechanisms

## Technical Specifications

### Base Parameters
- Initial Creation Cost: 100 STX
- Collection Limit: 1,000 pixels
- Base Creation Delay: 100 blocks
- Initial Ecosystem Factor: 100 (base percentage)

### Data Structures

#### Pixel Registry
```clarity
{
    pixel-id: uint,
    collector: principal,
    tier: uint,
    art-uri: (string-ascii 256)
}
```

#### Collector Statistics
```clarity
{
    last-action: uint,
    action-count: uint
}
```

#### Market History
```clarity
{
    rate: uint,
    turnover: uint
}
```

### Core Functions

#### create-pixel
Creates a new pixel NFT with the specified art URI. Subject to:
- Dynamic creation limits
- Cooldown period
- Current ecosystem factor
- Valid metadata requirements

#### transfer-pixel
Transfers pixel ownership between collectors with:
- Automatic collector metrics updates
- Activity tracking
- Balance management
- Ownership verification

#### get-ecosystem-metrics
Retrieves current protocol metrics including:
- Base price
- Trading volume
- Unique collectors count
- Current ecosystem factor
- Dynamic creation limit

## Usage

### Creating a Pixel
```clarity
(contract-call? .pixelverse create-pixel "https://artwork.uri")
```

### Transferring a Pixel
```clarity
(contract-call? .pixelverse transfer-pixel u1 'RECIPIENT.address)
```

### Checking Ecosystem Metrics
```clarity
(contract-call? .pixelverse get-ecosystem-metrics)
```

## Administrative Functions

### Setting Creation Delay
```clarity
(contract-call? .pixelverse set-creation-delay u150)
```

### Updating Base Price
```clarity
(contract-call? .pixelverse set-base-price u120000000)
```

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Admin restricted operation |
| u101 | Unauthorized holder |
| u102 | Pixel not found |
| u103 | Balance too low |
| u104 | Creation cap reached |
| u105 | Invalid caller |
| u106 | Operation blocked |
| u107 | Creation timeout |
| u108 | Price threshold |
| u109 | Invalid pixel ID |
| u110 | Invalid metadata |
| u111 | Invalid value |

## Market Dynamics

The protocol implements a dynamic ecosystem factor that adjusts based on:
1. Collector adoption rate
2. Trading volume
3. Base price movements
4. Historical market activity

This creates a self-regulating system that:
- Rewards early adopters
- Maintains market stability
- Encourages active trading
- Prevents market manipulation

## Security Considerations

### Input Validation
- All public functions implement comprehensive input validation
- Metadata URI length and format verification
- Pixel ID range checks
- Amount validation for all numeric inputs

### Access Control
- Administrative functions restricted to contract admin
- Transfer operations verified against current ownership
- Protocol-wide pause mechanism for emergency situations

### Market Protection
- Cooldown periods between creations
- Dynamic creation limits
- Price floor protection
- Automated market factor adjustments

## Development

### Prerequisites
- Clarity CLI
- Stacks blockchain development environment
- Understanding of NFT and DeFi concepts

### Testing
Recommended test scenarios:
1. Creation mechanics under various market conditions
2. Transfer operations with different collector states
3. Ecosystem factor calculations with mock market data
4. Admin function access control
5. Error handling for invalid inputs

## Contributing

Contributions are welcome! Please follow these steps:
1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Add tests if applicable
5. Submit a pull request

