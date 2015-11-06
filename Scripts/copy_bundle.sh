
if [ $CONFIGURATION == Release ]; then
echo "skip for release"
else
echo "Copy $BUILT_PRODUCTS_DIR/${TARGET_NAME}.bundle to $SRCROOT"
cp -R $BUILT_PRODUCTS_DIR/${TARGET_NAME}.bundle $SRCROOT/
fi
