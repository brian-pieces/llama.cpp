# Download model
```shell
curl -L https://huggingface.co/TheBloke/Llama-2-7B-GGML/resolve/main/llama-2-7b.ggmlv3.q4_K_M.bin --output ./models/llama-2-7b.ggmlv3.q4_K_M.bin
```

# Build
```shell
mkdir build && cd build && cmake .. && cmake --build . --config Release
```

# Run
```shell
dart test
```