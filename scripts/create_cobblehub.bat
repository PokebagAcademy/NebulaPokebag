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

set "SERVER_DIR=%ROOT%\servers\CobbleHub-1.21.1"
if exist "%SERVER_DIR%" (
  echo Server exists at %SERVER_DIR% - skipping generation.
) else (
  echo Generating server...
  call npm run start -- g server CobbleHub 1.21.1 --fabric 0.18.4
)

set "SRC_DIR=%ROOT%\servers\fabricmods"
set "DEST_DIR=%SERVER_DIR%\fabricmods\required"

if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

echo Writing servermeta.json (only if missing - an existing file is the source of truth)...
node -e "const fs=require('fs');const path=require('path');const root=process.env.ROOT||'.';const dir=path.join(root,'servers','CobbleHub-1.21.1');if(!fs.existsSync(dir)){console.error('missing',dir);process.exit(1);}const target=path.join(dir,'servermeta.json');if(fs.existsSync(target)){console.log('servermeta.json already exists - keeping it');process.exit(0);}const meta={};meta['schema']='file:///'+root+'/schemas/ServerMetaSchema.schema.json';meta.meta={version:'1.0.1',name:'CobbleHub Server',description:'CobbleHub Server (Minecraft 1.21.1)',icon:'',address:'play.cobblehub.fr',discord:{},mainServer:true,autoconnect:true};meta.fabric={version:'0.18.4'};meta.untrackedFiles=[{appliesTo:['files'],patterns:['options.txt','config/iris.properties','config/iris-excluded.json','config/xaerohud.txt','config/xaero/**','config/fancymenu/user_variables.db','config/fancymenu/animation_controller_states.json','config/fancymenu/normalized_scroll_screens.json','config/fancymenu/video_element_controller_metas.json','config/fancymenu/legacy_checklist.txt','fancymenu_data/**']}];fs.writeFileSync(target,JSON.stringify(meta,null,2));console.log('Wrote',target);"

echo Generating distribution.json...
call npm run start -- g distro
if %ERRORLEVEL% neq 0 (
  echo Failed to generate distribution.json
) else (
  echo Generated %ROOT%\distribution.json
)

echo Done.
