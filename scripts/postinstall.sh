#!/bin/bash
set -e  

echo "Cloning solmate..."
git clone https://github.com/transmissions11/solmate ./lib/solmate
cd lib/solmate
git checkout 89365b880c4f3c786bdd453d4b8e8fe410344a69

echo "✅ All repositories cloned successfully."
