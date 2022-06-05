echo "Temporarily ignore localization using preGenCommand.sh and postGenCommand.sh, please remove this script later"
rm -rf p2p_wallet/Base.lproj-backup
rm -rf p2p_wallet/en.lproj-backup
rm -rf p2p_wallet/ru.lproj-backup
rm -rf p2p_wallet/fr.lproj-backup
rm -rf p2p_wallet/vi.lproj-backup

mv p2p_wallet/Base.lproj p2p_wallet/Base.lproj-backup
mv p2p_wallet/en.lproj p2p_wallet/en.lproj-backup
mv p2p_wallet/ru.lproj p2p_wallet/ru.lproj-backup
mv p2p_wallet/fr.lproj p2p_wallet/fr.lproj-backup
mv p2p_wallet/vi.lproj p2p_wallet/vi.lproj-backup