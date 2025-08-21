# Maritime Risk Management Smart Contract

## Overview

The Maritime Risk Management Smart Contract is a comprehensive blockchain-based system designed to manage maritime risks, vessel registration, insurance claims, and compliance monitoring. Built on the Stacks blockchain using Clarity smart contract language, this system provides a decentralized platform for maritime stakeholders to manage vessel operations, assess risks, handle insurance, and ensure regulatory compliance.

## Features

### Core Functionality
- **Vessel Registration**: Register and manage vessel information including IMO numbers, specifications, and ownership details
- **Risk Assessment**: Conduct comprehensive risk evaluations based on multiple factors
- **Insurance Management**: Purchase insurance policies and file claims with automated processing
- **Compliance Monitoring**: Track inspections, certifications, and regulatory compliance
- **Role-Based Access Control**: Multi-tier permission system for different user types

### Key Components
1. **Vessel Management System**: Complete vessel lifecycle management
2. **Dynamic Risk Scoring**: Multi-factor risk assessment algorithm
3. **Insurance Claims Processing**: Automated claim filing and approval workflow
4. **Compliance Tracking**: Inspection records and certification management
5. **Emergency Controls**: Contract pause and deactivation capabilities

## Architecture

### User Roles
- **Contract Owner**: Full administrative access to all contract functions
- **Admin (Role 1)**: Can process claims, manage vessel statuses, and assign roles
- **Inspector (Role 2)**: Authorized to conduct risk assessments and compliance inspections
- **Vessel Owner (Role 3)**: Can register vessels, purchase insurance, and file claims

### Data Structures

#### Vessels
Each vessel record contains:
- Basic information (name, type, IMO number, flag state)
- Technical specifications (gross tonnage, year built)
- Risk and insurance data (current risk score, premium, expiry)
- Compliance status and inspection history

#### Risk Assessments
Risk evaluations include:
- Six risk factors with weighted scoring
- Assessment validity periods
- Assessor information and notes
- Total calculated risk score

#### Insurance Claims
Claim records track:
- Claim details (amount, type, incident date)
- Processing status and approval workflow
- Associated vessel and claimant information

#### Compliance Records
Inspection records contain:
- Inspector details and inspection type
- Compliance scores and deficiencies
- Corrective actions and next inspection dates
- Certificate issuance status

## Installation and Deployment

### Prerequisites
- Stacks blockchain development environment
- Clarinet for local testing and deployment
- STX tokens for contract deployment and transactions

### Deployment Steps
1. Clone the contract code to your development environment
2. Test the contract using Clarinet's local blockchain
3. Deploy to Stacks testnet for integration testing
4. Deploy to Stacks mainnet for production use

```bash
# Example Clarinet commands
clarinet check
clarinet test
clarinet deploy --testnet
```

## Usage Guide

### Initial Setup
1. Deploy the contract (deployer becomes contract owner)
2. Assign roles to users using `assign-role` function
3. Configure any custom parameters if needed

### Vessel Registration
```clarity
(contract-call? .maritime-risk-management register-vessel
  "VESSEL001"           ;; vessel-id
  "Ocean Explorer"      ;; vessel-name
  "Container Ship"      ;; vessel-type
  "IMO1234567"         ;; imo-number
  "SGP"                ;; flag-state
  u50000               ;; gross-tonnage
  u2010                ;; year-built
)
```

### Risk Assessment
Inspectors can conduct risk assessments with six weighted factors:
- Age Factor (15% weight)
- Maintenance Factor (25% weight)
- Route Risk (20% weight)
- Crew Experience (15% weight)
- Weather Exposure (15% weight)
- Cargo Type Risk (10% weight)

### Insurance Management
1. **Purchase Insurance**: Calculate premiums based on risk scores and vessel values
2. **File Claims**: Submit insurance claims with incident details
3. **Process Claims**: Admins can approve or reject pending claims

### Compliance Monitoring
Inspectors can conduct various inspection types and record:
- Compliance scores (0-100)
- Identified deficiencies
- Required corrective actions
- Next inspection schedules

## API Reference

### Public Functions

#### Vessel Management
- `register-vessel`: Register a new vessel in the system
- `update-vessel-status`: Activate or deactivate vessels

#### Risk Assessment
- `conduct-risk-assessment`: Perform comprehensive risk evaluation

#### Insurance
- `purchase-insurance`: Buy insurance coverage for vessels
- `file-insurance-claim`: Submit insurance claims
- `process-claim`: Admin function to approve/reject claims

#### Compliance
- `conduct-compliance-inspection`: Record inspection results

#### Role Management
- `assign-role`: Grant roles to users
- `revoke-role`: Remove user roles

#### Emergency Controls
- `set-emergency-pause`: Pause contract operations
- `deactivate-contract`: Permanently disable contract

### Read-Only Functions
- `get-vessel-info`: Retrieve vessel details
- `get-risk-assessment`: Get risk assessment records
- `get-insurance-claim`: View claim information
- `get-compliance-record`: Access inspection records
- `get-vessel-risk-level`: Get risk classification (HIGH/MEDIUM/LOW)
- `is-vessel-compliant`: Check compliance and insurance status

## Risk Scoring Algorithm

The contract uses a weighted scoring system:
```
Total Risk Score = (Age × 15% + Maintenance × 25% + Route × 20% + 
                   Crew × 15% + Weather × 15% + Cargo × 10%)
```

Risk Classifications:
- **HIGH RISK**: Score ≥ 70
- **MEDIUM RISK**: Score 40-69
- **LOW RISK**: Score < 40

## Insurance Premium Calculation

Premium calculation formula:
```
Premium = (Vessel Value × (100 + Risk Score × 10)) ÷ 10,000
```

## Security Features

### Access Control
- Role-based permissions with hierarchical access
- Function-level authorization checks
- Owner-only emergency controls

### Data Validation
- Input validation for all parameters
- Range checks for numerical values
- Existence checks for referenced entities

### Emergency Mechanisms
- Contract pause functionality
- Complete contract deactivation
- Administrative override capabilities

## Error Codes

The contract defines comprehensive error codes for debugging:
- `u100`: Not authorized
- `u101`: Vessel not found
- `u102`: Vessel already exists
- `u103`: Invalid risk score
- `u104`: Claim not found
- `u105`: Claim already processed
- And many more specific error conditions

## Limitations and Considerations

### Current Limitations
- No actual STX token transfers implemented (placeholder for premium payments)
- Fixed time periods based on block heights
- Limited storage for text fields
- No external data oracle integration