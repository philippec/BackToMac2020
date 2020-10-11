#!/bin/sh

DESTINATION_PATH=
APP_NAME="Camera On Top"
BUNDLE_ID="com.casgrain.Camera-On-Top"
API_KEY="9M2NG5A5N6"
API_ISSUER="69a6de89-8818-47e3-e053-5b8c7c11a4d1"

function print_usage {
    echo "$0 [options: ho]"
    echo "-o <path> path to the folder with the application to notarize"
    echo "-h print this message"
}

# Validate the inputs

while getopts ":ho:" opt; do
    case "$opt" in
        "o")
            DESTINATION_PATH=$OPTARG
            ;;
        "h")
            print_usage
            exit 0
            ;;
        "?")
            echo "Unknown option $OPTARG"
            print_usage
            exit 1
            ;;
        ":")
            echo "No argument value for option $OPTARG"
            print_usage
            exit 1
            ;;
        *)
            print_usage
            exit 1
            ;;
    esac
done

shift $(($OPTIND - 1))

if [ $# -gt 0 ]; then
	print_usage
	exit 1
fi
if [ -z "$DESTINATION_PATH" ]; then
	print_usage
	exit 1
fi

# Find the first app in the destination path
ARCHIVE_NAME=
ARCHIVE_VERSION=
for ONE_FILE in "$DESTINATION_PATH/$APP_NAME.app"
do
  ARCHIVE_NAME="$ONE_FILE"
  ARCHIVE_VERSION=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$ONE_FILE/Contents/Info.plist"`
  echo "Found $ARCHIVE_NAME, version $ARCHIVE_VERSION"
  break
done

if [ -z "$ARCHIVE_NAME" ]; then
    echo "Unable to find an application in $DESTINATION_PATH"
	print_usage
	exit 1
fi

ARTIFACT_NAME=$(basename "$ARCHIVE_NAME")
echo "Compressing $ARTIFACT_NAME..."

/usr/bin/ditto -c -k --keepParent --sequesterRsrc "$ARCHIVE_NAME" "$ARCHIVE_NAME.zip"

echo "Sending $ARTIFACT_NAME to Apple's Notary service"

xcrun altool --notarize-app --file "$ARCHIVE_NAME.zip" --primary-bundle-id "$BUNDLE_ID" --apiKey "$API_KEY" --apiIssuer "$API_ISSUER" --output-format xml | tail -n +2 > upload.plist
if [ $? -ne 0 ]; then
    echo "Error sending application, unable to notarize"
    cat upload.plist
    exit 1
fi

# Print the upload output to the console
plutil -p upload.plist

# Save the UUID to a variable
UUID=`/usr/libexec/PlistBuddy upload.plist -c "Print :notarization-upload:RequestUUID"`

echo "Upload UUID: $UUID"

echo "Waiting for Apple's Notary service"

function print_log {
    LOG_URL=`/usr/libexec/PlistBuddy $1 -c "Print :notarization-info:LogFileURL" ||true`
    if [ -n "$LOG_URL" ]; then
        echo "Log file content:"
        curl --silent "$LOG_URL" | python -mjson.tool
    else
        echo "No log file to print"
    fi
}

LOOPER=0
ERROR_RETRY_COUNT=0
MAX_ERROR_RETRY_COUNT=5
while [ $LOOPER -lt 1 ]; do
    echo "Sleeping for a minute"
    sleep 60
    echo "Fetching notarization information..."
    xcrun altool --notarization-info $UUID --apiKey "$API_KEY" --apiIssuer "$API_ISSUER" --output-format xml | tail -n +2 > wait.plist
    if [ $? -ne 0 ]; then
        echo "Error fetching notarization information, unable to notarize"
        plutil -p wait.plist
        print_log wait.plist
        if [ $ERROR_RETRY_COUNT -lt $MAX_ERROR_RETRY_COUNT ]; then
            ERROR_RETRY_COUNT=$((ERROR_RETRY_COUNT + 1))
            echo "Retry count $ERROR_RETRY_COUNT of $MAX_ERROR_RETRY_COUNT"
            continue
        else
            echo "Retry count exceeded, stopping the operation."
            exit 2
        fi
    fi
    plutil -p wait.plist
    STATUS=`/usr/libexec/PlistBuddy wait.plist -c "Print :notarization-info:Status"`
    echo "Status: $STATUS"
    if [ "$STATUS" = "in progress" ]; then
        echo "Waiting"
    elif [ "$STATUS" = "success" ]; then
        echo "Done"
        print_log wait.plist
        let LOOPER=1
    else
        echo "Unknown status $STATUS, unable to notarize"
        print_log wait.plist
        exit 3
    fi
done

echo "Stapling notarization certificate to $ARTIFACT_NAME"

xcrun stapler staple "$ARCHIVE_NAME"
if [ $? -ne 0 ]; then
    echo "Error stapling notarization certificate"
    exit 4
fi

echo "Verifying signature..."
spctl --verbose=4 --assess --type execute "$DESTINATION_PATH/$APP_NAME.app/"

echo "Notarization successful, cleaning up"
find "$DESTINATION_PATH" -depth 1 -not -name "*.app" -print -delete
rm upload.plist
rm wait.plist

VERSIONED_ARCHIVE_NAME="$APP_NAME"
VERSIONED_ARCHIVE_NAME+="_"
VERSIONED_ARCHIVE_NAME+="$ARCHIVE_VERSION"
echo "Re-compressing notarized application to $VERSIONED_ARCHIVE_NAME"
pushd "$DESTINATION_PATH"
ditto -ck --rsrc --sequesterRsrc --keepParent "$APP_NAME.app" "$VERSIONED_ARCHIVE_NAME.zip"
popd

echo "Notarization complete"
