#!/bin/bash
set -e

#Setup arguments
RESULTS_FOLDER="results"
if [ $# == 0 ]; then
	VERSION=stable
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
\"Load a seed from the folder of the downloaded sources\"
baseLevel := MttSeed new
    fromDirectoryNamed: '../source/BaseLevel';
    buildSeed.

\"Create an object space that will use an AST evaluator to run some code\"
objectSpace := AtObjectSpace new.
objectSpace worldConfiguration: MttMetatalk world.
objectSpace interpreter: (AtASTEvaluator new codeProvider: baseLevel; yourself).
objectSpace mirrorFactory: MttMirrorFactory new.
objectSpace methodDictionaryBuilder: MttMethodDictionaryMirror.

\"Create a builder, and tell it to bootstrap. Voilá, the objectSpace will be full\"
builder := MttBaseLevelBuilder new.
builder objectSpace: objectSpace.
builder kernelSpec: baseLevel.
builder buildKernel.

process := objectSpace createProcessWithPriority: 3 doing: MttMetatalk world baseLevelValidation.
objectSpace installAsActiveProcess: process.

objectSpace serializeInFileNamed: 'metatalk_baselevel.image'.
Smalltalk snapshot: false andQuit: true.
" > ./script.st

./pharo MetatalkBootstrap.image script.st
rm script.st
rm PharoDebug.log
echo "Script created and loaded. Finished! :D"