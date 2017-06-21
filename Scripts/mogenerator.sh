
DIR=`basename ${PROJECT_DIR}`
CORE_DATA_DIRECTORY="${PROJECT_DIR}/${DIR}/CoreData"

COREDATA_DIR="${CORE_DATA_DIRECTORY}"
HUMAN_DIR="${CORE_DATA_DIRECTORY}/Entries"
MACHINE_DIR="${CORE_DATA_DIRECTORY}/EntriesMachine"
INCLUDE_H="${CORE_DATA_DIRECTORY}/$1Includes.h"
INPUT_FILE_PATH="${CORE_DATA_DIRECTORY}/$1.xcdatamodeld"

MOGENERATOR=/usr/bin/mogenerator
if [ ! -f $MOGENERATOR ]; then
  MOGENERATOR=/usr/local/bin/mogenerator
fi

if [ -f "${INPUT_FILE_PATH}/.xccurrentversion" ] ; then

  CURRENT_VERSION=`/usr/libexec/PlistBuddy \
  "${INPUT_FILE_PATH}/.xccurrentversion" \
  -c 'print _XCCurrentVersionName'`

  MODEL="${INPUT_FILE_PATH}/$CURRENT_VERSION"

else
  echo  "File \"${INPUT_FILE_PATH}/.xccurrentversion\" doesn't exists."
  MODEL="${INPUT_FILE_PATH}/$1".xcdatamodel
fi

echo "Model ${MODEL}"

MOGENERATOR_CALL="$MOGENERATOR
--model ${MODEL}
--machine-dir ${MACHINE_DIR}/
--human-dir ${HUMAN_DIR}/
 --includeh ${INCLUDE_H}
 --template-var arc=true
 --template-var literals=true
 --template-var modules=true"

echo ${MOGENERATOR_CALL}
eval ${MOGENERATOR_CALL}

echo "that's all folks. mogenerator.sh is done"
