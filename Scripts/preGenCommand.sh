#-- Disable localization

echo "Temporarily ignore localization using preGenCommand.sh and postGenCommand.sh, please remove this script later"
rm -rf p2p_wallet/Resources/ru.lproj-backup
rm -rf p2p_wallet/Resources/fr.lproj-backup
rm -rf p2p_wallet/Resources/vi.lproj-backup

mv p2p_wallet/Resources/ru.lproj p2p_wallet/Resources/ru.lproj-backup
mv p2p_wallet/Resources/fr.lproj p2p_wallet/Resources/fr.lproj-backup
mv p2p_wallet/Resources/vi.lproj p2p_wallet/Resources/vi.lproj-backup

#-- Download and update xcconfig if needed

# check if XCCONFIG_URL exists
echo "Updating xcconfig..."
if [[ -z "${XCCONFIG_URL}" ]]; then
	# XCCONFIG_URL is not available
	echo "XCCONFIG_URL missing. Set this value: "
	echo "export XCCONFIG_URL=<Ask team leader for this value>"
	exit 1
else
	# for ci, there is already downloaded xcconfig in install.sh
	if [ "${IS_CI}" == "true" ]; then
		echo "Config.xcconfig has already been updated..."
	# if not ci, download the config file
	else
		curl -o ./p2p_wallet/Config.xcconfig ${XCCONFIG_URL}
	fi
fi