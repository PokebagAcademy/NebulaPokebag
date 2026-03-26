#!/usr/bin/env bash
set -euo pipefail

echo "Loading .env..."
if [ -f .env ]; then
  set -a
  . .env
  set +a
fi

echo "Installing dependencies..."
npm install

echo "Building project..."
npm run build

echo "Initializing root..."
npm run start -- init root

echo "Generating server PokeBag 1.21.1 with Fabric 0.18.4..."
npm run start -- g server PokeBag 1.21.1 --fabric 0.18.4

SERVER_DIR="$(realpath "${ROOT}/servers/PokeBag-1.21.1")"
SRC_DIR="$(realpath "${ROOT}/servers/fabricmods")"
DEST_DIR="${SERVER_DIR}/fabricmods/required"

mkdir -p "$DEST_DIR"

if [ -d "$SRC_DIR" ]; then
  shopt -s nullglob
  for f in "$SRC_DIR"/*; do
    if [ -f "$f" ]; then
      bn="$(basename "$f")"
      new="${bn%.disabled}"
      echo "Moving $bn -> $new"
      mv "$f" "$DEST_DIR/$new"
    fi
  done
fi

echo "Writing servermeta.json..."
node -e "const fs=require('fs');const path=require('path');const root=process.env.ROOT||'.';const dir=path.join(root,'servers','PokeBag-1.21.1');if(!fs.existsSync(dir)){console.error('Server dir missing',dir);process.exit(1);}const meta={};meta['$schema']='file:///'+root+'/schemas/ServerMetaSchema.schema.json';meta.meta={version:'1.0.0',name:'PokeBag Server',description:'PokeBag Server (Minecraft 1.21.1)',icon:'',address:'Play.pokebag.fr',discord:{},mainServer:false,autoconnect:true};meta.fabric={version:'0.18.4'};meta.untrackedFiles=[];fs.writeFileSync(path.join(dir,'servermeta.json'),JSON.stringify(meta,null,2));console.log('Wrote',path.join(dir,'servermeta.json'));"

echo "Done."
