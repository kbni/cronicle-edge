#!/bin/bash

cd "$(dirname "$0")"

usage() {
    echo "Usage: $0 /path/to/dist [--s3 | --lmdb | --level | --sftp | --sql | --dev | --verbose]"
    exit 1
}

writehead() {
    printf "\n ---- $1 [$(date +"%T")]\n"    
}

# -------------------- ARG CHECK 
x=0 
dist="dist"

while (( "$#" )); do
    case $1 in
        --s3 )    s3=1 ;;
        --sftp )  sftp=1 ;;
        --lmdb )  lmdb=1 ;;
        --level ) level=1 ;;
        --sql )   sql=1 ;;
        --dev | -d )  dev=1 ;;
        --verbose | -v )  verbose=1 ;;
        --force | -f )  force=1 ;;
        --restart | -r ) restart=1 ;;
        -*) echo "invalid parameter: $1"; usage ;;
        * ) dist=$1; x=$(($x + 1))
    esac
shift
done


if [ "$x" -gt 1 ]; then
  echo "Too many arguments"; usage;
fi


if ! command -v npm &>/dev/null ; then
    echo "npm is not installed"
    exit 1
fi

if ! command -v node &>/dev/null ; then
    echo "node is not installed"
    exit 1
fi

# ---------------------------------------------------------------------

echo "-----------------------------------------"
echo " Installing cronicle bundle into $dist"
echo "-----------------------------------------"
echo ""

# debug settings
minify="--minify=true"
ESBuildLogLevel="warning"
npmLogLevel="warn"

# check if cronicle is running and stop
if [ -e $dist/logs/cronicled.pid ]; then 
  if ps -p $(cat $dist/logs/cronicled.pid) > /dev/null; then
    writehead "Stopping cronicle [use --restart param to auto start]"
    kill -9 $(cat $dist/logs/cronicled.pid)
  fi
fi
  
if [ "$dev" = 1 ]; then
  minify="--minify=false"
  ESBuildLogLevel="info"
  npmLogLevel="info"
fi

if [ "$restart" = 1 ]; then
  minify="--minify=false"
fi

if [ "$verbose" = 1 ]; then
  ESBuildLogLevel="info"
  npmLogLevel="info"
fi


# ---------------------------------------------------------

if ! command -v esbuild &>/dev/null; then
  writehead "Installing esbuild"
  npm i esbuild -g --loglevel $npmLogLevel
fi

if [ ! -d "node_modules" ] || [ "$force" = 1 ]; then
  writehead "Installing npm packages"
  npm install --loglevel $npmLogLevel
fi

# ----------------

mkdir -p $dist 
cp -r htdocs $dist/
cp -r bin  $dist/
cp package.json  $dist/bin/


# ------------------------------- 

writehead "Building frontend"


mkdir -p $dist/htdocs/js/external && cp \
 node_modules/jquery/dist/jquery.min.js \
 node_modules/moment/min/moment.min.js \
 node_modules/moment-timezone/builds/moment-timezone-with-data.min.js \
 node_modules/chart.js/dist/Chart.min.js \
 node_modules/jstimezonedetect/dist/jstz.min.js \
 node_modules/socket.io/client-dist/socket.io.min.js \
 node_modules/ansi_up/ansi_up.js \
 node_modules/jquery-ui-dist/jquery-ui.min.js \
 node_modules/graphlib/dist/graphlib.min.js \
 node_modules/vis-network/dist/vis-network.min.js \
 node_modules/xss/dist/xss.min.js \
 node_modules/jquery-datetimepicker/build/jquery.datetimepicker.full.min.js \
 node_modules/diff/dist/diff.min.js \
 $dist/htdocs/js/external/

mkdir -p $dist/htdocs/css && cp \
  node_modules/font-awesome/css/font-awesome.min.css \
  node_modules/@mdi/font/css/materialdesignicons.min.css \
  node_modules/jquery-ui-dist/jquery-ui.min.css \
  node_modules/jquery-datetimepicker/build/jquery.datetimepicker.min.css \
  node_modules/pixl-webapp/css/base.css \
 $dist/htdocs/css/

mkdir -p $dist/htdocs/fonts && cp \
 node_modules/font-awesome/fonts/* \
 node_modules/@mdi/font/fonts/*.woff \
 node_modules/pixl-webapp/fonts/*.woff \
 $dist/htdocs/fonts/

# code mirror css

cat \
	node_modules/codemirror/lib/codemirror.css \
	node_modules/codemirror/theme/darcula.css \
	node_modules/codemirror/theme/solarized.css \
	node_modules/codemirror/theme/gruvbox-dark.css \
	node_modules/codemirror/addon/scroll/simplescrollbars.css \
	node_modules/codemirror/addon/display/fullscreen.css \
	node_modules/codemirror/addon/lint/lint.css \
	node_modules/codemirror/addon/fold/foldgutter.css \
  >  $dist/htdocs/css/codemirror.css

# codemirror js
cat \
	 node_modules/codemirror/lib/codemirror.js \
	 node_modules/codemirror/addon/scroll/simplescrollbars.js \
	 node_modules/codemirror/addon/edit/matchbrackets.js \
	 node_modules/codemirror/addon/selection/active-line.js \
	 node_modules/codemirror/addon/fold/foldgutter.js \
	 node_modules/codemirror/addon/fold/foldcode.js \
	 node_modules/codemirror/addon/fold/brace-fold.js \
	 node_modules/codemirror/addon/fold/indent-fold.js \
	 node_modules/codemirror/mode/powershell/powershell.js \
	 node_modules/codemirror/mode/javascript/javascript.js \
	 node_modules/codemirror/mode/python/python.js \
	 node_modules/codemirror/mode/perl/perl.js \
	 node_modules/codemirror/mode/shell/shell.js \
	 node_modules/codemirror/mode/groovy/groovy.js \
	 node_modules/codemirror/mode/clike/clike.js \
	 node_modules/codemirror/mode/properties/properties.js \
	 node_modules/codemirror/addon/display/fullscreen.js \
	 node_modules/codemirror/mode/xml/xml.js \
	 node_modules/codemirror/mode/sql/sql.js \
   node_modules/js-yaml/dist/js-yaml.js \
	 node_modules/codemirror/addon/lint/lint.js \
	 node_modules/codemirror/addon/lint/json-lint.js \
	 node_modules/codemirror/addon/lint/yaml-lint.js \
	 node_modules/codemirror/addon/mode/simple.js \
	 node_modules/codemirror/mode/dockerfile/dockerfile.js \
	 node_modules/codemirror/mode/toml/toml.js \
	 node_modules/codemirror/mode/yaml/yaml.js \
	 node_modules/codemirror/addon/comment/comment.js \
   node_modules/jsonlint-mod/lib/jsonlint.js \
   | esbuild --log-level=$ESBuildLogLevel $minify >  $dist/htdocs/js/codemirror.min.js

cat \
  node_modules/pixl-webapp/js/md5.js \
  node_modules/pixl-webapp/js/oop.js \
  node_modules/pixl-webapp/js/xml.js \
  node_modules/pixl-webapp/js/tools.js \
  node_modules/pixl-webapp/js/datetime.js \
  node_modules/pixl-webapp/js/page.js \
  node_modules/pixl-webapp/js/dialog.js \
  node_modules/pixl-webapp/js/base.js \
  | esbuild --log-level=$ESBuildLogLevel $minify --keep-names >  $dist/htdocs/js/common.min.js

cat htdocs/js/app.js \
  htdocs/js/pages/Base.class.js \
  htdocs/js/pages/Home.class.js \
  htdocs/js/pages/Login.class.js \
  htdocs/js/pages/Schedule.class.js \
  htdocs/js/pages/History.class.js \
  htdocs/js/pages/JobDetails.class.js \
  htdocs/js/pages/MyAccount.class.js \
  htdocs/js/pages/Admin.class.js \
  htdocs/js/pages/admin/Categories.js \
  htdocs/js/pages/admin/Servers.js \
  htdocs/js/pages/admin/Users.js \
  htdocs/js/pages/admin/Plugins.js \
  htdocs/js/pages/admin/Activity.js \
  htdocs/js/pages/admin/APIKeys.js \
  htdocs/js/pages/admin/ConfigKeys.js \
  htdocs/js/pages/admin/Secrets.js \
  | esbuild --log-level=$ESBuildLogLevel $minify --keep-names >  $dist/htdocs/js/combo.min.js

cp htdocs/index-bundle.html  $dist/htdocs/index.html

writehead "Bundle storage-cli and event plugins"

esbuild --bundle --log-level=$ESBuildLogLevel $minify --platform=node --outdir=$dist/bin/ \
 --external:../conf/config.json --external:../conf/storage.json --external:../conf/setup.json \
bin/storage-cli.js

esbuild --bundle --log-level=$ESBuildLogLevel $minify --platform=node --outdir=$dist/bin/  bin/shell-plugin.js
esbuild --bundle --log-level=$ESBuildLogLevel $minify --platform=node --outdir=$dist/bin/  bin/test-plugin.js
esbuild --bundle --log-level=$ESBuildLogLevel $minify --platform=node --outdir=$dist/bin/  bin/url-plugin.js
esbuild --bundle --log-level=$ESBuildLogLevel $minify --platform=node --outdir=$dist/bin/  --loader:.node=file bin/ssh-plugin.js
esbuild --bundle --log-level=$ESBuildLogLevel $minify --platform=node --outdir=$dist/bin/  bin/workflow.js
esbuild --bundle --log-level=$ESBuildLogLevel $minify --platform=node --outdir=$dist/bin/  bin/run-detached.js

writehead "Building Storage Engines"

printf "    - bundling FS Engine\n"
esbuild --bundle --log-level=$ESBuildLogLevel $minify --platform=node --outdir=$dist/bin/engines engines/Filesystem.js

if [ "$s3" = 1 ]; then
   printf "    - bundling S3 Engine\n"
   npm i @aws-sdk/client-s3 @aws-sdk/lib-storage --no-save --loglevel silent 
   esbuild --bundle --log-level=$ESBuildLogLevel $minify --platform=node --outdir=$dist/bin/engines engines/S3.js
fi

if [ "$level" = 1 ]; then
   printf "    - bundling Level Engine\n"
   npm i level --no-save --loglevel silent 
   esbuild --bundle --log-level=$ESBuildLogLevel $minify --platform=node --outdir=$dist/bin/engines engines/Level.js
   mkdir -p $dist/bin/engines/prebuilds/
   cp -r node_modules/classic-level/prebuilds/linux-x64 $dist/bin/engines/prebuilds/
fi

if [ "$lmdb" = 1 ]; then
   printf "    - bundling Lmdb Engine*\n"
   esbuild --bundle --log-level=$ESBuildLogLevel $minify --platform=node --outdir=$dist/bin/engines --external:lmdb engines/Lmdb.js 
fi

if [ "$sftp" = 1 ]; then
   printf "    - bundling Sftp Engine\n"
   npm i ssh2-sftp-client --no-save --loglevel silent 
   esbuild --bundle --log-level=$ESBuildLogLevel $minify --platform=node --loader:.node=file --outdir=$dist/bin/engines engines/Sftp.js
fi

if [ "$sql" = 1 ]; then
   printf "    - bundling SQL Engine [mysql/postgres]\n"
   npm i knex pg pg-query-stream mysql2 --no-save --loglevel silent
   esbuild --bundle --log-level=$ESBuildLogLevel $minify --platform=node --external:oracledb --external:sqlite3 \
     --external:mysql  --external:tedious --external:pg-native --external:better-sqlite3  \
     --outdir=$dist/bin/engines engines/SQL.js
fi

if [ "$redis" = 1 ]; then
   printf "    - bundling Redis Engine \n"
   npm i redis@3.1.2 --no-save --loglevel silent 
   esbuild --bundle --log-level=$ESBuildLogLevel $minify --platform=node --outdir=$dist/bin/engines engines/Redis.js
fi


# --- CRONICLE.JS
writehead "Bundling cronicle.js"
esbuild --bundle --log-level=$ESBuildLogLevel $minify --keep-names --platform=node --outfile=$dist/bin/cronicle.js lib/main.js

writehead "Applyig some patches"
# fix formidable 
esbuild --bundle --log-level=$ESBuildLogLevel $minify --keep-names --platform=node --outdir=$dist/bin/plugins node_modules/formidable/src/plugins/*.js

# --- setup configs on the initial run
if [ ! -d $dist/conf ]; then
  writehead "Setting up initial configs"
  cp -r sample_conf/  $dist/conf
  rm -rf $dist/conf/examples
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 > $dist/conf/secret_key
  chmod 400 $dist/conf/secret_key
fi


# ---- set up npm pac in dist if not yet, add some deps if needed
cd $dist
if [ ! -e 'package.json' ]; then 
  writehead "Setting up npm package in $dist"
   npm init -y &>/dev/null
   npm pkg set scripts.start="bin/manager"
fi

if [ "$lmdb" = 1 ]; then
  npm i lmdb --loglevel silent
fi 

cd - &>/dev/null

  

# ------  clean up 
writehead "Final cleanup"
rm -rf $dist/bin/cronicled.init $dist/bin/debug.sh $dist/bin/install.js $dist/bin/build.js $dist/bin/build-tools.js $dist/bin/manager.bat $dist/bin/win-*
chmod -R 755 $dist/bin


# -------------------- we are done 

# if in dev mode, start cronicle on background in manager mode
if [ "$restart" = 1 ]; then
  writehead "Starting cronicle..."
  export CRONICLE_dev_version="1.x.dev-$(date '+%Y-%m-%d %H:%M:%S')"
  ./$dist/bin/cronicle.js --manager
  echo "    - new process: $(cat $dist/logs/cronicled.pid)"
  echo "    - dev version: $CRONICLE_dev_version"
  exit 0  
fi

echo "-------------------------------------------------------------------------------------------------------------------------------------------"
echo "Bundle is ready: $(readlink -f $dist)"
if [ "$sql" = 1 ]; then
  echo " - SQL Engine is bundled for mysql and postgress only. SQLite, MSSQL Oracle need to be installed separetly in $dist"
fi 
if [ "$lmdb" = 1 ]; then
  echo " - Lmdb cannot be fully bundeled. Lmdb package was installed in $dist"
fi 
if [ "$level" = 1 ]; then
  echo " - If not running this on linux, copy OS proper binary from node_modules/classic-level/prebuilds to $dist/bin/engines/prebuilds/"
fi 

cat << EOF
Before you begin:
 - Configure you storage engine setting in conf/config.json || conf/storage.json || CRONICLE_storage_config=/path/to/custom/storage.json
 - Set you Secret key in conf/congig.json || conf/secret_key file || CRONICLE_secret_key_file || CRONICLE_secret_key env variables

To setup cronicle storage (on the first run):
 node ./$dist/bin/storage-cli.js setup

Start as manager in foreground:
 node ./$dist/bin/cronicle.js --echo --foreground --manager --color

Or  both together: ./$dist/bin/manager

-------------------------------------------------------------------------------------------------------------------------------------------

To reinstall/upgrade run (please back up $(readlink -f $dist) ):
 ./bundle.sh $dist -f
EOF
