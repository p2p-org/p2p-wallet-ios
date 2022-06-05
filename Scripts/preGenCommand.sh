echo "Temporarily ignore localization using preGenCommand.sh and postGenCommand.sh, please remove this script later"
[ ! -f src ] || mv p2p_wallet/Base.lproj p2p_wallet/Base.lproj-backup
[ ! -f src ] || mv p2p_wallet/en.lproj p2p_wallet/en.lproj-backup
[ ! -f src ] || mv p2p_wallet/ru.lproj p2p_wallet/ru.lproj-backup
[ ! -f src ] || mv p2p_wallet/fr.lproj p2p_wallet/fr.lproj-backup
[ ! -f src ] || mv p2p_wallet/vi.lproj p2p_wallet/vi.lproj-backup