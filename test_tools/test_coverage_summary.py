from pathlib import Path
import unittest

from tool.coverage_summary import read_lcov, summarize


class CoverageSummaryTests(unittest.TestCase):
    def test_external_sources_do_not_add_hits_to_the_previous_file(self):
        root = Path('/project')
        files = read_lcov('SF:lib/app.dart\nDA:1,1\nSF:/sdk/flutter/lib/widgets.dart\nDA:2,4\nend_of_record', root)
        self.assertEqual(files, {'lib/app.dart': {1: 1}})

    def test_duplicate_records_merge_lines_instead_of_inflating_coverage(self):
        files = read_lcov('SF:lib/app.dart\nDA:1,0\nDA:2,2\nend_of_record\nSF:lib/app.dart\nDA:1,3\nDA:2,0', Path('/project'))
        result = summarize(files, ['lib/app.dart'])
        self.assertEqual(result['total'], {'total': 2, 'covered': 2})

    def test_package_tests_and_path_traversals_are_excluded(self):
        files = read_lcov('SF:packages/data/test/model_test.dart\nDA:1,5\nSF:../outside.dart\nDA:1,9', Path('/project'))
        self.assertEqual(files, {})

    def test_component_totals_and_uninstrumented_sources_are_explicit(self):
        files = read_lcov('SF:lib/app.dart\nDA:1,0\nSF:packages/data/lib/model.dart\nDA:1,2', Path('/project'))
        result = summarize(files, ['lib/app.dart', 'lib/uncovered.dart', 'packages/data/lib/model.dart'])
        self.assertEqual(result['components']['app']['covered'], 0)
        self.assertEqual(result['components']['data']['covered'], 1)
        self.assertEqual(result['absent_files'], ['lib/uncovered.dart'])

    def test_empty_report_has_zero_totals(self):
        self.assertEqual(summarize({}, [])['total'], {'total': 0, 'covered': 0})


if __name__ == '__main__':
    unittest.main()
