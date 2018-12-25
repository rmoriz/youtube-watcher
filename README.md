# WARNING
- Proof of concept - DO NOT USE IN PRODUCTION!
- Violates all YouTube Terms of Use you can imagine.
- 0 tests, YOLO
- almost zero input validation, probably vulnerable to the easiest XML attacks.
- no mqtt persistence, detection of webhook duplets
- currently not able to differentiate between new live stream, update, upload or deletion event.

![diagram](dia.png?raw=true)
![example](youtube-watcher.gif?raw=true)


## Tools used

- Ruby 2.6 + a lot of gems
- [StreamLink](https://github.com/streamlink/streamlink)
- MQTT (Eclipse Mosquitto)
- Docker

## Why?

- record streams
- watch streams using VLC which plays in background (no modal shit, no ads)

## Which streams do you love?

- [Louis Rossmann LIVE board repair](https://www.youtube.com/channel/UC6nZlvfz4YWoBWbjiaYJA3g)
- [Teslabjorn Live](https://www.youtube.com/channel/UCD3YwI6vR9BSHufERd4sqwQ)
- [Paul Daniels](https://www.youtube.com/user/19PLD73) (board repair)
- [Jessa Jones (PhD) from iPad Rehab](https://www.youtube.com/channel/UCPjp41qeXe1o_lp1US9TpWA)
- [BigRigTravels](https://www.youtube.com/user/BigRigTravels)


## Misc

Diagram made with https://monodraw.helftone.com/
