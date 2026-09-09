import importlib.util
import pathlib
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("metadata", pathlib.Path(__file__).parents[1] / "scripts/metadata.py")
metadata = importlib.util.module_from_spec(spec)
spec.loader.exec_module(metadata)


class MetadataTest(unittest.TestCase):
    def test_references(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "$(touch nope)\n雪.png"
            path.write_bytes(b"not decoded by metadata")
            rows = metadata.inspect([directory, str(path), str(path) + "missing"])
            self.assertEqual(rows[0]["kind"], "folder")
            self.assertTrue(rows[1]["image"])
            self.assertFalse(rows[2]["exists"])
            self.assertEqual(len(list(pathlib.Path(directory).iterdir())), 1)

    def test_rejects_invalid_paths(self):
        for paths in [["relative"], ["/a\0b"], [2], "path", ["/"] * 257]:
            with self.assertRaises(ValueError):
                metadata.inspect(paths)


if __name__ == "__main__":
    unittest.main()
