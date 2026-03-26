@echo off
REM Load .env into environment variables
if exist .env (
  for /f "usebackq tokens=1* delims==" %%A in (.env) do (
    set "%%A=%%B"
  )
)

echo Installing dependencies...
call npm install

echo Building...
call npm run build

echo Initializing root...
call npm run start -- init root

set "SERVER_DIR=%ROOT%\servers\PokeBag-1.21.1"
if exist "%SERVER_DIR%" (
  echo Server exists at %SERVER_DIR% - skipping generation.
) else (
  echo Generating server...
  call npm run start -- g server PokeBag 1.21.1 --fabric 0.18.4
)

set "SRC_DIR=%ROOT%\servers\fabricmods"
set "DEST_DIR=%SERVER_DIR%\fabricmods\required"

if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

if exist "%SRC_DIR%" (
  echo Using PowerShell to move and rename mods...
  powershell -NoProfile -Command "& { $src=Resolve-Path -LiteralPath '%SRC_DIR%' -ErrorAction SilentlyContinue; if($null -eq $src){ Write-Host 'Source not found'; exit 0 }; $dest='%DEST_DIR%'; if(-not (Test-Path $dest)){ New-Item -ItemType Directory -Path $dest | Out-Null }; Get-ChildItem -Path $src -File | ForEach-Object { $new = $_.Name -replace '\.disabled$',''; $target = Join-Path $dest $new; Write-Host ('Moving {0} -> {1}' -f $_.FullName, $target); Move-Item -LiteralPath $_.FullName -Destination $target -Force } }"
)

echo Writing servermeta.json...
node -e "const fs=require('fs');const path=require('path');const root=process.env.ROOT||'.';const dir=path.join(root,'servers','PokeBag-1.21.1');if(!fs.existsSync(dir)){console.error('missing',dir);process.exit(1);}const meta={};meta['$schema']='file:///'+root+'/schemas/ServerMetaSchema.schema.json';meta.meta={version:'1.0.0',name:'PokeBag Server',description:'PokeBag Server (Minecraft 1.21.1)',icon:'',address:'Play.pokebag.fr',discord:{},mainServer:false,autoconnect:true};meta.fabric={version:'0.18.4'};meta.untrackedFiles=[];fs.writeFileSync(path.join(dir,'servermeta.json'),JSON.stringify(meta,null,2));console.log('Wrote',path.join(dir,'servermeta.json'));"

echo Done.
