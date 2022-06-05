echo "Temporarily ignore localization using preGenCommand.sh and postGenCommand.sh, please remove this script later"
rm -rf p2p_wallet/Base.lproj
rm -rf p2p_wallet/en.lproj
rm -rf p2p_wallet/ru.lproj
rm -rf p2p_wallet/fr.lproj
rm -rf p2p_wallet/vi.lproj

mv p2p_wallet/Base.lproj-backup p2p_wallet/Base.lproj
mv p2p_wallet/en.lproj-backup p2p_wallet/en.lproj
mv p2p_wallet/ru.lproj-backup p2p_wallet/ru.lproj
mv p2p_wallet/fr.lproj-backup p2p_wallet/fr.lproj
mv p2p_wallet/vi.lproj-backup p2p_wallet/vi.lproj