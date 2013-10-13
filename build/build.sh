#!/bin/bash
set -e

#Setup arguments
RESULTS_FOLDER="results"
if [ $# == 0 ]; then
	VERSION=bleedingEdge
else
	VERSION=$1
fi


#Work in temporal directory
if [ -a $RESULTS_FOLDER ]; then
		echo "cannot create directory named \""$RESULTS_FOLDER"\": file already exists"
		exit 1
fi

mkdir $RESULTS_FOLDER
cd $RESULTS_FOLDER

#Load image for this project

wget -O - get.pharo.org/20+vm | bash
./pharo Pharo.image save MetatalkBootstrap --delete-old



#Load stable version of the monticello configuration, according to this git sources
REPO=http://smalltalkhub.com/mc/Guille/Seed/main
./pharo MetatalkBootstrap.image config $REPO ConfigurationOfHazelnut --install=$VERSION

echo "Configuration Loaded. Opening script..."

echo -e "
Workspace openContents: '\"I am a builder for a Metatalk base level system. I bootstrap the system using an object space. You configure myself by providing mi a kernelSpec, and sending me the message #buildKernel.\"

\"Load a seed from the folder of the downloaded sources\"
baseLevel := MttSeed new
    fromDirectoryNamed: ''../source/BaseLevel'';
    buildSeed.
	
metaLevel := MttSeed new
	parent: baseLevel;
   fromDirectoryNamed: ''../source/MetaLevel'';
   buildSeed.

\"Create an object space that will use an AST evaluator to run some code\"
objectSpace := AtObjectSpace new.
objectSpace worldConfiguration: MttMetatalk world.
objectSpace interpreter: (AtASTEvaluator new codeProvider: baseLevel, metaLevel; yourself).
objectSpace mirrorFactory: MttMirrorFactory new.
objectSpace methodDictionaryBuilder: MttMethodDictionaryMirror.

\"Create a builder, and tell it to bootstrap. Voila, the objectSpace will be full\"
builder := MttBaseLevelBuilder new.
builder objectSpace: objectSpace.
builder kernelSpec: baseLevel.
builder buildKernel.
process := objectSpace createProcessWithPriority: 3 doing: MttMetatalk world baseLevelValidation.
objectSpace installAsActiveProcess: process.

\"Create a builder, and tell it to bootstrap. Voila, the objectSpace will be full of mirrors\"
builder := MttMetaLevelBuilder new.
builder objectSpace: objectSpace.
builder metaLevelSpec: metaLevel.
builder baseLevelSpec: baseLevel.
builder buildKernel.

process := objectSpace createProcessWithPriority: 3 doing: MttMetatalk world baseLevelValidation.
process := objectSpace createProcessWithPriority: 3 doing: MttMetatalk world metaLevelValidation.

objectSpace installAsActiveProcess: process.


''metatalk.image'' asFileReference ensureDeleted.
objectSpace serializeInFileNamed: ''metatalk.image''.

\"Browse me\"
objectSpace browse.'.
Smalltalk snapshot: true andQuit: true." > ./script.st

./pharo MetatalkBootstrap.image script.st
rm script.st
rm PharoDebug.log
echo "Script created and loaded. Finished! :D"