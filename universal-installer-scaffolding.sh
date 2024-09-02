#!/bin/bash



if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be ran as root!";
    exit 1;
fi


echo " ---SCAFFOLDING STARTED! :: STEP 1/5: SETTINGS---";

if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME="ghostland"
    DF_PROJECT_NAME="  (default)"
fi

if [ -z "$SCRIPT_NAME" ]; then
    SCRIPT_NAME="scripts/guzios-magic-sauce"
    DF_SCRIPT_NAME="  (default)"
fi

if [ -z "$INSTALL_PATH" ]; then
    INSTALL_PATH="/bin/minecraft"
    DF_INSTALL_PATH="  (default)"
fi

if [ -z "$NON_INTERACTIVE_HAPPY_PATH" ]; then
    NON_INTERACTIVE_HAPPY_PATH="NO"
else
    NON_INTERACTIVE_HAPPY_PATH="YES"
fi

if [ -z "$GITHUB" ]; then
    if [ -z "$GIT" ]; then
        STRATEGY="ARCHIVE"
        if [ -z "$SOURCE" ]; then
            REPORTED_SOURCE="ARCHIVE"
        else
            REPORTED_SOURCE="ARCHIVE // DOWNLOAD FROM: $SOURCE"
            if [ "$SOURCE" == "EXPECT" ]; then
                REPORTED_SOURCE="ARCHIVE // EXPECT PRESENT"
            fi
        fi
    else
        STRATEGY="GIT"
        REPORTED_SOURCE="GIT: $GIT"
    fi
else
    STRATEGY="GITHUB"
    REPORTED_SOURCE="GITHUB: $GITHUB"
fi

mkdir -p "/var/spectre";
mkdir "/var/spectre/$PROJECT_NAME";

if [ $? -ne 0 ]; then
    echo "ERROR: It would appear as though \`$PROJECT_NAME\` already exists"
    echo "or /var/spectre is unwriteable. See above for more info.";
    exit 1;
fi

cd /var/spectre || exit;


echo "  > Version: 0.2";
echo "  > Project name: $PROJECT_NAME $DF_PROJECT_NAME";
echo "  > Source: $REPORTED_SOURCE";
echo "  > Running from: $(pwd)";
echo "  > Post-scaffold script name: $SCRIPT_NAME $DF_SCRIPT_NAME";
echo "  > Installed binary path: $INSTALL_PATH $DF_INSTALL_PATH";
echo "  > Make the script's happy-path fully non-interactive: $NON_INTERACTIVE_HAPPY_PATH";

sleep 3;
echo;
echo " ---STEP 2/5: OBTAINING THE FILES USING...---";
if [ "$STRATEGY" == "ARCHIVE" ]; then
    echo "...the \`ARCHIVE\` strategy.";
    if [ -e "$PROJECT_NAME.zip" ]; then
        echo "File already found. Great! Moving on.";
    else
        echo "$(pwd)/$PROJECT_NAME.zip not found. According to your settings, we now should...";

        if [ "$SOURCE" == "EXPECT" ]; then
            echo "...crash the script, because it should be there.";
            exit 1;
        fi

        if [ -z "$SOURCE" ]; then
            echo "...wait until it appears.";
            chmod --verbose 777 .;
            echo "AWAITING FOR: $(pwd)/$PROJECT_NAME.zip...";
            echo "";
            echo "Now's the time to ask your friend to \`scp\` project files in there, or";
            echo "do it yourself if you can, or just \`cp\` them, if they're on device already.";
            echo "";
            echo "For your conveinience, we temproarily made $(pwd) freely accessible.";
            echo "This is very useful for tools that can't operate as root, but can cause";
            echo "security problems, should you decide to cancel this operation.";
            echo "Plese press ANY SINGLE KEY to cancel instead of using Ctrl+C,";
            echo "or remember to do \`chmod 555 $(pwd)\` if you use Ctrl+C.";
            while [ ! -e "$PROJECT_NAME.zip" ]; do
                read -r -n 1 -s -t 1;
                if [ $? -eq 0 ]; then
                    chmod --verbose 555 .;
                    echo "NOTE: Safely cancelled.";
                    exit 0;
                fi
            done
            echo "File found!";
            chmod --verbose 555 .;
            echo "NOTE: $(pwd) is secure again";
        else
            echo "...download it from $SOURCE.";
            wget "$SOURCE";
            if [ -e "$PROJECT_NAME.zip" ]; then
                echo "Download succesful!";
            else
                echo "ERROR: \`wget\` finnished running, but the $PROJECT_NAME.zip file";
                echo "doesn't seem to exist. Cannot operate. See above for more info.";
                exit 1;
            fi
        fi

        echo;
        echo " ---STEP 2a/5b: UNZIPPING---";
        sleep 1;
        unzip "$PROJECT_NAME.zip";
        if [ $? -ne 0 ]; then
            echo "ERROR: Unzip failed. See above for more info.";
            exit 1;
        fi

        echo;
        echo " ---STEP 2b/5b: CLEANUP---";
        rm --verbose "$PROJECT_NAME.zip";
        if [ $? -ne 0 ]; then
            echo "NOTE: Couldn't clean up. This is non-critical,";
            echo "but you'll need to remember to manually remove:";
            echo "$(pwd)/$PROJECT_NAME.zip";
            echo "Press any key to continue...";
            read -r -n 1 -s;
        fi
        chmod --verbose 777 "$(pwd)/$PROJECT_NAME/$SCRIPT_NAME.sh";
    fi
fi

if [ "$STRATEGY" == "GITHUB" ]; then
    echo "...the \`GITHUB\` strategy.";
    gh repo clone "$GITHUB" "$PROJECT_NAME";
    if [ $? -ne 0 ]; then
        echo "ERROR: GitHub operation failed. See above for more info.";
        exit 1;
    fi
fi

if [ "$STRATEGY" == "GIT" ]; then
    echo "...the \`GIT\` strategy.";
    git clone "$GIT" "$PROJECT_NAME";
    if [ $? -ne 0 ]; then
        echo "ERROR: Git operation failed. See above for more info.";
        exit 1;
    fi
fi

sleep 3;
echo;
echo " ---STEP 3/5: SEDDING---";
sed -i -e "s/%INSTALL_PATH%/$INSTALL_PATH/g" "./$PROJECT_NAME/$SCRIPT_NAME.sh";
if [ $? -ne 0 ]; then
    echo "SED operation failed! Couldn't set %INSTALL_PATH% to $INSTALL_PATH.";
    echo "Nevertheless, scaffolding is already done, so the script will now exit.";
    echo "";
    echo "However, if you want to install the newly-scaffolded script, you need to:";
    echo "  - Change %INSTALL_PATH% into $INSTALL_PATH in \`$(pwd)/$PROJECT_NAME/$SCRIPT_NAME.sh\`.";
    echo "  - Run the command \`sudo $(pwd)/$PROJECT_NAME/$SCRIPT_NAME.sh install\`.";
    exit 1;
fi
echo "SED operation done. Changed %INSTALL_PATH% to $INSTALL_PATH, or it was set already / never existed in the 1st place.";

sleep 3;
echo;
echo " ---STEP 4/5: TEST---";
echo "Checking if everything went according to plan by running:";
echo "\$ ./$PROJECT_NAME/$SCRIPT_NAME.sh help";
sleep 3;
echo;
echo "----------------------------";
"./$PROJECT_NAME/$SCRIPT_NAME.sh" help;
if [ $? -ne 0 ]; then
    echo "----------------------------";
    echo;
    echo "ERROR: It would appear as though something went wrong. See above for more info.";
    exit 1;
fi
echo "----------------------------";

sleep 3;
echo;
echo " ---STEP 5/5: INSTALL---";
echo "If you can see \`help\` output above - good news!";
echo "Scaffolding completed successfully! One more thing left:";
echo "\$ ./$PROJECT_NAME/$SCRIPT_NAME.sh install";
echo "The aforementioned command will run the actual installer.";
echo "Press any key to execute it...";
echo "(Or Ctrl+C to leave it ready-to-install, but not installed.)";
if [ "$NON_INTERACTIVE_HAPPY_PATH" == "YES" ]; then
    echo "SIKE! No keypress needed - it will be simulated in 5s. This happy-path is fully non-interactive.";
    sleep 5;
else
    read -r -n 1 -s;
fi
echo;
echo;
echo "KEYPRESS DETECTED - BOOTING UP THE INSTALLER...";
echo;
"./$PROJECT_NAME/$SCRIPT_NAME.sh" install;
exit;