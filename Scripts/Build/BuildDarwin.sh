#!/bin/bash

configureCMake() {

   cmake -S "${productRepoPath}" -B "${productBuildPath}" \
      -D CMAKE_PREFIX_PATH="${libQtPath};${openSSLPath}" \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_OSX_DEPLOYMENT_TARGET=10.12 \
      -D CMAKE_OSX_ARCHITECTURES=${platformArchitecture} \
      -D SYNERGY_ENTERPRISE=ON \
      -D SYNERGY_REVISION="${productRevision}" \
      || exit 1

}

buildApplication() {

   pushd "${productBuildPath}" || exit 1

      make -j || exit 1
      make install/strip || exit 1

      "${libQtPath}/bin/macdeployqt" "${productBuildPath}/bundle/Synergy.app" || exit 1

      rsync -av --delete "${productBuildPath}/bundle/Synergy.app/" "${binariesPath}/${productName}.app/" || exit 1

   popd

}

buildDMG() {

   ln -s /Applications "${productBuildPath}/bundle/Applications"

   if [ ${platformArchitecture} = 'arm64' ]; then
      codesign --force --deep --sign - "${binariesPath}/${productName}.app"
   fi

   hdiutil create -volname "${productName} ${productVersion}-${productStage}" -srcfolder "${productBuildPath}/bundle" -ov -format UDZO "${binariesPath}/${productPackageName}.dmg" || exit 1

}

set -o nounset

configureCMake
buildApplication
buildDMG

exit 0
