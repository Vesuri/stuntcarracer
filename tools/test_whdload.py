#!/usr/bin/env python3
"""Boot a host-built slave in FS-UAE and retain WHDLoad dumps for inspection."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--disk', required=True, type=Path, help='Original PAL or Quartex Disk.1')
    p.add_argument('--workbench', required=True, type=Path, help='Workbench boot ADF with C: and Libs:')
    p.add_argument('--kickstart', required=True, type=Path)
    p.add_argument('--emulator', default=str(Path.home()/'.local/fs-uae/fs-uae'))
    p.add_argument('--whdload', type=Path, default=Path.home()/'.local/share/amiga/WHDLoad/C/WHDLoad')
    p.add_argument('--ntsc', action='store_true')
    p.add_argument('--custom2', action='store_true', help='Enable TNT tracks')
    p.add_argument('--custom3', action='store_true', help='Enable enhanced graphics')
    p.add_argument('--no-preload', action='store_true')
    p.add_argument('--ticks', type=int, default=1000)
    p.add_argument('--seconds', type=int, default=90, help='Host safety timeout')
    args = p.parse_args()
    slave = 'StuntTrackRacer' if args.ntsc else 'StuntCarRacer'
    for path in (args.disk, args.workbench, args.kickstart, args.whdload, ROOT/'build'/(slave+'.slave')):
        if not path.is_file():
            p.error(f'Missing file: {path}')
    base = Path(tempfile.mkdtemp(prefix='whdload-test-', dir=ROOT/'build'))
    print('Fixture:', base, flush=True)
    boot, game = base/'boot', base/'game'
    for d in (boot/'s', game, base/'state'):
        d.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(args.whdload, game/'WHDLoad')
    shutil.copyfile(ROOT/'build'/(slave+'.slave'), game/(slave+'.slave'))
    shutil.copyfile(args.disk, game/'Disk.1')
    (boot/'s/WHDLoad.prefs').write_text('Expert\nReadDelay=0\n')
    options = ('PRELOAD ' if not args.no_preload else '')
    options += f'CUSTOM2={int(args.custom2)} CUSTOM3={int(args.custom3)}'
    (boot/'s/startup-sequence').write_text(
        'DF0:C/Assign C: DF0:C\nDF0:C/Assign LIBS: DF0:Libs\n'
        'Stack 16384\nFailAt 999\nCD DH1:\n'
        f'WHDLoad {slave}.slave {options} SPLASHDELAY=0 NOREQ COREDUMP FILELOG TIMEOUT={args.ticks} >DH0:result\n'
        'Echo done >DH0:done\n')
    with (base/'emulator.log').open('w') as log:
        emu = subprocess.Popen([args.emulator, '--amiga_model=A1200', '--cpu=68020',
            '--uae_cpu_model=68020', '--uae_cpu_24bit_addressing=false',
            '--jit_compiler=0', '--chip_memory=2048', '--fast_memory=8192',
            '--kickstart_file='+str(args.kickstart.resolve()),
            '--hard_drive_0='+str(boot), '--hard_drive_0_priority=10', '--hard_drive_1='+str(game),
            '--floppy_drive_0='+str(args.workbench.resolve()),
            '--ntsc_mode='+str(int(args.ntsc)),
            '--joystick_port_0=mouse', '--joystick_port_1=nothing', '--warp_mode=1',
            '--fullscreen=0', '--state_dir='+str(base/'state')], stdout=log, stderr=log)
        try:
            deadline = time.monotonic()+args.seconds
            while time.monotonic()<deadline and not (boot/'done').exists():
                if emu.poll() is not None:
                    raise RuntimeError(f'FS-UAE exited unexpectedly: {base}')
                time.sleep(.25)
            output = (boot/'result').read_text(errors='replace') if (boot/'result').exists() else ''
            report = (game/'.whdl_register').read_text(encoding='latin1') if (game/'.whdl_register').exists() else ''
            if not (boot/'done').exists() or 'DEBUG caused.' not in report:
                raise RuntimeError(f'No normal WHDLoad timed dump: {base}\n{output}\n{report}')
            if not (game/'.whdl_memory').is_file() or not (game/'.whdl_expmem').is_file():
                raise RuntimeError('Missing WHDLoad memory dumps')
            print(f'PASS: {slave} reached WHDLoad timeout without a reported exception; inspect retained display/game state.')
        finally:
            emu.terminate()
            try:
                emu.wait(timeout=5)
            except subprocess.TimeoutExpired:
                emu.kill()
                emu.wait()

if __name__ == '__main__':
    main()
