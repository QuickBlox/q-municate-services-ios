echo "Begin momd for $3"
CORE_DATA_DIRECTORY="${PROJECT_DIR}/$3/CoreData"

COREDATA_DIR="${CORE_DATA_DIRECTORY}"
HUMAN_DIR="${CORE_DATA_DIRECTORY}/Entries"
MACHINE_DIR="${CORE_DATA_DIRECTORY}/EntriesMachine"
INCLUDE_H="${CORE_DATA_DIRECTORY}/$1"
INPUT_FILE_PATH="${CORE_DATA_DIRECTORY}/$2"

echo "${INPUT_FILE_PATH}/.xccurrentversion"

curVer=`/usr/libexec/PlistBuddy "${INPUT_FILE_PATH}/.xccurrentversion" -c 'print _XCCurrentVersionName'`

mogenerator=/usr/bin/mogenerator

if [ ! -f $mogenerator ]; then
mogenerator=/usr/local/bin/mogenerator
fi

echo $mogenerator --model \"$COREDATA_DIR/$curVer\" --machine-dir "$MACHINE_DIR/" --human-dir "$HUMAN_DIR/" --includeh "$INCLUDE_H" --template-var arc=true
$mogenerator --model "${INPUT_FILE_PATH}/$curVer" --machine-dir "$MACHINE_DIR/" --human-dir "$HUMAN_DIR/" --includeh "$INCLUDE_H" --template-var arc=true

echo "Begin mom for $3"

echo $mogenerator --model \"${INPUT_FILE_PATH}\" --machine-dir "$MACHINE_DIR/" --human-dir "$HUMAN_DIR/" --includeh "$INCLUDE_H" --template-var arc=true
$mogenerator --model \"${INPUT_FILE_PATH}\" --machine-dir "$MACHINE_DIR/" --human-dir "$HUMAN_DIR/" --includeh "$INCLUDE_H" --template-var arc=true

echo "that's all folks. mogen.sh is done"
