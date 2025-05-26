use ffmpeg-build-script to create ffmpeg nvenc for owncast.

resource: https://github.com/markus-perl/ffmpeg-build-script

commands:
git clone https://github.com/markus-perl/ffmpeg-build-script

cd ffmpeg-build-script

./build-ffmpeg --enable-gpl-and-non-free --build 

once completed it will ask you to replace your binary folders. - NO
no need.. just say no here.

you just need "ffmpeg"

copy ffmpeg to folder of owncast.

example copy command:
cp /srv/mergerfs/data/root/downloads/ffmpeg-build-script/workspace/bin/ffmpeg /docker/owncast/ffmpeg/usr/local/bin

docker compose up -d

nvenc should be listed in application to be used now.
