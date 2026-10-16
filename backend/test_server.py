import json
import threading
import unittest
from urllib.error import HTTPError
from urllib.request import urlopen, Request
from unittest.mock import patch
from http.server import ThreadingHTTPServer
from server import Handler


class ApiTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base = f'http://127.0.0.1:{cls.server.server_port}'

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def test_drills_and_cors(self):
        with urlopen(self.base + '/api/drills') as response:
            drills = json.load(response)
            self.assertEqual(len(drills), 6)
            self.assertEqual(drills[0]['title'], 'Backhand Throw')
            self.assertEqual(response.headers['Access-Control-Allow-Origin'], '*')
            for drill in drills:
                self.assertGreater(drill['minutes'], 0)
                self.assertTrue(drill['instructions'])

    def test_empty_and_error(self):
        with patch('server.DATA_FILE') as data:
            data.read_text.return_value = '[]'
            self.assertEqual(json.load(urlopen(self.base + '/api/drills')), [])
            data.read_text.side_effect = OSError('unavailable')
            with self.assertRaises(HTTPError) as error:
                urlopen(self.base + '/api/drills')
            self.assertEqual(error.exception.code, 500)

    def test_not_found_and_options(self):
        with self.assertRaises(HTTPError) as error:
            urlopen(self.base + '/missing')
        self.assertEqual(error.exception.code, 404)
        with urlopen(Request(self.base + '/api/drills', method='OPTIONS')) as response:
            self.assertEqual(response.status, 204)


if __name__ == '__main__':
    unittest.main()
