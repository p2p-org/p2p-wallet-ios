echo "Start remove localization script"

PATH="${SRCROOT}/p2p_wallet/Resources"

rm -r "$PATH/ru.lproj/Localizable.strings"
rm -r "$PATH/fr.lproj/Localizable.strings"
rm -r "$PATH/vi.lproj/Localizable.strings"

echo "Remove localization script completed"