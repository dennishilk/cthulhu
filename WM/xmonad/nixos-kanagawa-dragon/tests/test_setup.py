"""Behavior checks; never write to the real home or system configuration."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

def run(script, *args, env=None):
    return subprocess.run(['bash', str(ROOT / script), *map(str, args)],
                          capture_output=True, text=True, env=env)

class Installation(unittest.TestCase):
    def test_fresh_install_and_rerun_preserve_marker(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(run('scripts/install-user.sh', d).returncode, 0)
            marker = Path(d, '.config/fastfetch/cthulhu-born')
            os.utime(marker, (1000000000, 1000000000))
            self.assertEqual(run('scripts/install-user.sh', d).returncode, 0)
            self.assertEqual(marker.stat().st_mtime, 1000000000)
            self.assertTrue(os.access(Path(d, '.local/bin/cthulhu-audio'), os.X_OK))
            self.assertFalse(Path(d, '.xinitrc').exists())
            for source in (ROOT / 'home').rglob('*'):
                if source.is_file():
                    self.assertEqual(source.read_bytes(), (Path(d) / source.relative_to(ROOT / 'home')).read_bytes())

    def test_conflict_is_detected_before_any_installation(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d, '.xmobarrc'); p.write_text('keep my bar')
            self.assertNotEqual(run('scripts/install-user.sh', d).returncode, 0)
            self.assertEqual(p.read_text(), 'keep my bar')
            self.assertEqual(list(Path(d).iterdir()), [p])

    def test_destination_symlink_is_refused(self):
        with tempfile.TemporaryDirectory() as d, tempfile.TemporaryDirectory() as outside:
            Path(d, '.config').symlink_to(outside, target_is_directory=True)
            self.assertNotEqual(run('scripts/install-user.sh', d).returncode, 0)
            self.assertEqual(list(Path(outside).iterdir()), [])

    def test_xdg_xmonad_precedence_is_reported(self):
        with tempfile.TemporaryDirectory() as d:
            Path(d, '.config/xmonad').mkdir(parents=True)
            self.assertNotEqual(run('scripts/install-user.sh', d).returncode, 0)
            self.assertFalse(Path(d, '.xmonad').exists())

class Helpers(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.folder = Path(self.tmp.name)
        self.log = self.folder / 'log'
        self.env = dict(os.environ, PATH=str(self.folder)+':'+os.environ['PATH'],
                        CTHULHU_TEST_LOG=str(self.log), CTHULHU_TEST_VOLUME='Volume: 0.50')
        for command, script in {
            'wpctl': 'if [ "$1" = get-volume ]; then printf "%s\\n" "$CTHULHU_TEST_VOLUME"; else printf "%s\\n" "$*" >> "$CTHULHU_TEST_LOG"; fi',
            'dunstify': 'printf "notify %s\\n" "$*" >> "$CTHULHU_TEST_LOG"',
            'feh': 'printf "feh %s\\n" "$*" >> "$CTHULHU_TEST_LOG"',
            'xsetroot': 'printf "root %s\\n" "$*" >> "$CTHULHU_TEST_LOG"',
            'xrandr': 'printf "xrandr %s\\n" "$*" >> "$CTHULHU_TEST_LOG"',
        }.items():
            p = self.folder / command; p.write_text('#!/usr/bin/env bash\n'+script+'\n'); p.chmod(0o755)

    def test_volume_status_rounds_and_never_notifies(self):
        self.env['CTHULHU_TEST_VOLUME'] = 'Volume: 0.05'
        result = run('home/.local/bin/cthulhu-audio', 'status', env=self.env)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '5%\n')
        self.assertFalse(self.log.exists())

    def test_muted_status(self):
        self.env['CTHULHU_TEST_VOLUME'] = 'Volume: 0.50 [MUTED]'
        self.assertEqual(run('home/.local/bin/cthulhu-audio', 'status', env=self.env).stdout, 'MUTE\n')

    def test_raise_volume_caps_at_unity_and_notifies(self):
        result = run('home/.local/bin/cthulhu-audio', 'up', env=self.env)
        self.assertEqual(result.returncode, 0)
        self.assertIn('set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+', self.log.read_text())
        self.assertIn('int:value:50', self.log.read_text())

    def test_mic_targets_source_and_replaces_notification(self):
        result = run('home/.local/bin/cthulhu-audio', 'mic', env=self.env)
        self.assertEqual(result.returncode, 0)
        self.assertIn('set-mute @DEFAULT_AUDIO_SOURCE@ toggle', self.log.read_text())
        self.assertIn('41002', self.log.read_text())

    def test_bad_audio_action_does_nothing(self):
        self.assertEqual(run('home/.local/bin/cthulhu-audio', 'invalid', env=self.env).returncode, 2)
        self.assertFalse(self.log.exists())

    def test_no_images_gives_solid_background_without_reconfiguring_outputs(self):
        result = run('home/.config/cthulhu/monitors.sh', self.folder, env=self.env)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(self.log.read_text(), 'root -solid #181616\n')

    def test_single_and_dual_wallpapers(self):
        Path(self.folder, '1.png').touch()
        self.assertEqual(run('home/.config/cthulhu/monitors.sh', self.folder, env=self.env).returncode, 0)
        self.assertIn('feh --bg-max '+str(self.folder / '1.png'), self.log.read_text())
        self.assertNotIn('2.png', self.log.read_text())
        self.log.unlink(); Path(self.folder, '2.png').touch()
        self.assertEqual(run('home/.config/cthulhu/monitors.sh', self.folder, env=self.env).returncode, 0)
        self.assertIn(str(self.folder / '2.png'), self.log.read_text())

    def test_fastfetch_configuration_is_portable(self):
        data = json.loads((ROOT / 'home/.config/fastfetch/config.jsonc').read_text())
        self.assertEqual(data['logo'], '~/.config/fastfetch/1.png')
        self.assertEqual([x['folders'] for x in data['modules'] if 'folders' in x], ['/'])

if __name__ == '__main__':
    unittest.main(verbosity=2)
