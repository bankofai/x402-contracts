#!/bin/bash
set -e  

echo "Cloning forge-std..."
git clone --branch v1.12.0 --depth 1 https://github.com/foundry-rs/forge-std ./lib/forge-std

echo "Cloning solmate..."
git clone https://github.com/transmissions11/solmate ./lib/solmate
cd lib/solmate
git checkout 89365b880c4f3c786bdd453d4b8e8fe410344a69
cd ../../

echo "Cloning sun std..."
git clone --branch v1.0.0 git@github.com:sun-protocol/sun-contract-std ./lib/sun-contract-std
echo "✅ All repositories cloned successfully."
