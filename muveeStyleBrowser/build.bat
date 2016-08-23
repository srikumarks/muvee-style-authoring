@echo off
echo Creating temp directory ..
mkdir temp
echo Creating exe ..
mzc --gui-exe temp\muveeStyleBrowser.exe --ico icons\msb.ico muveeStyleBrowser.ss
echo Creating package directory ..
mzc --exe-dir temp\muveeStyleBrowser temp\muveeStyleBrowser.exe
echo Copying icons ..
mkdir temp\muveeStyleBrowser\icons
copy icons\128x128.png temp\muveeStyleBrowser\icons
copy icons\128x128a.xbm temp\muveeStyleBrowser\icons
copy icons\16x16.png temp\muveeStyleBrowser\icons
echo Creating archive ..
pushd temp
zip -r muveeStyleBrowser.zip muveeStyleBrowser
popd
echo Done!
echo Result = temp\muveeStyleBrowser.zip
 
