echo "Temporarily ignore localization using preGenCommand.sh and postGenCommand.sh, please remove this script later"
[ ! -f src ] || rm -rf p2p_wallet/Base.lproj
[ ! -f src ] || rm -rf p2p_wallet/en.lproj
[ ! -f src ] || rm -rf p2p_wallet/ru.lproj
[ ! -f src ] || rm -rf p2p_wallet/fr.lproj
[ ! -f src ] || rm -rf p2p_wallet/vi.lproj

[ ! -f src ] || mv p2p_wallet/Base.lproj-backup p2p_wallet/Base.lproj
[ ! -f src ] || mv p2p_wallet/en.lproj-backup p2p_wallet/en.lproj
[ ! -f src ] || mv p2p_wallet/ru.lproj-backup p2p_wallet/ru.lproj
[ ! -f src ] || mv p2p_wallet/fr.lproj-backup p2p_wallet/fr.lproj
[ ! -f src ] || mv p2p_wallet/vi.lproj-backup p2p_wallet/vi.lproj