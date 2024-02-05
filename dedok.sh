#!/bin/bash

# install libssl1.1 (fix for runpod.io)
wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.20_amd64.deb
dpkg -i libssl1.1_1.1.1f-1ubuntu2.20_amd64.deb || echo "libssl1.1 could not be installed."
rm libssl1.1_1.1.1f-1ubuntu2.20_amd64.deb

# Install simple text editor
if ! [ -x "$(command -v nano)" ]; then
    echo 'Installing nano' >&2
    
    # Compatible with runpod.io
    wget http://mirrors.kernel.org/ubuntu/pool/main/n/nano/nano_4.8-1ubuntu1_amd64.deb
    dpkg -i nano_4.8-1ubuntu1_amd64.deb
    rm nano_4.8-1ubuntu1_amd64.deb
fi

# Check if miner is installed
if [ ! -d "$HOME/miner" ]; then
    echo "Miner not installed. Installing."
    
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs
    
    cd "$HOME" || exit
    git clone https://github.com/TrueCarry/JettonGramGpuMiner.git miner
    
    cd miner || exit
    
    printf "Miner installed! Start mining with \x1B[32m./1000.sh\x1B[0m\n"
else
    cd "$HOME/miner" || exit
    echo "Miner installed. Updating."
    git pull
    
    printf "Miner updated! Start mining with \x1B[32m./1000.sh\x1B[0m\n"
fi

GPU_COUNT=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l) > /dev/null 2>&1

# Update start file
if [ "$GPU_COUNT" = "0" ]; then
    echo "Cant get GPU count. Aborting."
    exit 1
    elif [ "$GPU_COUNT" = "1" ]; then
    echo "One GPU detected. Creating start file"
    cat > 1000.sh << EOL
#!/bin/bash
npm install

while true; do
    node send_universal.js --api tonapi --bin ./pow-miner-cuda --givers 1000
    sleep 1;
done;
EOL
else
    echo "Detected ${GPU_COUNT} GPUs. Creating start file"
    cat > 1000.sh << EOL
#!/bin/bash
npm install

while true; do
    node send_multigpu.js --api tonapi --bin ./pow-miner-cuda --givers 1000 --gpu-count ${GPU_COUNT}
    sleep 1;
done;
EOL
fi

chmod +x 1000.sh
echo -e 'SEED=layer waste proud baby fish hair popular near chuckle coach unveil draw asset skill version rescue dynamic raccoon poverty piece puppy post stamp plate' >> config.txt
printf "\x1B[31mDONT FORGET TO CREATE config.txt BEFORE START!!!\x1B[0m\n"
bash 1000.sh
