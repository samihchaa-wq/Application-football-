"""Le CSP de production doit pointer vers la nouvelle base commerciale."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from stamp_commercial_csp import PLACEHOLDER_HOST, replace_csp_hosts  # noqa: E402


class CommercialCspTests(unittest.TestCase):
    def setUp(self) -> None:
        self.html = (
            '<meta http-equiv="Content-Security-Policy" content="'
            f"img-src https://{PLACEHOLDER_HOST}; "
            f"connect-src https://{PLACEHOLDER_HOST} wss://{PLACEHOLDER_HOST}; "
            f'media-src https://{PLACEHOLDER_HOST}">'
        )

    def test_stamps_all_http_and_websocket_sources(self) -> None:
        output = replace_csp_hosts(
            self.html, "https://aaaaaaaaaaaaaaaaaaaa.supabase.co"
        )
        self.assertNotIn(PLACEHOLDER_HOST, output)
        self.assertEqual(output.count("aaaaaaaaaaaaaaaaaaaa.supabase.co"), 4)
        self.assertIn("wss://aaaaaaaaaaaaaaaaaaaa.supabase.co", output)

    def test_fails_if_source_csp_changes(self) -> None:
        with self.assertRaises(ValueError):
            replace_csp_hosts(self.html.replace(PLACEHOLDER_HOST, "example.com", 1),
                              "https://aaaaaaaaaaaaaaaaaaaa.supabase.co")

    def test_fails_if_csp_is_missing(self) -> None:
        with self.assertRaises(ValueError):
            replace_csp_hosts(
                "Hello " + PLACEHOLDER_HOST * 4,
                "https://aaaaaaaaaaaaaaaaaaaa.supabase.co",
            )


if __name__ == "__main__":
    unittest.main()
