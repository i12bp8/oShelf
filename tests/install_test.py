import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class InstallTest(unittest.TestCase):
    def test_install_refuses_overwrite_and_uninstall_delegates(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            commands = base / "bin"
            commands.mkdir()
            log = base / "calls"
            for name in ["omarchy", "omarchy-shell"]:
                command = commands / name
                command.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$OSHELF_TEST_LOG"\n'
                    + '''if [ "$*" = "shell listPlugins" ]; then
  printf '%s\\n' '[{"id":"io.github.i12bp8.oshelf"}]'
fi
''')
                command.chmod(0o755)
            env = dict(os.environ, XDG_CONFIG_HOME=str(base / "config"),
                       PATH=str(commands) + os.pathsep + os.environ["PATH"], OSHELF_TEST_LOG=str(log))
            subprocess.run([str(ROOT / "scripts/install.sh")], env=env, check=True, capture_output=True)
            installed = base / "config/omarchy/plugins/io.github.i12bp8.oshelf"
            self.assertTrue((installed / "native/liboshelf-native.so").is_file())
            self.assertTrue((installed / "scripts/metadata.py").is_file())
            self.assertFalse((installed / "tests").exists())
            marker = installed / "keep"
            marker.write_text("user content")
            again = subprocess.run([str(ROOT / "scripts/install.sh")], env=env, capture_output=True)
            self.assertNotEqual(again.returncode, 0)
            self.assertEqual(marker.read_text(), "user content")
            subprocess.run([str(ROOT / "scripts/uninstall.sh")], env=env, check=True)
            self.assertIn("plugin enable io.github.i12bp8.oshelf", log.read_text())
            self.assertIn("plugin remove io.github.i12bp8.oshelf", log.read_text())


if __name__ == "__main__":
    unittest.main()
