set VERSION=%DATE:~-4%.%DATE:~4,2%.%DATE:~7,2%
packer build -only=vmware_desktop -var version=$VERSION packer.json
