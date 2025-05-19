# Tokenized Energy Attribute Certificate (EAC) Trading System

A blockchain-based system for verifying renewable energy generation, issuing tradable certificates, and managing their lifecycle from creation to retirement.

## Overview

This project implements a complete Energy Attribute Certificate (EAC) system using Clarity smart contracts for the Stacks blockchain. The system allows for:

1. Verification of renewable energy generators
2. Tracking of energy production
3. Issuance of tradable certificates
4. Trading of certificates on a marketplace
5. Retirement of certificates for environmental claims

## Smart Contracts

### Generator Verification Contract

This contract maintains a registry of verified renewable energy generators with details about their location, capacity, and energy type.

Key functions:
- `register-generator`: Add a new generator to the registry
- `is-verified-generator`: Check if a generator is verified
- `revoke-verification`: Remove a generator from the registry

### Production Tracking Contract

This contract records energy production data from verified generators over specified time periods.

Key functions:
- `record-production`: Log energy production for a verified generator
- `verify-production`: Admin verification of production claims
- `get-production`: Retrieve production details
- `start-new-period`: Begin a new production tracking period

### Certificate Issuance Contract

This contract creates non-fungible tokens (NFTs) representing Energy Attribute Certificates for verified production.

Key functions:
- `issue-certificate`: Mint a new certificate for verified production
- `get-certificate-info`: Retrieve certificate details

### Trading Contract

This contract provides a marketplace for buying and selling energy certificates with built-in fee mechanisms.

Key functions:
- `list-certificate`: Put a certificate up for sale
- `buy-certificate`: Purchase a listed certificate
- `cancel-listing`: Remove a certificate from the marketplace
- `get-listing`: View details of a listed certificate

### Retirement Contract

This contract manages the permanent removal of certificates from circulation after they've been used for environmental claims.

Key functions:
- `retire-certificate`: Permanently retire a certificate
- `get-retirement-info`: View retirement details
- `admin-retire-certificate`: Admin-initiated retirement

## System Architecture

The contracts work together in the following workflow:

1. Generators are verified through the Generator Verification Contract
2. Verified generators record their energy production in the Production Tracking Contract
3. Admins verify the production data
4. Certificates are issued for verified production through the Certificate Issuance Contract
5. Certificate owners can list their certificates for sale through the Trading Contract
6. Buyers can purchase certificates through the Trading Contract
7. Certificate owners can permanently retire certificates through the Retirement Contract

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- Node.js and npm for running tests

### Installation

1. Clone the repository
