@echo off
python %~dp0../../scripts/flasher.py -f espHome_SmartStation.yaml.j2 -a run --local
pause