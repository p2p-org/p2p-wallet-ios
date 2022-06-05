echo "Temporarily ignore localization using preGenCommand.sh and postGenCommand.sh, please remove this script later"
rm -rf p2p_wallet/Resources/Base.lproj-backup
rm -rf p2p_wallet/Resources/en.lproj-backup
rm -rf p2p_wallet/Resources/ru.lproj-backup
rm -rf p2p_wallet/Resources/fr.lproj-backup
rm -rf p2p_wallet/Resources/vi.lproj-backup

mv p2p_wallet/Resources/Base.lproj p2p_wallet/Resources/Base.lproj-backup
mv p2p_wallet/Resources/en.lproj p2p_wallet/Resources/en.lproj-backup
mv p2p_wallet/Resources/ru.lproj p2p_wallet/Resources/ru.lproj-backup
mv p2p_wallet/Resources/fr.lproj p2p_wallet/Resources/fr.lproj-backup
mv p2p_wallet/Resources/vi.lproj p2p_wallet/Resources/vi.lproj-backup