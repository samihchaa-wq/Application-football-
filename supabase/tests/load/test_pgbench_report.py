"""Lecture fiable du bilan final de pgbench (sans base et sans réseau)."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_pgbench_report import check_report  # noqa: E402


class PgBenchReportTests(unittest.TestCase):
    def test_healthy_report(self):
        self.assertEqual(check_report(
            "number of transactions actually processed: 100\n"
            "number of failed transactions: 0 (0.0%)\n"
            "tps = 23.1 (without initial connection time)\n",
        ), [])

    def test_failed_transactions_rejected_even_with_exit_zero(self):
        self.assertTrue(check_report(
            "number of transactions actually processed: 100\n"
            "number of failed transactions: 2 (2%)\ntps = 10.0\n"
        ))

    def test_zero_transactions_rejected(self):
        self.assertTrue(check_report(
            "number of transactions actually processed: 0\ntps = 0.0\n"
        ))

    def test_empty_and_progress_only_output_rejected(self):
        self.assertTrue(check_report(""))
        self.assertTrue(check_report("progress: 50 tps\n"))

    def test_only_one_final_report_accepted(self):
        self.assertTrue(check_report(
            "number of transactions actually processed: 100\n"
            "number of transactions actually processed: 200\n"
            "tps = 10.0\n"
        ))

    def test_report_without_failure_field_is_accepted(self):
        self.assertEqual(check_report(
            "number of transactions actually processed: 14\n"
            "tps = 1.5\n"
        ), [])


if __name__ == "__main__":
    unittest.main()
