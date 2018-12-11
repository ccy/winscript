# wim2vhdx

Create a bootable Windows VHDX file from [WIM](https://en.wikipedia.org/wiki/Windows_Imaging_Format) or [ESD](https://www.lifewire.com/esd-file-2621103) file.

List available disk images in a WIM file:

    dism /Get-ImageInfo /ImageFile:d:\sources\install.wim

Show detail information of a disk image: 

    dism /get-imageinfo /ImageFile:d:\sources\install.wim /index:1

Create a new vhdx file with windows installation disk image index 2:

    wim2vhdx.cmd -f c:\mywim.vhdx -w d:\sources\install.wim  -i 2

Boot from Windows in VHDX partition mount to drive E and physical hard disk's boot partition mount to drive F:

    bcdboot e:\windows /s f: /f uefi