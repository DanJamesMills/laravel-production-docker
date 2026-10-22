import tempfile
import unittest
from pathlib import Path
from collect_health import byte_value, storage_usage


class CollectorTest(unittest.TestCase):
    def test_binary_and_decimal_sizes(self):
        self.assertEqual(byte_value('1.5 GiB'), 1610612736)
        self.assertEqual(byte_value('2MB'), 2000000)
        self.assertEqual(byte_value('100B'), 100)
        with self.assertRaises(ValueError):
            byte_value('unknown')

    def test_categories_are_disjoint_and_symlinks_are_skipped(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ['app/private/crawler-data/sites/1/screenshots/a.png', 'app/private/crawler-data/sites/1/scans/2/a.html.gz', 'app/private/crawler-tests/1/a.png', 'logs/laravel.log', 'framework/views/a.php']:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b'x' * 100)
            (root / 'alias').symlink_to(root / 'app', target_is_directory=True)
            result = storage_usage(root)
            self.assertTrue(result['complete'])
            self.assertEqual(result['total_bytes'], 500)
            self.assertTrue(all(item['bytes'] == 100 and item['files'] == 1 for item in result['categories'].values()))
            self.assertFalse(storage_usage(root, limit=1)['complete'])
            self.assertFalse(storage_usage(root, seconds=-1)['complete'])
            self.assertFalse(storage_usage(root / 'missing')['complete'])


if __name__ == '__main__':
    unittest.main()
