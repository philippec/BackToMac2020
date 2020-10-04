#!/usr/bin/env bash

set -e
#set -v

SCRIPT_PATH=`cd \`dirname '$0'\`; pwd`
cd "$SCRIPT_PATH"

XCODEBUILD=/usr/bin/xcodebuild

# Folder containing the application workspace
APP_FOLDER="$SCRIPT_PATH/.."
BUILD_NUMBER=

# Test parameters
SDK=macosx
PROJECT_NAME="Camera On Top"
SCHEME="Camera On Top"
APP_NAME="Camera On Top"
DESTINATION="$APP_FOLDER/build"

function print_usage {
    echo "$0 [options: hn]"
    echo "-n <build number> Specify a CFBundleVersion"
    echo "-h print this message"
}

# Validate the inputs
while getopts ":n:h" opt; do
    case "${opt}" in
        "n")
            BUILD_NUMBER=$OPTARG
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

if [ $# -gt 1 ]; then
	print_usage
	exit 1
fi

echo "Updating build number..."
if [ -z "$BUILD_NUMBER" ]; then
    echo "Using build number from Info.plist"
else
    echo "Setting build number to '$BUILD_NUMBER'"
    /usr/libexec/PlistBuddy -c "set :CFBundleVersion $BUILD_NUMBER" "$APP_FOLDER/$APP_NAME/Info.plist"
fi

echo "Building application..."
"$XCODEBUILD" -sdk $SDK -project "$APP_FOLDER/$PROJECT_NAME.xcodeproj" -scheme "$SCHEME" -configuration Release install DSTROOT="$DESTINATION"

echo "Verifying signature..."
spctl --verbose=4 --assess --type execute "$DESTINATION/Applications/$APP_NAME.app/"
