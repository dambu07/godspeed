#!/bin/bash
# Basic Godspeed usage example

# Check system
godspeed doctor

# Create React project
godspeed template react my-react-app
cd my-react-app

# Install dependencies and start
godspeed install
godspeed go
