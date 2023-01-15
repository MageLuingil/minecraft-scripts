Shulker systemd service
=======================

Service files for systemd to run multiple instances of [destruc7i0n/shulker](https://github.com/destruc7i0n/shulker)

Installing
----------

Assuming a local user `minecraft` with a home directory at `/var/games/minecraft/`; change these values as appropriate.

### Install NVM for local user

1. Install latest nvm from nvm.sh
   ```
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | mcdo bash
   export NVM_DIR="/var/games/minecraft/.nvm"
   ```
2. Install node 16
   ```
   sudo -u minecraft bash -c ". $NVM_DIR/nvm.sh; nvm install --default 16"
   ```

### Install shulker

1. Clone (or symlink) [destruc7i0n/shulker](https://github.com/destruc7i0n/shulker) to `/usr/games/minecraft-discord`
2. Build shulker
   ```
   sudo -u minecraft NODE_VERSION=16 $NVM_DIR/nvm-exec npm install
   sudo -u minecraft NODE_VERSION=16 $NVM_DIR/nvm-exec npm run build
   ```
3. Install service scripts to /etc/systemd/system/
   ```
   sudo cp ./shulker*.service /etc/systemd/system/
   ```

Usage
-----

### Run a single service

Create a `config.json` file in `/usr/games/minecraft-discord`, then start the service with
```
sudo systemctl start shulker.service
```

### Run multiple services

Add shulker config files to `/etc/shulker/config.[server-name].json`, then start the services with
```
sudo systemctl start shulker@[server-name].service
```
