#!/bin/bash

# Check if a context name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <context-name>"
  exit 1
fi

# Get the provided context name
context_name=$1

# Get the current context
current_context=$(kubectl config current-context)

# Check if the current context matches the provided context name
if [ "$current_context" == "$context_name" ]; then
  echo "You're working in the correct context '$context_name'. Continuing."
else
  # Unset the current context
  kubectl config unset current-context
  echo "The current context was '$current_context'. It has been unset to prevent working in the wrong cluster."
  echo "Please run 'az login' and then the pnpm connect script to make sure you're connected to the correct environment."
  az login
  az aks get-credentials --resource-group rg-$context_name --name $context_name
fi