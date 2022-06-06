echo "Temporarily ignore localization using preGenCommand.sh and postGenCommand.sh, please remove this script later"
rm -rf p2p_wallet/Resources/ru.lproj
rm -rf p2p_wallet/Resources/fr.lproj
rm -rf p2p_wallet/Resources/vi.lproj

mv p2p_wallet/Resources/ru.lproj-backup p2p_wallet/Resources/ru.lproj
mv p2p_wallet/Resources/fr.lproj-backup p2p_wallet/Resources/fr.lproj
mv p2p_wallet/Resources/vi.lproj-backup p2p_wallet/Resources/vi.lproj

# install dependency
pod install