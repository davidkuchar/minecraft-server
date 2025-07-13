#!/bin/bash

echo "Starting PaperMC Server with GeyserMC..."
echo "Java Edition: localhost:25565"
echo "Bedrock Edition: localhost:19132"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Create data directory if it doesn't exist
mkdir -p data plugins config

# Start the server
docker-compose up