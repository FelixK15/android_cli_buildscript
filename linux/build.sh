#! /bin/bash

errorValue=1
successValue=0

function programIsInstalled()
{
    local programName=$1
    command -v "${programName}" &> /dev/null

    if [ $? -eq 0 ]
    then
        return $successValue
    fi

    return $errorValue
}

function installProgram()
{
    local programToInstall=${1}
    local programInstallCommand="apt-get -qq --assume-yes install ${programToInstall} &> /dev/null"
    eval ${programInstallCommand}
    
    local aptGetReturnValue=$?

    if [ $aptGetReturnValue -eq $errorValue ]
    then
        echo "   Couldn't install ${programToInstall}"
        return $errorValue
    fi

    return $successValue
}

function prequisitesNotMet()
{
    local user=$(whoami)
    if [ ${user} != "root" ]
    then
        echo "   Please run this script as root"
        return $successValue
    fi

    if ! programIsInstalled "apt-get";
    then
        echo "   'apt-get' is not installed but is a prerequisite. Please make sure that you have apt-get in one of your bin directories."
        return $successValue
    fi

    if ! installProgram "wget";
    then
        return $successValue
    fi

    if ! installProgram "unzip";
    then
        return $successValue
    fi

    return $errorValue
}

function getAndroidSDKPath()
{
    #FK: This path is arbitrarily chosen
    #    TODO: Check if there is a 'default' path for the android sdk
    local sdkVersion=$1
    local sdkPath="/usr/local/etc/android_sdk_${sdkVersion}"
    echo $sdkPath
}

function getAndroidSDKCommandLineToolsPath()
{
    local sdkVersion=$1
    local sdkPath=$(getAndroidSDKPath $sdkVersion)
    local sdkCommandLineToolPath="${sdkPath}/cmdline-tools"

    echo ${sdkCommandLineToolPath}
}

function getAndroidSDKCommandLineToolApplicationPath()
{
    local sdkVersion=$1
    local sdkCommandLineToolPath=$(getAndroidSDKCommandLineToolsPath $sdkVersion)
    local sdkManagerApplicationPath="${sdkPath}/cmdline-tools/bin/sdkmanager"

    echo ${sdkManagerApplicationPath}
}

function getAndroidSDKPlatformPath()
{
    local sdkVersion=$1
    local sdkPath=$(getAndroidSDKPath $sdkVersion)
    local sdkPlatformPath="${sdkPath}/platforms/android-${sdkVersion}"

    echo ${sdkPlatformPath}
}

function getAndroidSDKBuildToolsPath()
{
    local sdkVersion=$1
    local sdkPath=$(getAndroidSDKPath $sdkVersion)
    local sdkBuildToolsPath="${sdkPath}/build-tools/${sdkVersion}.0.0"

    echo ${sdkBuildToolsPath}
}

function getAndroidNDKPath()
{
    local sdkVersion=$1
    local ndkVersion=$2
    local sdkPath=$(getAndroidSDKPath $sdkVersion)
    local ndkPath="${sdkPath}/ndk/${ndkVersion}"

    echo ${ndkPath}
}

function noAndroidSDKManagerInstalled()
{
    local sdkVersion=$1
    local sdkCommandlineToolsPath=$(getAndroidSDKCommandLineToolsPath $sdkVersion)
    local sdkManagerPath="${sdkCommandlineToolsPath}/bin/sdkmanager"

    if programIsInstalled $sdkManagerPath;
    then
        return $errorValue
    fi

    return $successValue
}

function installAndroidSDKManager()
{
    local sdkVersion=$1
    local sdkPath=$(getAndroidSDKPath $sdkVersion)

    if ! [ -d $sdkPath ];
    then
        local createSDKPathCommand="mkdir ${sdkPath}"
        if ! eval $createSDKPathCommand;
        then
            echo "Couldn't create sdk path '${sdkPath}'"
            return $errorValue
        fi
    fi


    #FK: Change link at will. It used to be tied to the sdk version but apparently that changed :(
    local sdkCommandLineDownloadArchiveName="commandlinetools-linux-7583922_latest.zip"
    local sdkDownloadPath="https://dl.google.com/android/repository/${sdkCommandLineDownloadArchiveName}"
    local wgetSDKDownloadCommand="wget --quiet ${sdkDownloadPath}"

    echo "   Downloading android sdk command line tools for sdk version ${sdkVersion}..."
    if ! eval $wgetSDKDownloadCommand;
    then
        echo "   Couldn't download android sdk commandline tool using command '${wgetSDKDownloadCommand}'"
        return $errorValue
    fi

    echo "   Downloaded android sdk commandline tool archive '${sdkCommandLineDownloadArchiveName}"
    echo "   Trying to export android sdk commandline tool archive to ${sdkPath}..."

    local sdkArchiveExportCommand="unzip -o -q ${sdkCommandLineDownloadArchiveName} -d ${sdkPath}"
    if ! eval $sdkArchiveExportCommand;
    then
        echo "   Couldn't extract android sdk commandline tool archive using command '${sdkArchiveExportCommand}'"
        return $errorValue
    fi

    echo "   Finished exporting the android sdk commandline tool archive."
    
    echo "   Accepting SDK licenses..."
    local sdkManagerPath=$(getAndroidSDKCommandLineToolApplicationPath $sdkVersion)
    local sdkLicenseAgreementCommand="yes | ${sdkManagerPath} --sdk_root=${sdkPath} --licenses &> /dev/null"
    eval ${sdkLicenseAgreementCommand}
    
    return $successValue
}

function noAndroidSDKInstalled()
{
    local sdkVersion=$1
    local ndkVersion=$2
    local sdkPlatformPath=$(getAndroidSDKPlatformPath $sdkVersion)
    if ! [ -d $sdkPath ];
    then

        return $successValue
    fi

    local ndkPath=$(getAndroidNDKPath $sdkVersion $ndkVersion)
    if ! [ -d $ndkPath ];
    then
        return $successValue
    fi

    local sdkBuildTools=$(getAndroidSDKBuildToolsPath $sdkVersion)
    if ! [ -d $sdkBuildTools ];
    then
        return $successValue
    fi

    return $errorValue
}

function installAndroidSDK()
{
    local sdkVersion=$1
    local ndkVersion=$2
    local buildToolsVersion=${sdkVersion}.0.0

    local sdkPath=$(getAndroidSDKPath $sdkVersion)
    local sdkManager=$(getAndroidSDKCommandLineToolApplicationPath $sdkVersion)
    local installSDKPlatformCommand="${sdkManager} --sdk_root=${sdkPath} 'platforms;android-${sdkVersion}'"
    local installNDKCommand="${sdkManager} --sdk_root=${sdkPath} 'ndk;${ndkVersion}'"
    local installBuildToolsCommand="${sdkManager} --sdk_root=${sdkPath} 'build-tools;${buildToolsVersion}'"

    echo "   ... installing sdk platform ${sdkVersion}"
    eval ${installSDKPlatformCommand}

    echo
    echo "   ... installing ndk ${ndkVersion}"
    eval ${installNDKCommand}

    echo
    echo "   ... installing build-tools ${buildToolsVersion}"
    eval ${installBuildToolsCommand}

    return $successValue
}

function noJDKInstalled()
{
    local jdkVersion=$1
    if ! programIsInstalled "javac";
    then 
        return $successValue
    fi

    local javacVersion="$(javac --version)"
    local expectedVersion="javac ${jdkVersion}"

    if [ "$javacVersion" != "$expectedVersion" ];
    then
        return $successValue
    fi

    return $errorValue
}

function installJDK()
{
    local jdkVersion=$1
    local jdkPackageName="openjdk-${jdkVersion}-jdk-headless"
    
    echo "   Trying to install jdk version ${jdkVersion} using package '${jdkPackageName}'"
    if ! installProgram $jdkPackageName;
    then
        echo "   Couldn't install jdk package '${jdkPackageName}'."
        return $errorValue
    fi

    return $successValue
}

function checkPrerequisites()
{
    echo
    echo "Checking prequisites..."
    if prequisitesNotMet;
    then
        echo "Exiting build script because prequisites are not met"
        exit
    fi
    echo "... prerequisites are met!"
}

function checkCompiler()
{
    echo
    echo "Checking if gcc is installed..."
    if ! programIsInstalled "gcc";
    then
        echo "   Couldn't find gcc, trying to install"
        if ! installProgram "gcc";
        then
            echo "Exiting build script because gcc couldn't get installed"
            exit
        fi
    fi
    echo "... Found a gcc!"
}

function checkAndroidSDKManagerInstallation()
{
    local androidSDKVersion=$1

    echo
    echo "Check if Android SDK Manager ${androidSDKVersion} is installed..."
    if noAndroidSDKManagerInstalled $androidSDKVersion;
    then
        echo "   Couldn't find Android SDK Manager ${androidSDKVersion} installation"
        if ! installAndroidSDKManager $androidSDKVersion;
        then
            echo "Exiting build script because Android SDK Manager couldn't get installed"
            exit
        fi
    fi
    echo "... SDK Manager is installed!"
}

function checkAndroidSDKInstallation()
{
    local androidSDKVersion=$1
    local androidNDKVersion=$2

    echo
    echo "Check if Android SDK ${androidSDKVersion} and NDK ${androidNDKVersion} are installed..."
    if noAndroidSDKInstalled $androidSDKVersion $androidNDKVersion;
    then
        echo "   Couldn't find Android SDK ${androidSDKVersion} or NDK ${androidNDKVersion} installation"
        if ! installAndroidSDK $androidSDKVersion $androidNDKVersion;
        then
            echo "Exiting build script because Android SDK ${androidSDKVersion} coulnd't get installed"
            exit
        fi
    fi
    echo "... SDK ${androidSDKVersion} and NDK ${androidNDKVersion} are installed!"
}

function checkJDKInstallation()
{
    local jdkVersion=$1

    echo
    echo "Check if JDK ${jdkVersion} is installed..."
    if noJDKInstalled $jdkVersion;
    then 
        echo "   Couldn't find JDK ${jdkVersion} installation"
        if ! installJDK $jdkVersion;
        then 
            echo "Exiting build script because JDK couldn't get installed"
            exit
        fi
    fi
    echo "... JDK ${jdkVersion} is installed!"
}


#FK: Change these at will
#Note: run sdkmanager --list to see what version are available
androidSDKVersion="29"
androidNDKVersion="23.0.7599858"
jdkVersion="17"

#FK: This is the 'main'
checkPrerequisites
checkCompiler
checkAndroidSDKManagerInstallation $androidSDKVersion
checkAndroidSDKInstallation $androidSDKVersion $androidNDKVersion
checkJDKInstallation $jdkVersion