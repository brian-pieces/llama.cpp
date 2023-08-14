#!/bin/bash

#
# Temporary script - will be removed in the future
#

cd `dirname $0`
cd ..

# Important:
#
#   "--keep 48" is based on the contents of prompts/chat-with-bob.txt
#
./main -m ./models/llama-2-7b-chat.ggmlv3.q4_K_M.bin -n 1024 -p "Give me 5 things to do in NYC"
